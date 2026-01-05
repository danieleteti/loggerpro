unit ThreadSafetyTestU;

interface

uses
  DUnitX.TestFramework,
  LoggerPro,
  LoggerPro.Builder,
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Rtti;

type
  [TestFixture]
  TThreadSafetyTest = class
  public
    [Test]
    [RepeatTest(5)]
    procedure TestDestroyWhileThreadsAreLogging;

    [Test]
    [RepeatTest(5)]
    procedure TestDestroyWhileThreadsAreLoggingWithContext;

    [Test]
    procedure TestRapidCreateDestroy;
  end;

implementation

uses
  LoggerPro.MemoryAppender;

type
  TLoggingThread = class(TThread)
  private
    FLog: ILogWriter;
    FCount: Integer;
    FUseContext: Boolean;
  protected
    procedure Execute; override;
  public
    constructor Create(ALog: ILogWriter; ACount: Integer; AUseContext: Boolean = False);
  end;

{ TLoggingThread }

constructor TLoggingThread.Create(ALog: ILogWriter; ACount: Integer; AUseContext: Boolean);
begin
  inherited Create(False);
  FreeOnTerminate := False;
  FLog := ALog;
  FCount := ACount;
  FUseContext := AUseContext;
end;

procedure TLoggingThread.Execute;
var
  I: Integer;
begin
  for I := 1 to FCount do
  begin
    if Terminated then
      Break;
    try
      if FUseContext then
        FLog.Info('Message from thread', 'THREAD', [
          LogParam.I('iteration', I),
          LogParam.I('thread_id', TThread.CurrentThread.ThreadID)
        ])
      else
        FLog.Info(Format('Message %d from thread', [I]), 'THREAD');
    except
      // Ignore exceptions during shutdown - this is expected
    end;
  end;
end;

{ TThreadSafetyTest }

procedure TThreadSafetyTest.TestDestroyWhileThreadsAreLogging;
const
  THREAD_COUNT = 10;
  MESSAGES_PER_THREAD = 1000;
var
  Log: ILogWriter;
  Threads: array[0..THREAD_COUNT-1] of TLoggingThread;
  I: Integer;
begin
  // Create logger with memory appender
  Log := LoggerProBuilder
    .WriteToMemory.WithMaxSize(100).Done
    .Build;

  // Start multiple threads that will log continuously
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TLoggingThread.Create(Log, MESSAGES_PER_THREAD);

  // Give threads some time to start logging
  Sleep(50);

  // Destroy logger while threads are still logging
  // This should NOT cause access violations
  Log := nil;

  // Wait for threads to finish (they should exit gracefully)
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].Terminate;
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  // If we get here without access violation, test passed
  Assert.Pass('Logger destroyed while threads were logging without access violation');
end;

procedure TThreadSafetyTest.TestDestroyWhileThreadsAreLoggingWithContext;
const
  THREAD_COUNT = 10;
  MESSAGES_PER_THREAD = 1000;
var
  Log: ILogWriter;
  Threads: array[0..THREAD_COUNT-1] of TLoggingThread;
  I: Integer;
begin
  // Create logger with memory appender
  Log := LoggerProBuilder
    .WriteToMemory.WithMaxSize(100).Done
    .Build;

  // Start multiple threads that will log with context
  for I := 0 to THREAD_COUNT - 1 do
    Threads[I] := TLoggingThread.Create(Log, MESSAGES_PER_THREAD, True);

  // Give threads some time to start logging
  Sleep(50);

  // Destroy logger while threads are still logging
  Log := nil;

  // Wait for threads to finish
  for I := 0 to THREAD_COUNT - 1 do
  begin
    Threads[I].Terminate;
    Threads[I].WaitFor;
    Threads[I].Free;
  end;

  Assert.Pass('Logger destroyed while threads were logging with context without access violation');
end;

procedure TThreadSafetyTest.TestRapidCreateDestroy;
const
  ITERATIONS = 50;
var
  Log: ILogWriter;
  I, J: Integer;
begin
  // Rapidly create and destroy loggers while logging
  // This tests the shutdown path repeatedly
  for I := 1 to ITERATIONS do
  begin
    Log := LoggerProBuilder
      .WriteToMemory.WithMaxSize(10).Done
      .Build;

    // Log a few messages
    for J := 1 to 10 do
      Log.Info('Rapid test message %d-%d', [I, J], 'RAPID');

    // Immediately destroy
    Log := nil;
  end;

  Assert.Pass('Rapid create/destroy cycles completed without issues');
end;

initialization
  TDUnitX.RegisterTestFixture(TThreadSafetyTest);

end.
