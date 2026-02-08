unit CriticalIssuesTestU;

interface

uses
  DUnitX.TestFramework,
  LoggerPro,
  LoggerPro.FileAppender,
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type
  [TestFixture]
  TCriticalIssuesTest = class
  private
    procedure CleanupLogFiles;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    // Issue #100 - Hanging in destructor
    [Test]
    [TestCase('QuickDestroy', '10')]
    [TestCase('MediumDestroy', '100')]
    [TestCase('LargeDestroy', '1000')]
    procedure TestDestructorDoesNotHang(const MessageCount: Integer);

    [Test]
    procedure TestShutdownIsIdempotent;

    [Test]
    procedure TestShutdownWithTimeout;

    // Issue #97 - Data loss on destroy
    [Test]
    procedure TestNoDataLossOnDestroy;

    [Test]
    procedure TestAutoFlushOnDestroy;

    [Test]
    procedure TestDestroyWithPendingMessages;
  end;

implementation

uses
  LoggerPro.Builder,
  System.IOUtils,
  System.Diagnostics;

{ TCriticalIssuesTest }

procedure TCriticalIssuesTest.Setup;
begin
  CleanupLogFiles;
end;

procedure TCriticalIssuesTest.TearDown;
begin
  CleanupLogFiles;
end;

procedure TCriticalIssuesTest.CleanupLogFiles;
var
  lFiles: TArray<string>;
  lFile: string;
begin
  lFiles := TDirectory.GetFiles(TPath.GetTempPath, 'critical_test_*.log', TSearchOption.soTopDirectoryOnly);
  for lFile in lFiles do
  begin
    try
      TFile.Delete(lFile);
    except
      // Ignore errors during cleanup
    end;
  end;
end;

procedure TCriticalIssuesTest.TestDestructorDoesNotHang(const MessageCount: Integer);
var
  lLog: ILogWriter;
  lStopwatch: TStopwatch;
  I: Integer;
  lElapsedMs: Int64;
const
  MAX_DESTROY_TIME_MS = 5000; // 5 seconds max for destroy
begin
  // Create logger with file appender
  lLog := LoggerProBuilder
    .WriteToFile
      .WithFileBaseName(TPath.Combine(TPath.GetTempPath, 'critical_test_hang'))
      .WithMaxBackupFiles(0)
      .Done
    .Build;

  // Queue multiple messages
  for I := 1 to MessageCount do
  begin
    lLog.Info('Test message %d', [I], 'TEST');
  end;

  // Measure destructor time
  lStopwatch := TStopwatch.StartNew;

  // Trigger destructor (release interface)
  lLog := nil;

  lStopwatch.Stop;
  lElapsedMs := lStopwatch.ElapsedMilliseconds;

  // Verify destructor completed in reasonable time
  Assert.IsTrue(lElapsedMs < MAX_DESTROY_TIME_MS,
    Format('Destructor took %d ms (max %d ms) - possible hang detected!',
      [lElapsedMs, MAX_DESTROY_TIME_MS]));
end;

procedure TCriticalIssuesTest.TestShutdownIsIdempotent;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToFile
      .WithFileBaseName(TPath.Combine(TPath.GetTempPath, 'critical_test_shutdown'))
      .WithMaxBackupFiles(0)
      .Done
    .Build;

  lLog.Info('Before shutdown');

  // Call Shutdown multiple times - should not hang or fail
  lLog.Shutdown;
  lLog.Shutdown;
  lLog.Shutdown;

  // Destructor should also work fine
  lLog := nil;

  Assert.Pass('Shutdown is idempotent');
end;

procedure TCriticalIssuesTest.TestShutdownWithTimeout;
var
  lLog: ILogWriter;
  lStopwatch: TStopwatch;
  lElapsedMs: Int64;
  I: Integer;
const
  MAX_SHUTDOWN_TIME_MS = 3000; // 3 seconds max
begin
  lLog := LoggerProBuilder
    .WriteToFile
      .WithFileBaseName(TPath.Combine(TPath.GetTempPath, 'critical_test_timeout'))
      .WithMaxBackupFiles(0)
      .Done
    .Build;

  // Queue many messages
  for I := 1 to 1000 do
  begin
    lLog.Info('Message %d', [I], 'TEST');
  end;

  lStopwatch := TStopwatch.StartNew;
  lLog.Shutdown;
  lStopwatch.Stop;

  lElapsedMs := lStopwatch.ElapsedMilliseconds;

  Assert.IsTrue(lElapsedMs < MAX_SHUTDOWN_TIME_MS,
    Format('Shutdown took %d ms (max %d ms)', [lElapsedMs, MAX_SHUTDOWN_TIME_MS]));

  lLog := nil;
end;

procedure TCriticalIssuesTest.TestNoDataLossOnDestroy;
var
  lLog: ILogWriter;
  lLogFileName: string;
  lLogContent: string;
  I: Integer;
  lBaseName: string;
const
  MESSAGE_COUNT = 100;
begin
  lBaseName := TPath.Combine(TPath.GetTempPath, 'critical_test_dataloss');
  lLogFileName := lBaseName + '.00.TEST.log';  // Format: {basename}.{number}.{tag}.log

  WriteLn('TestNoDataLossOnDestroy: Log file will be: ' + lLogFileName);

  lLog := LoggerProBuilder
    .WriteToFile
      .WithFileBaseName(lBaseName)
      .WithMaxBackupFiles(0)
      .Done
    .Build;

  // Queue messages
  for I := 1 to MESSAGE_COUNT do
  begin
    lLog.Info('Message %d', [I], 'TEST');
  end;

  // Destroy logger (should auto-flush)
  lLog := nil;

  // Wait a bit for file to be fully written
  Sleep(2000);

  // Verify all messages were written
  Assert.IsTrue(TFile.Exists(lLogFileName), 'Log file should exist');

  lLogContent := TFile.ReadAllText(lLogFileName);

  // Check that we have all messages (each message contains "Message X")
  for I := 1 to MESSAGE_COUNT do
  begin
    Assert.Contains(lLogContent, Format('Message %d', [I]),
      Format('Message %d not found in log file - data loss detected!', [I]));
  end;
end;

procedure TCriticalIssuesTest.TestAutoFlushOnDestroy;
var
  lLog: ILogWriter;
  lLogFileName: string;
  lLogContent: string;
  lStopwatch: TStopwatch;
begin
  lLogFileName := TPath.Combine(TPath.GetTempPath, 'critical_test_autoflush.00.TEST.log');

  lLog := LoggerProBuilder
    .WriteToFile
      .WithFileBaseName(TPath.Combine(TPath.GetTempPath, 'critical_test_autoflush'))
      .WithMaxBackupFiles(0)
      .Done
    .Build;

  lLog.Info('Test message that must be flushed', 'TEST');

  // Destroy without calling Shutdown (should auto-flush)
  lStopwatch := TStopwatch.StartNew;
  lLog := nil;
  lStopwatch.Stop;

  // Should complete quickly
  Assert.IsTrue(lStopwatch.ElapsedMilliseconds < 3000,
    'Auto-flush took too long');

  // Wait for file write
  Sleep(2000);

  // Verify message was written
  Assert.IsTrue(TFile.Exists(lLogFileName), 'Log file should exist');
  lLogContent := TFile.ReadAllText(lLogFileName);
  Assert.Contains(lLogContent, 'Test message that must be flushed',
    'Message not flushed on destroy');
end;

procedure TCriticalIssuesTest.TestDestroyWithPendingMessages;
var
  lLog: ILogWriter;
  lLogFileName: string;
  lLogContent: string;
  I: Integer;
  lMessageCount: Integer;
const
  EXPECTED_MESSAGES = 500;
begin
  lLogFileName := TPath.Combine(TPath.GetTempPath, 'critical_test_pending.00.TEST.log');

  lLog := LoggerProBuilder
    .WriteToFile
      .WithFileBaseName(TPath.Combine(TPath.GetTempPath, 'critical_test_pending'))
      .WithMaxBackupFiles(0)
      .Done
    .Build;

  // Queue many messages quickly (some will be pending in queue)
  for I := 1 to EXPECTED_MESSAGES do
  begin
    lLog.Info('Pending message %d', [I], 'TEST');
  end;

  // Destroy immediately without explicit Shutdown
  lLog := nil;

  // Wait for flush
  Sleep(3000);

  // Verify file exists and contains messages
  Assert.IsTrue(TFile.Exists(lLogFileName), 'Log file should exist');

  lLogContent := TFile.ReadAllText(lLogFileName);

  // Count how many messages were written
  lMessageCount := 0;
  for I := 1 to EXPECTED_MESSAGES do
  begin
    if lLogContent.Contains(Format('Pending message %d', [I])) then
      Inc(lMessageCount);
  end;

  // We expect most messages to be written (allow 5% loss in extreme cases)
  Assert.IsTrue(lMessageCount >= Trunc(EXPECTED_MESSAGES * 0.95),
    Format('Too many messages lost: %d/%d written (%.1f%%)',
      [lMessageCount, EXPECTED_MESSAGES, (lMessageCount / EXPECTED_MESSAGES) * 100]));
end;

initialization
  TDUnitX.RegisterTestFixture(TCriticalIssuesTest);

end.
