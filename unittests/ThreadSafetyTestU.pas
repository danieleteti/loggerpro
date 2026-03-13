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

    // Issue #109 - DLL initialization deadlock (Windows Loader Lock)
    //
    // NOTE: The actual deadlock (System.IsLibrary = True branch) can only be
    // reproduced in a DLL loaded via P/Invoke: the Loader Lock held during
    // DllMain/DLL_THREAD_ATTACH prevents the logger thread from starting,
    // deadlocking the spin-wait. That scenario cannot be exercised from an EXE
    // test runner.
    //
    // What we CAN test is the invariant the fix relies on:
    //   "FQueue is created in TLoggerThread.Create (before Start), so log items
    //    enqueued before Execute() begins are never lost."
    // If this contract breaks, the DLL fix would be unsafe regardless.

    [Test]
    // Logs N messages with zero intentional delay after Build() and verifies
    // all messages are received after Shutdown (queue fully drained).
    procedure TestNoMessageLossWhenLoggingImmediatelyAfterBuild;

    [Test]
    // Many threads all start logging before the logger thread could possibly
    // have processed anything. Verifies zero message loss after Shutdown.
    procedure TestNoMessageLossWithConcurrentImmediateLogging;
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

procedure TThreadSafetyTest.TestNoMessageLossWhenLoggingImmediatelyAfterBuild;
const
  MESSAGE_COUNT = 200;
var
  lLog: ILogWriter;
  lAppender: TLoggerProMemoryRingBufferAppender;
  I: Integer;
begin
  // Build with a buffer large enough to hold every message
  lAppender := TLoggerProMemoryRingBufferAppender.Create(MESSAGE_COUNT + 10);
  lLog := LoggerProBuilder
    .WriteToAppender(lAppender)
    .Build;

  // Log immediately — no Sleep, no yield.
  // The logger thread may not have called Execute() yet when the first
  // Enqueue happens. The queue must already be allocated (PR #109 invariant).
  for I := 1 to MESSAGE_COUNT do
    lLog.Info('ImmediateMsg %d', [I], 'PR109');

  // Shutdown flushes the queue completely before returning.
  lLog.Shutdown;
  lLog := nil;

  Assert.AreEqual(MESSAGE_COUNT, lAppender.Count,
    Format('Expected %d messages, got %d — messages lost before thread started',
      [MESSAGE_COUNT, lAppender.Count]));
end;

procedure TThreadSafetyTest.TestNoMessageLossWithConcurrentImmediateLogging;
const
  THREAD_COUNT  = 8;
  MSGS_PER_THREAD = 50;
  TOTAL_MSGS    = THREAD_COUNT * MSGS_PER_THREAD;
var
  lLog: ILogWriter;
  lAppender: TLoggerProMemoryRingBufferAppender;
  lThreads: array[0..THREAD_COUNT - 1] of TLoggingThread;
  I: Integer;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(TOTAL_MSGS + 10);
  lLog := LoggerProBuilder
    .WriteToAppender(lAppender)
    .Build;

  // All threads start logging at once — before Execute() has had time to
  // dequeue anything. This mirrors the DLL scenario where Initialize returns
  // without spin-waiting and callers begin logging immediately.
  for I := 0 to THREAD_COUNT - 1 do
    lThreads[I] := TLoggingThread.Create(lLog, MSGS_PER_THREAD);

  for I := 0 to THREAD_COUNT - 1 do
  begin
    lThreads[I].WaitFor;
    lThreads[I].Free;
  end;

  lLog.Shutdown;
  lLog := nil;

  Assert.AreEqual(TOTAL_MSGS, lAppender.Count,
    Format('Expected %d messages, got %d — concurrent early-enqueue lost messages',
      [TOTAL_MSGS, lAppender.Count]));
end;

initialization
  TDUnitX.RegisterTestFixture(TThreadSafetyTest);

end.
