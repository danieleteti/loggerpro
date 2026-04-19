unit LifecycleRaceTestU;

{
  Deterministic stress tests for the logger lifecycle.

  These tests reproduce the race where rapid Build -> Log -> Shutdown cycles
  drop entire sections of log output under the Delphi IDE debugger.
  The debugger amplifies otherwise-invisible windows where a new appender
  thread has not yet reached its Running state when log items flow in.

  To provoke the same windows WITHOUT a debugger, the test appender
  injects configurable Setup latency and first-call failures that simulate
  IDE-induced thread scheduling delays.
}

interface

uses
  DUnitX.TestFramework,
  LoggerPro,
  LoggerPro.Builder,
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections;

type
  TRaceTestAppender = class(TLoggerProAppenderBase)
  strict private
    class var FLock: TCriticalSection;
    class var FAllMessages: TList<string>;
  public
    class constructor Create;
    class destructor Destroy;
    class procedure ResetCollector;
    class function TotalMessages: Integer;
    class function SnapshotMessages: TArray<string>;

    class var SetupDelayMs: Cardinal;
    class var SetupFailFirst: Boolean;
    class var SetupFailFirstTriggered: Boolean;
    class var WriteDelayMs: Cardinal;
    // When > 0, Setup/WriteLog sleep a random [0..JitterMs] before running.
    // This simulates the unpredictable thread scheduling imposed by the
    // IDE debugger (CREATE_THREAD_DEBUG_EVENT handling, symbol loading,
    // first-chance exception handshaking).
    class var JitterMs: Cardinal;

    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); override;
  end;

  [TestFixture]
  TLifecycleRaceTest = class
  public
    [Setup]
    procedure BeforeEach;

    [Test]
    // Baseline: many rapid Build -> Log -> Shutdown cycles. No injected delays.
    // Verifies no items are lost in a clean lifecycle.
    [RepeatTest(5)]
    procedure TestRapidLifecycleNoLoss;

    [Test]
    // Simulates IDE debugger thread-creation delay: Setup sleeps a few ms
    // before returning. If TAppenderAdapter.Create does not wait for the
    // appender thread to reach its ready state, log items enqueued from
    // the main thread can be processed before Setup completes and get
    // held in the appender queue past the shutdown drain.
    [RepeatTest(5)]
    procedure TestSlowSetupNoLoss;

    [Test]
    // Worst-case: Setup sleeps AND the first logger's cycle is followed
    // immediately by the next (no gap between Shutdown and Build). This
    // stresses the adapter-lifecycle lock.
    [RepeatTest(5)]
    procedure TestBackToBackLifecyclesSlowSetup;

    [Test]
    // Mimics the colors_demo scenario: six sections, each with two
    // appenders (console-like and file-like are both TRaceTestAppender
    // here so we can count deterministically). No Sleep between sections.
    [RepeatTest(5)]
    procedure TestSixSectionsTwoAppenders;

    [Test]
    // The appender's FIRST Setup attempt FAILS (injected), then succeeds.
    // This used to put the appender in WaitAfterFail permanently and strand
    // every queued item; WaitUntilReady + the retry loop should now drain.
    [RepeatTest(3)]
    procedure TestFirstSetupFailsThenSucceeds;

    [Test]
    // Back-to-back cycles with BOTH slow Setup AND slow WriteLog - the
    // most aggressive configuration. Any stranded item shows up as a miss.
    [RepeatTest(3)]
    procedure TestAggressiveStress;

    [Test]
    // Random jitter in Setup and WriteLog - simulates the unpredictable
    // scheduling imposed by the IDE debugger. The architecture must be
    // immune to thread-timing perturbations.
    [RepeatTest(3)]
    procedure TestRandomJitterStress;
  end;

implementation

uses
  System.Diagnostics;

{ TRaceTestAppender }

class constructor TRaceTestAppender.Create;
begin
  FLock := TCriticalSection.Create;
  FAllMessages := TList<string>.Create;
  SetupDelayMs := 0;
  SetupFailFirst := False;
  SetupFailFirstTriggered := False;
  WriteDelayMs := 0;
  JitterMs := 0;
  Randomize;
end;

function RandomJitter(aMaxMs: Cardinal): Cardinal; inline;
begin
  if aMaxMs = 0 then
    Result := 0
  else
    Result := Cardinal(Random(Integer(aMaxMs) + 1));
end;

class destructor TRaceTestAppender.Destroy;
begin
  FreeAndNil(FAllMessages);
  FreeAndNil(FLock);
end;

class procedure TRaceTestAppender.ResetCollector;
begin
  FLock.Enter;
  try
    FAllMessages.Clear;
    SetupFailFirstTriggered := False;
  finally
    FLock.Leave;
  end;
end;

class function TRaceTestAppender.TotalMessages: Integer;
begin
  FLock.Enter;
  try
    Result := FAllMessages.Count;
  finally
    FLock.Leave;
  end;
end;

class function TRaceTestAppender.SnapshotMessages: TArray<string>;
begin
  FLock.Enter;
  try
    Result := FAllMessages.ToArray;
  finally
    FLock.Leave;
  end;
end;

procedure TRaceTestAppender.Setup;
var
  lJitter: Cardinal;
begin
  inherited;
  if SetupDelayMs > 0 then
    Sleep(SetupDelayMs);
  lJitter := RandomJitter(JitterMs);
  if lJitter > 0 then
    Sleep(lJitter);
  if SetupFailFirst then
  begin
    FLock.Enter;
    try
      if not SetupFailFirstTriggered then
      begin
        SetupFailFirstTriggered := True;
        raise Exception.Create('Simulated first-Setup failure');
      end;
    finally
      FLock.Leave;
    end;
  end;
end;

procedure TRaceTestAppender.TearDown;
begin
  inherited;
end;

procedure TRaceTestAppender.WriteLog(const aLogItem: TLogItem);
var
  lJitter: Cardinal;
begin
  if WriteDelayMs > 0 then
    Sleep(WriteDelayMs);
  lJitter := RandomJitter(JitterMs);
  if lJitter > 0 then
    Sleep(lJitter);
  FLock.Enter;
  try
    FAllMessages.Add(aLogItem.LogMessage);
  finally
    FLock.Leave;
  end;
end;

{ TLifecycleRaceTest }

procedure TLifecycleRaceTest.BeforeEach;
begin
  TRaceTestAppender.ResetCollector;
  TRaceTestAppender.SetupDelayMs := 0;
  TRaceTestAppender.SetupFailFirst := False;
  TRaceTestAppender.WriteDelayMs := 0;
  TRaceTestAppender.JitterMs := 0;
end;

procedure TLifecycleRaceTest.TestRapidLifecycleNoLoss;
const
  CYCLES = 50;
  LOGS_PER_CYCLE = 7;
var
  I, J: Integer;
  Log: ILogWriter;
  Appender: TRaceTestAppender;
begin
  for I := 1 to CYCLES do
  begin
    Appender := TRaceTestAppender.Create;
    Log := LoggerProBuilder
      .WriteToAppender(Appender)
      .Build;
    for J := 1 to LOGS_PER_CYCLE do
      Log.Info(Format('cycle=%d msg=%d', [I, J]), 'RACE');
    Log.Shutdown;
    Log := nil;
  end;

  Assert.AreEqual(CYCLES * LOGS_PER_CYCLE, TRaceTestAppender.TotalMessages,
    Format('Expected %d messages across %d cycles, got %d',
      [CYCLES * LOGS_PER_CYCLE, CYCLES, TRaceTestAppender.TotalMessages]));
end;

procedure TLifecycleRaceTest.TestSlowSetupNoLoss;
const
  CYCLES = 20;
  LOGS_PER_CYCLE = 7;
var
  I, J: Integer;
  Log: ILogWriter;
  Appender: TRaceTestAppender;
begin
  TRaceTestAppender.SetupDelayMs := 20;
  for I := 1 to CYCLES do
  begin
    Appender := TRaceTestAppender.Create;
    Log := LoggerProBuilder
      .WriteToAppender(Appender)
      .Build;
    // Log IMMEDIATELY after Build - Setup is still sleeping.
    for J := 1 to LOGS_PER_CYCLE do
      Log.Info(Format('cycle=%d msg=%d', [I, J]), 'RACE');
    Log.Shutdown;
    Log := nil;
  end;

  Assert.AreEqual(CYCLES * LOGS_PER_CYCLE, TRaceTestAppender.TotalMessages,
    Format('Expected %d messages, got %d - items dropped under slow-Setup race',
      [CYCLES * LOGS_PER_CYCLE, TRaceTestAppender.TotalMessages]));
end;

procedure TLifecycleRaceTest.TestBackToBackLifecyclesSlowSetup;
const
  CYCLES = 20;
  LOGS_PER_CYCLE = 7;
var
  I, J: Integer;
  Log: ILogWriter;
  Appender: TRaceTestAppender;
begin
  TRaceTestAppender.SetupDelayMs := 15;
  TRaceTestAppender.WriteDelayMs := 1;
  for I := 1 to CYCLES do
  begin
    Appender := TRaceTestAppender.Create;
    Log := LoggerProBuilder
      .WriteToAppender(Appender)
      .Build;
    for J := 1 to LOGS_PER_CYCLE do
      Log.Info(Format('cycle=%d msg=%d', [I, J]), 'RACE');
    Log.Shutdown;
    Log := nil;
    // No sleep between cycles - back-to-back.
  end;

  Assert.AreEqual(CYCLES * LOGS_PER_CYCLE, TRaceTestAppender.TotalMessages,
    Format('Expected %d messages, got %d - back-to-back cycles dropped items',
      [CYCLES * LOGS_PER_CYCLE, TRaceTestAppender.TotalMessages]));
end;

procedure TLifecycleRaceTest.TestSixSectionsTwoAppenders;
const
  SECTIONS = 6;
  LOGS_PER_SECTION = 7;
var
  I, J: Integer;
  Log: ILogWriter;
  Appender1, Appender2: TRaceTestAppender;
begin
  TRaceTestAppender.SetupDelayMs := 10;
  for I := 1 to SECTIONS do
  begin
    Appender1 := TRaceTestAppender.Create;
    Appender2 := TRaceTestAppender.Create;
    Log := LoggerProBuilder
      .WriteToAppender(Appender1)
      .WriteToAppender(Appender2)
      .Build;
    for J := 1 to LOGS_PER_SECTION do
      Log.Info(Format('section=%d msg=%d', [I, J]), 'RACE');
    Log.Shutdown;
    Log := nil;
  end;

  // Two appenders -> each message written twice.
  Assert.AreEqual(SECTIONS * LOGS_PER_SECTION * 2, TRaceTestAppender.TotalMessages,
    Format('Expected %d messages (2 appenders), got %d',
      [SECTIONS * LOGS_PER_SECTION * 2, TRaceTestAppender.TotalMessages]));
end;

procedure TLifecycleRaceTest.TestFirstSetupFailsThenSucceeds;
const
  LOGS = 7;
var
  J: Integer;
  Log: ILogWriter;
  Appender: TRaceTestAppender;
begin
  TRaceTestAppender.SetupFailFirst := True;
  Appender := TRaceTestAppender.Create;
  Log := LoggerProBuilder
    .WriteToAppender(Appender)
    .Build;
  for J := 1 to LOGS do
    Log.Info(Format('msg=%d', [J]), 'RACE');
  Log.Shutdown;
  Log := nil;

  Assert.AreEqual(LOGS, TRaceTestAppender.TotalMessages,
    Format('Expected %d messages, got %d - first-Setup-failure stranded items',
      [LOGS, TRaceTestAppender.TotalMessages]));
end;

procedure TLifecycleRaceTest.TestAggressiveStress;
const
  CYCLES = 30;
  LOGS_PER_CYCLE = 10;
var
  I, J: Integer;
  Log: ILogWriter;
  A1, A2: TRaceTestAppender;
begin
  TRaceTestAppender.SetupDelayMs := 25;
  TRaceTestAppender.WriteDelayMs := 1;
  for I := 1 to CYCLES do
  begin
    A1 := TRaceTestAppender.Create;
    A2 := TRaceTestAppender.Create;
    Log := LoggerProBuilder
      .WriteToAppender(A1)
      .WriteToAppender(A2)
      .Build;
    for J := 1 to LOGS_PER_CYCLE do
      Log.Info(Format('cycle=%d msg=%d', [I, J]), 'RACE');
    Log.Shutdown;
    Log := nil;
  end;

  Assert.AreEqual(CYCLES * LOGS_PER_CYCLE * 2, TRaceTestAppender.TotalMessages,
    Format('Expected %d messages, got %d - aggressive stress dropped items',
      [CYCLES * LOGS_PER_CYCLE * 2, TRaceTestAppender.TotalMessages]));
end;

procedure TLifecycleRaceTest.TestRandomJitterStress;
const
  CYCLES = 20;
  LOGS_PER_CYCLE = 7;
var
  I, J: Integer;
  Log: ILogWriter;
  A1, A2: TRaceTestAppender;
begin
  TRaceTestAppender.JitterMs := 30;  // random 0..30ms on Setup AND WriteLog
  for I := 1 to CYCLES do
  begin
    A1 := TRaceTestAppender.Create;
    A2 := TRaceTestAppender.Create;
    Log := LoggerProBuilder
      .WriteToAppender(A1)
      .WriteToAppender(A2)
      .Build;
    for J := 1 to LOGS_PER_CYCLE do
      Log.Info(Format('cycle=%d msg=%d', [I, J]), 'RACE');
    Log.Shutdown;
    Log := nil;
  end;

  Assert.AreEqual(CYCLES * LOGS_PER_CYCLE * 2, TRaceTestAppender.TotalMessages,
    Format('Expected %d messages, got %d - random jitter dropped items',
      [CYCLES * LOGS_PER_CYCLE * 2, TRaceTestAppender.TotalMessages]));
end;

initialization
  TDUnitX.RegisterTestFixture(TLifecycleRaceTest);

end.
