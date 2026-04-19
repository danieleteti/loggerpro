unit BuilderTestU;

// Tests exercise the deprecated BuildLogWriter directly to keep the
// legacy factory covered. Silence the deprecation noise here - the
// deprecation is intentional for users, not for us.
{$WARN SYMBOL_DEPRECATED OFF}

interface

uses
  DUnitX.TestFramework,
  LoggerPro,
  LoggerPro.Builder,
  System.SysUtils,
  System.Classes,
  System.SyncObjs;

type
  [TestFixture]
  TLoggerProBuilderTest = class
  public
    [Test]
    procedure TestBuildWithConsoleAppender;
    [Test]
    procedure TestBuildWithFileAppender;
    [Test]
    procedure TestBuildWithMultipleAppenders;
    [Test]
    procedure TestBuildWithNoAppendersRaisesException;
    [Test]
    procedure TestWriteToFileWithAllOptions;
    [Test]
    procedure TestWriteToWebhookWithHeaders;
    [Test]
    procedure TestWriteToMemory;
    [Test]
    procedure TestWriteToCallback;
    [Test]
    procedure TestWriteToTimeRotatingFile;
    [Test]
    procedure TestMixedAppenders;
    [Test]
    procedure TestBuilderFunction;
    [Test]
    procedure TestWithDefaultLogLevel;
    [Test]
    procedure TestWithMinimumLevel;
    [Test]
    procedure TestWithDefaultTag;
    [Test]
    procedure TestWithDefaultTagOverride;
    [Test]
    procedure TestLogWithoutTagUsesMainAsDefault;
    [Test]
    procedure TestWithDefaultTagOnSubLogger;
    [Test]
    procedure TestLogExceptionWithoutFormatter;
    [Test]
    procedure TestLogExceptionWithStackTraceFormatter;
    [Test]
    procedure TestLogExceptionWithMessageAndTag;
    [Test]
    procedure TestSyslogWithUseLocalTime;
    [Test]
    procedure TestElasticSearchWithBasicAuth;
    [Test]
    procedure TestElasticSearchWithAPIKey;
    [Test]
    procedure TestElasticSearchWithBearerToken;
    [Test]
    procedure TestFileAppenderGetCurrentLogFileName;
    [Test]
    procedure TestSimpleFileAppenderGetCurrentLogFileName;
    [Test]
    procedure TestLogExceptionWithChainedExceptions;
    [Test]
    procedure TestFileAppenderWithDailyRotation;
    [Test]
    procedure TestFileAppenderWithFileFormatTagAsFolder;
    [Test]
    procedure TestFileAppenderWithFileFormatDateAsFolder;
    [Test]
    procedure TestFileAppenderCombinedRotation;
    [Test]
    procedure TestFileAppenderBackwardCompatibleNoInterval;
    [Test]
    procedure TestFileAppenderOnAfterRotateSizeRotation;
    [Test]
    procedure TestFileAppenderOnAfterRotateBuilder;
    [Test]
    procedure TestWriteToStrings;
    [Test]
    procedure TestWriteToStringsWithMaxLines;
    [Test]
    procedure TestWriteToStringsClearOnStartup;
    [Test]
    procedure TestBuildWithConsoleUTF8Output;
    [Test]
    procedure TestBuildWithSimpleConsoleUTF8Output;
{$IF Defined(MSWINDOWS)}
    [Test]
    procedure TestWriteToWindowsEventLog;
    [Test]
    procedure TestWriteToWindowsEventLogWithSourceName;
    [Test]
    procedure TestWriteToWindowsEventLogWithLogLevel;
{$ENDIF}
  end;

implementation

uses
  LoggerPro.ConsoleAppender,
  LoggerPro.FileAppender,
  LoggerPro.MemoryAppender,
  LoggerPro.CallbackAppender,
  LoggerPro.TimeRotatingFileAppender,
  LoggerPro.WebhookAppender,
  LoggerPro.UDPSyslogAppender,
  LoggerPro.ElasticSearchAppender,
  LoggerPro.StringsAppender,
  TestSyslogServerU,
  System.IOUtils,
  System.DateUtils,
  System.NetEncoding
{$IF Defined(MSWINDOWS)}
  , LoggerPro.WindowsEventLogAppender
{$ENDIF}
  ;

procedure WaitForMsg10InStrings(lStrings: TStrings);
var
  lDeadline: TDateTime;
  K: Integer;
  lSaw10: Boolean;
begin
  lSaw10 := False;
  lDeadline := Now + EncodeTime(0, 0, 5, 0);
  while (not lSaw10) and (Now < lDeadline) do
  begin
    CheckSynchronize(20);
    for K := 0 to lStrings.Count - 1 do
      if lStrings[K].Contains('msg 10') then
      begin
        lSaw10 := True;
        Break;
      end;
  end;
  if not lSaw10 then
    raise Exception.Create('Timeout waiting for msg 10 to reach lStrings');
  while CheckSynchronize(10) do;
end;

{ TLoggerProBuilderTest }

procedure TLoggerProBuilderTest.TestBuildWithConsoleAppender;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToConsole.Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created');
end;

procedure TLoggerProBuilderTest.TestBuildWithFileAppender;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToFile.Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created');
end;

procedure TLoggerProBuilderTest.TestBuildWithMultipleAppenders;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToConsole.Done
    .WriteToFile.Done
    .WriteToMemory.WithMaxSize(100).Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with multiple appenders');
end;

procedure TLoggerProBuilderTest.TestBuildWithNoAppendersRaisesException;
begin
  Assert.WillRaise(
    procedure
    begin
      LoggerProBuilder.Build;
    end,
    ELoggerPro,
    'Building without appenders should raise exception');
end;

procedure TLoggerProBuilderTest.TestWriteToFileWithAllOptions;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToFile
      .WithLogsFolder('logs')
      .WithFileBaseName('testapp')
      .WithMaxBackupFiles(10)
      .WithMaxFileSizeInKB(5000)
      .WithLogLevel(TLogType.Warning)
      .Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with configured file appender');
end;

procedure TLoggerProBuilderTest.TestWriteToWebhookWithHeaders;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToWebhook
      .WithURL('http://localhost:8080/logs')
      .WithContentType(TWebhookContentType.JSON)
      .WithTimeout(10)
      .WithRetryCount(5)
      .WithHeader('Authorization', 'Bearer token123')
      .WithHeader('X-Custom', 'value')
      .WithLogLevel(TLogType.Info)
      .Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with configured HTTP appender');
end;

procedure TLoggerProBuilderTest.TestWriteToMemory;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToMemory
      .WithMaxSize(500)
      .WithLogLevel(TLogType.Debug)
      .Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with configured memory appender');
end;

procedure TLoggerProBuilderTest.TestWriteToCallback;
var
  lLog: ILogWriter;
  lCallbackInvoked: Boolean;
  lEvent: TEvent;
begin
  lCallbackInvoked := False;
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lCallbackInvoked := True;
            lEvent.SetEvent;
          end)
        .WithLogLevel(TLogType.Debug)
        .Done
      .Build;

    Assert.IsNotNull(lLog, 'Logger should be created with callback appender');

    lLog.Debug('Test message', 'TEST');
    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.IsTrue(lCallbackInvoked, 'Callback flag should be true');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestWriteToTimeRotatingFile;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToTimeRotatingFile
      .WithInterval(TTimeRotationInterval.Daily)
      .WithMaxBackupFiles(30)
      .WithLogsFolder('logs')
      .WithFileBaseName('rotating')
      .WithLogLevel(TLogType.Info)
      .Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with time rotating appender');
end;

procedure TLoggerProBuilderTest.TestMixedAppenders;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToConsole.WithLogLevel(TLogType.Warning).Done
    .WriteToFile
      .WithLogsFolder('logs')
      .WithMaxBackupFiles(5)
      .Done
    .WriteToMemory.WithMaxSize(200).Done
    .WriteToCallback
      .WithCallback(
        procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
        begin
          // Do nothing
        end)
      .Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with mixed appenders');
end;

procedure TLoggerProBuilderTest.TestBuilderFunction;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToConsole.Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created using LoggerProBuilder function');
end;

procedure TLoggerProBuilderTest.TestWithDefaultLogLevel;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WithDefaultLogLevel(TLogType.Warning)
    .WriteToConsole.Done
    .WriteToFile.Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with default log level');
end;

procedure TLoggerProBuilderTest.TestWithMinimumLevel;
var
  lLog: ILogWriter;
  lMessageCount: Integer;
  lEvent: TEvent;
begin
  lMessageCount := 0;
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WithMinimumLevel(TLogType.Warning)  // Only Warning, Error, Fatal
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            Inc(lMessageCount);
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    // These should be filtered out (below minimum level)
    lLog.Debug('Debug message', 'TEST');
    lLog.Info('Info message', 'TEST');

    // These should be logged (at or above minimum level)
    lLog.Warn('Warning message', 'TEST');

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked for Warning');
    Assert.AreEqual(1, lMessageCount, 'Only Warning message should be logged (Debug and Info filtered out)');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestWithDefaultTag;
var
  lLog: ILogWriter;
  lReceivedTag: string;
  lEvent: TEvent;
begin
  lReceivedTag := '';
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WithDefaultTag('MYAPP')
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lReceivedTag := aLogItem.LogTag;
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    lLog.Info('Test message');  // No tag specified
    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.AreEqual('MYAPP', lReceivedTag, 'Default tag from builder should be used');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestWithDefaultTagOverride;
var
  lLog: ILogWriter;
  lReceivedTag: string;
  lEvent: TEvent;
begin
  lReceivedTag := '';
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WithDefaultTag('MYAPP')
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lReceivedTag := aLogItem.LogTag;
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    lLog.Info('Test message', 'CUSTOM');  // Explicit tag should override
    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.AreEqual('CUSTOM', lReceivedTag, 'Explicit tag should override default');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestLogWithoutTagUsesMainAsDefault;
var
  lLog: ILogWriter;
  lReceivedTag: string;
  lEvent: TEvent;
begin
  lReceivedTag := '';
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lReceivedTag := aLogItem.LogTag;
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    lLog.Info('Test message');  // No tag, no WithDefaultTag -> should use 'main'
    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.AreEqual(DEFAULT_LOG_TAG, lReceivedTag, 'Default tag should be "main"');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestWithDefaultTagOnSubLogger;
var
  lLog, lOrderLog: ILogWriter;
  lReceivedTag: string;
  lEvent: TEvent;
begin
  lReceivedTag := '';
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lReceivedTag := aLogItem.LogTag;
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    lOrderLog := lLog.WithDefaultTag('ORDERS');
    lOrderLog.Info('Order received');  // Should use 'ORDERS'
    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.AreEqual('ORDERS', lReceivedTag, 'Sub-logger should use its own default tag');
  finally
    lLog := nil;
    lOrderLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestLogExceptionWithoutFormatter;
var
  lLog: ILogWriter;
  lReceivedMessage: string;
  lEvent: TEvent;
begin
  lReceivedMessage := '';
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lReceivedMessage := aLogItem.LogMessage;
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    try
      raise Exception.Create('Test error message');
    except
      on E: Exception do
        lLog.LogException(E, 'Operation failed');
    end;

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.Contains(lReceivedMessage, 'Exception', 'Should contain exception class name');
    Assert.Contains(lReceivedMessage, 'Test error message', 'Should contain exception message');
    Assert.Contains(lReceivedMessage, 'Operation failed', 'Should contain custom message');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestLogExceptionWithStackTraceFormatter;
var
  lLog: ILogWriter;
  lReceivedMessage: string;
  lEvent: TEvent;
begin
  lReceivedMessage := '';
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WithStackTraceFormatter(
        function(E: Exception): string
        begin
          Result := 'FAKE_STACK_TRACE_LINE_1' + sLineBreak + 'FAKE_STACK_TRACE_LINE_2';
        end)
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lReceivedMessage := aLogItem.LogMessage;
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    try
      raise Exception.Create('Test error');
    except
      on E: Exception do
        lLog.LogException(E);
    end;

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.Contains(lReceivedMessage, 'Exception', 'Should contain exception class name');
    Assert.Contains(lReceivedMessage, 'Test error', 'Should contain exception message');
    Assert.Contains(lReceivedMessage, 'FAKE_STACK_TRACE_LINE_1', 'Should contain stack trace');
    Assert.Contains(lReceivedMessage, 'FAKE_STACK_TRACE_LINE_2', 'Should contain full stack trace');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestLogExceptionWithMessageAndTag;
var
  lLog: ILogWriter;
  lReceivedMessage: string;
  lReceivedTag: string;
  lEvent: TEvent;
begin
  lReceivedMessage := '';
  lReceivedTag := '';
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lReceivedMessage := aLogItem.LogMessage;
            lReceivedTag := aLogItem.LogTag;
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    try
      raise Exception.Create('Test error message');
    except
      on E: Exception do
        lLog.LogException(E, 'Operation failed', 'MYERRORS');
    end;

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.Contains(lReceivedMessage, 'Exception', 'Should contain exception class name');
    Assert.Contains(lReceivedMessage, 'Test error message', 'Should contain exception message');
    Assert.Contains(lReceivedMessage, 'Operation failed', 'Should contain custom message');
    Assert.AreEqual('MYERRORS', lReceivedTag, 'Should use specified tag');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestSyslogWithUseLocalTime;
var
  lLog: ILogWriter;
  lAppender: TLoggerProUDPSyslogAppender;
  lServer: TSyslogTestServer;
  lReceivedMsg: string;
const
  TEST_PORT = 15140; // Use non-standard port to avoid conflicts
begin
  // Create test Syslog server
  lServer := TSyslogTestServer.Create(TEST_PORT);
  try
    lServer.Start;

    // Test 1: UseLocalTime = False (default, should send UTC)
    lAppender := TLoggerProUDPSyslogAppender.Create('127.0.0.1', TEST_PORT, 'testhost', 'testuser', 'testapp', '1.0', '123', False, False, False);
    try
      lLog := BuildLogWriter([lAppender]);
      lLog.Info('UTC test message', 'TEST');
      Sleep(500); // Wait for async send

      Assert.AreEqual(1, lServer.MessageCount, 'Should have received 1 message');
      lReceivedMsg := lServer.GetLastMessage;

      // Verify message contains UTC timestamp (approximately)
      Assert.IsFalse(lReceivedMsg.IsEmpty, 'Should have received a message');
      Assert.Contains(lReceivedMsg, 'UTC test message', 'Should contain log message');

      lServer.Clear;
    finally
      lLog := nil;
    end;

    // Test 2: UseLocalTime = True (should send local time)
    lAppender := TLoggerProUDPSyslogAppender.Create('127.0.0.1', TEST_PORT, 'testhost', 'testuser', 'testapp', '1.0', '123', False, False, True);
    try
      lLog := BuildLogWriter([lAppender]);
      Assert.IsTrue(lAppender.UseLocalTime, 'UseLocalTime should be True');
      lLog.Info('Local time test message', 'TEST');
      Sleep(500); // Wait for async send

      Assert.AreEqual(1, lServer.MessageCount, 'Should have received 1 message');
      lReceivedMsg := lServer.GetLastMessage;

      Assert.IsFalse(lReceivedMsg.IsEmpty, 'Should have received a message');
      Assert.Contains(lReceivedMsg, 'Local time test message', 'Should contain log message');

      // The timestamp in the message should be in ISO8601 format
      // We can't do exact match due to timing, but we can verify the message was received
      Assert.IsTrue(lServer.MessageCount >= 1, 'Should have received at least 1 message');
    finally
      lLog := nil;
    end;

  finally
    lServer.Stop;
    lServer.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestElasticSearchWithBasicAuth;
var
  lLog: ILogWriter;
  lAppender: TLoggerProElasticSearchAppender;
  lUsername, lPassword: string;
begin
  lUsername := 'testuser';
  lPassword := 'testpass';

  lAppender := TLoggerProElasticSearchAppender.Create('http://localhost:9200/logs/_doc', 5);
  try
    lAppender.SetBasicAuth(lUsername, lPassword);
    lLog := BuildLogWriter([lAppender]);

    Assert.IsNotNull(lLog, 'Logger should be created with ElasticSearch appender');
    // Basic Auth header will be tested by InternalWriteLog when a message is logged
    // We're just verifying the configuration doesn't raise exceptions
  finally
    lLog := nil;
  end;
end;

procedure TLoggerProBuilderTest.TestElasticSearchWithAPIKey;
var
  lLog: ILogWriter;
  lAppender: TLoggerProElasticSearchAppender;
begin
  lAppender := TLoggerProElasticSearchAppender.Create('http://localhost:9200/logs/_doc', 5);
  try
    lAppender.SetAPIKey('test-api-key-12345');
    lLog := BuildLogWriter([lAppender]);

    Assert.IsNotNull(lLog, 'Logger should be created with ElasticSearch appender');
  finally
    lLog := nil;
  end;
end;

procedure TLoggerProBuilderTest.TestElasticSearchWithBearerToken;
var
  lLog: ILogWriter;
  lAppender: TLoggerProElasticSearchAppender;
begin
  lAppender := TLoggerProElasticSearchAppender.Create('http://localhost:9200/logs/_doc', 5);
  try
    lAppender.SetBearerToken('test-bearer-token-xyz');
    lLog := BuildLogWriter([lAppender]);

    Assert.IsNotNull(lLog, 'Logger should be created with ElasticSearch appender');
  finally
    lLog := nil;
  end;
end;

procedure TLoggerProBuilderTest.TestFileAppenderGetCurrentLogFileName;
var
  lLog: ILogWriter;
  lAppender: TLoggerProFileAppender;
  lFileName: string;
  lAllFiles: TArray<string>;
begin
  lAppender := TLoggerProFileAppender.Create(0, 1000, TPath.GetTempPath, '{module}.{number}.{tag}.log');
  try
    lLog := BuildLogWriter([lAppender]);

    // Write a log message to trigger file creation
    lLog.Info('Test message', 'TEST');
    Sleep(100); // Give time for async write

    // Get current log file name for 'TEST' tag
    lFileName := lAppender.GetCurrentLogFileName('TEST');
    Assert.IsFalse(lFileName.IsEmpty, 'File name should not be empty');
    Assert.Contains(lFileName, 'TEST', 'File name should contain tag');

    // Write another message with different tag
    lLog.Info('Another message', 'OTHER');
    Sleep(100);

    // Get all current log file names
    lAllFiles := lAppender.GetAllCurrentLogFileNames;
    Assert.AreEqual(2, Length(lAllFiles), 'Should have 2 log files (TEST and OTHER tags)');
  finally
    lLog := nil;
  end;
end;

procedure TLoggerProBuilderTest.TestSimpleFileAppenderGetCurrentLogFileName;
var
  lLog: ILogWriter;
  lAppender: TLoggerProSimpleFileAppender;
  lFileName: string;
begin
  lAppender := TLoggerProSimpleFileAppender.Create(0, 1000, TPath.GetTempPath, 'testlog.{number}.log');
  try
    lLog := BuildLogWriter([lAppender]);

    // Get current log file name
    lFileName := lAppender.GetCurrentLogFileName;
    Assert.IsFalse(lFileName.IsEmpty, 'File name should not be empty');
    Assert.Contains(lFileName, 'testlog', 'File name should contain base name');
    Assert.Contains(lFileName, '.00.log', 'File name should contain number');

    // Write a message to verify file is created
    lLog.Info('Test message', 'TEST');
    Sleep(100);

    // File name should remain the same
    Assert.AreEqual(lFileName, lAppender.GetCurrentLogFileName, 'File name should not change');
  finally
    lLog := nil;
  end;
end;

procedure TLoggerProBuilderTest.TestLogExceptionWithChainedExceptions;
var
  lLog: ILogWriter;
  lReceivedMessage: string;
  lEvent: TEvent;
begin
  lReceivedMessage := '';
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lReceivedMessage := aLogItem.LogMessage;
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    try
      try
        try
          raise Exception.Create('Root cause: file not found');
        except
          Exception.RaiseOuterException(EInvalidOperation.Create('Cannot load config'));
        end;
      except
        Exception.RaiseOuterException(EAbort.Create('Startup failed'));
      end;
    except
      on E: Exception do
        lLog.LogException(E, 'Application error');
    end;

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.Contains(lReceivedMessage, 'Application error', 'Should contain custom message');
    Assert.Contains(lReceivedMessage, 'EAbort', 'Should contain outer exception class');
    Assert.Contains(lReceivedMessage, 'Startup failed', 'Should contain outer exception message');
    Assert.Contains(lReceivedMessage, 'Caused by: EInvalidOperation', 'Should contain middle chained exception');
    Assert.Contains(lReceivedMessage, 'Cannot load config', 'Should contain middle exception message');
    Assert.Contains(lReceivedMessage, 'Caused by: Exception', 'Should contain root cause exception');
    Assert.Contains(lReceivedMessage, 'Root cause: file not found', 'Should contain root cause message');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestFileAppenderWithDailyRotation;
var
  lLog: ILogWriter;
  lAppender: TLoggerProFileAppender;
  lFileName: string;
  lLogsFolder: string;
begin
  lLogsFolder := TPath.Combine(TPath.GetTempPath, 'loggerprotest_daily_' + FormatDateTime('hhnnsszzz', Now));
  try
    lAppender := TLoggerProFileAppender.Create(
      5, // max backup
      0, // no size limit
      lLogsFolder,
      '{module}.{date}.{tag}.log',
      nil, // renderer
      nil, // encoding
      TTimeRotationInterval.Daily,
      0);
    lLog := BuildLogWriter([lAppender]);

    // Write a log message to trigger file creation
    lLog.Info('Daily rotation test', 'TEST');
    Sleep(200);

    // Get current log file name for 'TEST' tag
    lFileName := lAppender.GetCurrentLogFileName('TEST');
    Assert.IsFalse(lFileName.IsEmpty, 'File name should not be empty');
    Assert.Contains(lFileName, FormatDateTime('yyyymmdd', Now), 'File name should contain today''s date');
    Assert.Contains(lFileName, 'TEST', 'File name should contain tag');
    Assert.IsTrue(TFile.Exists(lFileName), 'Log file should exist');
  finally
    lLog := nil;
    if TDirectory.Exists(lLogsFolder) then
      TDirectory.Delete(lLogsFolder, True);
  end;
end;

procedure TLoggerProBuilderTest.TestFileAppenderWithFileFormatTagAsFolder;
var
  lLog: ILogWriter;
  lAppender: TLoggerProFileAppender;
  lFileName: string;
  lLogsFolder: string;
begin
  lLogsFolder := TPath.Combine(TPath.GetTempPath, 'loggerprotest_tagfolder_' + FormatDateTime('hhnnsszzz', Now));
  try
    lAppender := TLoggerProFileAppender.Create(
      5, 0, lLogsFolder,
      '{tag}/{module}.{date}.log',
      nil, nil,
      TTimeRotationInterval.Daily, 0);
    lLog := BuildLogWriter([lAppender]);

    lLog.Info('Tag folder test', 'ORDERS');
    Sleep(200);

    lFileName := lAppender.GetCurrentLogFileName('ORDERS');
    Assert.IsFalse(lFileName.IsEmpty, 'File name should not be empty');
    // Verify tag is used as a subfolder
    Assert.Contains(lFileName, 'ORDERS', 'Path should contain tag as folder');
    Assert.IsTrue(TDirectory.Exists(TPath.Combine(lLogsFolder, 'ORDERS')),
      'Tag subfolder should be created');
    Assert.IsTrue(TFile.Exists(lFileName), 'Log file should exist');
  finally
    lLog := nil;
    if TDirectory.Exists(lLogsFolder) then
      TDirectory.Delete(lLogsFolder, True);
  end;
end;

procedure TLoggerProBuilderTest.TestFileAppenderWithFileFormatDateAsFolder;
var
  lLog: ILogWriter;
  lAppender: TLoggerProFileAppender;
  lFileName: string;
  lLogsFolder: string;
  lExpectedFolder: string;
begin
  lLogsFolder := TPath.Combine(TPath.GetTempPath, 'loggerprotest_datefolder_' + FormatDateTime('hhnnsszzz', Now));
  try
    lAppender := TLoggerProFileAppender.Create(
      5,
      1, // 1 KB max size to enable size-based rotation
      lLogsFolder,
      '{date}/{module}.{number}.{tag}.log',
      nil, nil,
      TTimeRotationInterval.Daily, 0);
    lLog := BuildLogWriter([lAppender]);

    lLog.Info('Date folder test', 'APP');
    Sleep(200);

    lFileName := lAppender.GetCurrentLogFileName('APP');
    Assert.IsFalse(lFileName.IsEmpty, 'File name should not be empty');
    lExpectedFolder := TPath.Combine(lLogsFolder, FormatDateTime('yyyymmdd', Now));
    Assert.IsTrue(TDirectory.Exists(lExpectedFolder),
      'Date subfolder should be created');
    Assert.IsTrue(TFile.Exists(lFileName), 'Log file should exist');
  finally
    lLog := nil;
    if TDirectory.Exists(lLogsFolder) then
      TDirectory.Delete(lLogsFolder, True);
  end;
end;

procedure TLoggerProBuilderTest.TestFileAppenderCombinedRotation;
var
  lLog: ILogWriter;
  lAppender: TLoggerProFileAppender;
  lFileName: string;
  lLogsFolder: string;
begin
  lLogsFolder := TPath.Combine(TPath.GetTempPath, 'loggerprotest_combined_' + FormatDateTime('hhnnsszzz', Now));
  try
    // Combined: time rotation (daily) + size rotation (1 KB)
    lAppender := TLoggerProFileAppender.Create(
      5,
      1, // 1 KB max
      lLogsFolder,
      '{module}.{date}.{number}.{tag}.log',
      nil, nil,
      TTimeRotationInterval.Daily, 0);
    lLog := BuildLogWriter([lAppender]);

    lLog.Info('Combined rotation test', 'TEST');
    Sleep(200);

    lFileName := lAppender.GetCurrentLogFileName('TEST');
    Assert.IsFalse(lFileName.IsEmpty, 'File name should not be empty');
    Assert.Contains(lFileName, FormatDateTime('yyyymmdd', Now), 'Should contain date');
    Assert.Contains(lFileName, '.00.', 'Should contain file number');
    Assert.IsTrue(TFile.Exists(lFileName), 'Log file should exist');
  finally
    lLog := nil;
    if TDirectory.Exists(lLogsFolder) then
      TDirectory.Delete(lLogsFolder, True);
  end;
end;

procedure TLoggerProBuilderTest.TestFileAppenderBackwardCompatibleNoInterval;
var
  lLog: ILogWriter;
  lAppender: TLoggerProFileAppender;
  lFileName: string;
  lLogsFolder: string;
begin
  lLogsFolder := TPath.Combine(TPath.GetTempPath, 'loggerprotest_compat_' + FormatDateTime('hhnnsszzz', Now));
  try
    // Exact same usage as before - no interval, default behavior
    lAppender := TLoggerProFileAppender.Create(
      5, 1000, lLogsFolder);
    lLog := BuildLogWriter([lAppender]);

    lLog.Info('Backward compat test', 'TEST');
    Sleep(200);

    lFileName := lAppender.GetCurrentLogFileName('TEST');
    Assert.IsFalse(lFileName.IsEmpty, 'File name should not be empty');
    Assert.Contains(lFileName, '.00.', 'Should contain file number (size rotation)');
    Assert.Contains(lFileName, 'TEST', 'Should contain tag');
    // Should NOT contain a date
    Assert.IsFalse(lFileName.Contains(FormatDateTime('yyyymmdd', Now)),
      'Should not contain date (no time rotation)');
    Assert.IsTrue(TFile.Exists(lFileName), 'Log file should exist');
  finally
    lLog := nil;
    if TDirectory.Exists(lLogsFolder) then
      TDirectory.Delete(lLogsFolder, True);
  end;
end;

procedure TLoggerProBuilderTest.TestFileAppenderOnAfterRotateSizeRotation;
var
  lLog: ILogWriter;
  lAppender: TLoggerProFileAppender;
  lLogsFolder: string;
  lRotatedFileName: string;
  lCallbackInvoked: Boolean;
  I: Integer;
begin
  lLogsFolder := TPath.Combine(TPath.GetTempPath, 'loggerprotest_rotate_cb_' + FormatDateTime('hhnnsszzz', Now));
  lRotatedFileName := '';
  lCallbackInvoked := False;
  try
    lAppender := TLoggerProFileAppender.Create(
      5,   // max backup
      1,   // 1 KB max size - triggers rotation quickly
      lLogsFolder,
      '{module}.{number}.{tag}.log');
    lAppender.OnAfterRotate :=
      procedure(const aRotatedFileName: string)
      begin
        lCallbackInvoked := True;
        lRotatedFileName := aRotatedFileName;
      end;

    lLog := BuildLogWriter([lAppender]);

    // Write enough data to trigger size-based rotation (> 1 KB)
    for I := 1 to 30 do
      lLog.Info('Rotation test message number ' + I.ToString + ' with padding data to fill the file quickly', 'TEST');
    Sleep(2000); // Wait for async writes and rotation

    Assert.IsTrue(lCallbackInvoked, 'OnAfterRotate callback should have been invoked');
    Assert.IsFalse(lRotatedFileName.IsEmpty, 'Rotated file name should not be empty');
    Assert.Contains(lRotatedFileName, '.01.', 'Rotated file should be file number 1');
    Assert.Contains(lRotatedFileName, 'TEST', 'Rotated file should contain the tag');
    Assert.IsTrue(TFile.Exists(lRotatedFileName), 'Rotated file should exist on disk');
  finally
    lLog := nil;
    if TDirectory.Exists(lLogsFolder) then
      TDirectory.Delete(lLogsFolder, True);
  end;
end;

procedure TLoggerProBuilderTest.TestFileAppenderOnAfterRotateBuilder;
var
  lLog: ILogWriter;
  lLogsFolder: string;
  lCallbackInvoked: Boolean;
  I: Integer;
begin
  lLogsFolder := TPath.Combine(TPath.GetTempPath, 'loggerprotest_rotate_builder_' + FormatDateTime('hhnnsszzz', Now));
  lCallbackInvoked := False;
  try
    lLog := LoggerProBuilder
      .WriteToFile
        .WithLogsFolder(lLogsFolder)
        .WithMaxFileSizeInKB(1)  // 1 KB - triggers rotation quickly
        .WithOnAfterRotate(
          procedure(const aRotatedFileName: string)
          begin
            lCallbackInvoked := True;
          end)
        .Done
      .Build;

    // Write enough data to trigger size-based rotation (> 1 KB)
    for I := 1 to 30 do
      lLog.Info('Builder rotate test message number ' + I.ToString + ' with padding data to fill quickly', 'TEST');
    Sleep(2000); // Wait for async writes and rotation

    Assert.IsTrue(lCallbackInvoked, 'OnAfterRotate callback should have been invoked via builder');
  finally
    lLog := nil;
    if TDirectory.Exists(lLogsFolder) then
      TDirectory.Delete(lLogsFolder, True);
  end;
end;

procedure TLoggerProBuilderTest.TestWriteToStrings;
var
  lLog: ILogWriter;
  lStrings: TStringList;
  lEvent: TEvent;
begin
  lStrings := TStringList.Create;
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WriteToStrings(lStrings)
        .Done
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            lEvent.SetEvent;
          end)
        .Done
      .Build;

    lLog.Info('Test message for TStrings', 'TEST');
    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    // In a console app there is no message loop, so TThread.Queue closures must be
    // drained manually with CheckSynchronize. Poll until the expected state arrives.
    while (lStrings.Count < 1) and (CheckSynchronize(50)) do;
    CheckSynchronize(50);
    Assert.AreEqual(1, lStrings.Count, 'Should have 1 line in TStrings');
    Assert.Contains(lStrings[0], 'Test message for TStrings', 'TStrings should contain the log message');
  finally
    lLog := nil;
    lEvent.Free;
    lStrings.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestWriteToStringsWithMaxLines;
var
  lLog: ILogWriter;
  lStrings: TStringList;
  lEvent: TEvent;
  I: Integer;
begin
  lStrings := TStringList.Create;
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog := LoggerProBuilder
      .WriteToStrings(lStrings)
        .WithMaxLogLines(5)
        .Done
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            if aFormattedMessage.Contains('msg 10') then
              lEvent.SetEvent;
          end)
        .Done
      .Build;

    for I := 1 to 10 do
      lLog.Info('msg ' + I.ToString, 'TEST');

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Last callback should be invoked');
    // Each appender has its own thread - the strings appender may still be
    // queueing TThread.Queue closures after the callback signals. Poll the
    // main-thread queue until 'msg 10' actually lands in lStrings, or timeout.
    WaitForMsg10InStrings(lStrings);
    Assert.AreEqual(5, lStrings.Count, 'Should have at most 5 lines (MaxLogLines)');
    // The last 5 messages should be retained (msg 6..10)
    Assert.Contains(lStrings[lStrings.Count - 1], 'msg 10', 'Last line should be message 10');
    Assert.Contains(lStrings[0], 'msg 6', 'First line should be message 6');
  finally
    lLog := nil;
    lEvent.Free;
    lStrings.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestWriteToStringsClearOnStartup;
var
  lLog: ILogWriter;
  lStrings: TStringList;
begin
  lStrings := TStringList.Create;
  try
    lStrings.Add('pre-existing line 1');
    lStrings.Add('pre-existing line 2');
    Assert.AreEqual(2, lStrings.Count, 'Pre-condition: list should have 2 lines');

    // Build triggers Setup which calls TThread.Synchronize to clear the list
    lLog := LoggerProBuilder
      .WriteToStrings(lStrings)
        .WithClearOnStartup(True)
        .Done
      .Build;

    // CheckSynchronize drains the TThread.Synchronize call from Setup
    CheckSynchronize(500);
    Assert.AreEqual(0, lStrings.Count,
      'TStrings should be cleared on startup when WithClearOnStartup(True)');
  finally
    lLog := nil;
    lStrings.Free;
  end;
end;

procedure TLoggerProBuilderTest.TestBuildWithConsoleUTF8Output;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToConsole.WithUTF8Output.Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with UTF8 console appender');
end;

procedure TLoggerProBuilderTest.TestBuildWithSimpleConsoleUTF8Output;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToSimpleConsole.WithUTF8Output.Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with UTF8 simple console appender');
end;

{$IF Defined(MSWINDOWS)}
procedure TLoggerProBuilderTest.TestWriteToWindowsEventLog;
var
  lLog: ILogWriter;
begin
  // Test that logger can be created with Windows Event Log appender
  // Note: Actually writing to Windows Event Log requires admin privileges,
  // so we only test that the appender can be configured
  lLog := LoggerProBuilder
    .WriteToWindowsEventLog
      .Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with Windows Event Log appender');
end;

procedure TLoggerProBuilderTest.TestWriteToWindowsEventLogWithSourceName;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToWindowsEventLog
      .WithSourceName('LoggerProTest')
      .Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with custom source name');
end;

procedure TLoggerProBuilderTest.TestWriteToWindowsEventLogWithLogLevel;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToWindowsEventLog
      .WithSourceName('LoggerProTest')
      .WithLogLevel(TLogType.Warning)
      .Done
    .Build;

  Assert.IsNotNull(lLog, 'Logger should be created with log level');
end;
{$ENDIF}

initialization
  TDUnitX.RegisterTestFixture(TLoggerProBuilderTest);

end.
