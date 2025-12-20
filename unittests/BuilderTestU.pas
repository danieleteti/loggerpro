unit BuilderTestU;

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
    procedure TestWriteToHTTPWithHeaders;
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
  end;

implementation

uses
  LoggerPro.ConsoleAppender,
  LoggerPro.FileAppender,
  LoggerPro.MemoryAppender,
  LoggerPro.CallbackAppender,
  LoggerPro.TimeRotatingFileAppender,
  LoggerPro.HTTPAppender;

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

procedure TLoggerProBuilderTest.TestWriteToHTTPWithHeaders;
var
  lLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToHTTP
      .WithURL('http://localhost:8080/logs')
      .WithContentType(THTTPContentType.JSON)
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

initialization
  TDUnitX.RegisterTestFixture(TLoggerProBuilderTest);

end.
