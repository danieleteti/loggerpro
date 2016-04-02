unit LoggerProTestU;

interface

uses
  DUnitX.TestFramework, LoggerPro;

type

  [TestFixture]
  TLoggerProTest = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestTLogItemClone;
    [Test]
    [TestCase('Type DEBUG', '0,DEBUG')]
    [TestCase('Type INFO', '1,INFO')]
    [TestCase('Type WARN', '2,WARNING')]
    [TestCase('Type ERROR', '3,ERROR')]
    procedure TestTLogItemTypeAsString(aLogType: Byte; aExpected: String);

    [Test]
    procedure TestOnAppenderError;

    [Test]
    procedure TestLogLevel;
  end;

implementation

uses
  System.SysUtils, TestSupportAppendersU, System.SyncObjs;

function LogItemAreEquals(A, B: TLogItem): Boolean;
begin
  Assert.AreEqual(A.LogType, B.LogType, 'LogType is different');
  Assert.AreEqual(A.LogMessage, B.LogMessage, 'LogMessage is different');
  Assert.AreEqual(A.LogTag, B.LogTag, 'LogTag is different');
  Assert.AreEqual(A.TimeStamp, B.TimeStamp, 'TimeStamp is different');
  Assert.AreEqual(A.ThreadID, B.ThreadID, 'ThreadID is different');
  Assert.AreEqual(A.RetriesCount, B.RetriesCount, 'RetriesCount is different');
end;

procedure TLoggerProTest.Setup;
begin
end;

procedure TLoggerProTest.TearDown;
begin
end;

procedure TLoggerProTest.TestLogLevel;
var
  lSetup, lTearDown: TProc;
  lTearDownCalled, lSetupCalled: Boolean;
  lWriteLog: TProc<TLogItem>;
  lLogWriter: ILogWriter;
  lLogItem: TLogItem;
  lEvent: TEvent;
  lLock: TObject;
  lHistory: TArray<String>;
begin
  lHistory := [];
  lLock := TObject.Create;
  try
    lSetup := procedure
      begin
        lHistory := lHistory + ['setup'];
        lSetupCalled := True;
      end;
    lTearDown := procedure
      begin
        lHistory := lHistory + ['teardown'];
        lTearDownCalled := True;
      end;
    lWriteLog := procedure(aLogItem: TLogItem)
      begin
        lHistory := lHistory + ['writelog' + aLogItem.LogTypeAsString];
        TMonitor.Enter(lLock);
        try
          FreeAndNil(lLogItem);
          lLogItem := aLogItem.Clone;
          lEvent.SetEvent;
        finally
          TMonitor.Exit(lLock);
        end;
      end;

    lLogWriter := BuildLogWriter([TMyAppender.Create(lSetup, lTearDown,
      lWriteLog)]);
    lEvent := TEvent.Create(nil, True, false, '');
    try
      // debug message
      lEvent.ResetEvent;
      lLogWriter.Debug('debug message', 'debug');
      Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000),
        'Event not released after 5 seconds');
      Assert.AreEqual('debug message', lLogItem.LogMessage);
      Assert.AreEqual('debug', lLogItem.LogTag);
      Assert.AreEqual('DEBUG', lLogItem.LogTypeAsString);

      // info message
      lEvent.ResetEvent;
      lLogWriter.Info('info message', 'info');
      Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000),
        'Event not released after 5 seconds');
      Assert.AreEqual('info message', lLogItem.LogMessage);
      Assert.AreEqual('info', lLogItem.LogTag);
      Assert.AreEqual('INFO', lLogItem.LogTypeAsString);

      // warning message
      lEvent.ResetEvent;
      lLogWriter.Warn('warning message', 'warning');
      Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000),
        'Event not released after 5 seconds');
      Assert.AreEqual('warning message', lLogItem.LogMessage);
      Assert.AreEqual('warning', lLogItem.LogTag);
      Assert.AreEqual('WARNING', lLogItem.LogTypeAsString);

      // error message
      lEvent.ResetEvent;
      lLogWriter.Error('error message', 'error');
      Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000),
        'Event not released after 5 seconds');
      Assert.AreEqual('error message', lLogItem.LogMessage);
      Assert.AreEqual('error', lLogItem.LogTag);
      Assert.AreEqual('ERROR', lLogItem.LogTypeAsString);

      lLogWriter := nil;
      Assert.AreEqual(6, Length(lHistory));
      Assert.AreEqual('setup', lHistory[0]);
      Assert.AreEqual('writelogDEBUG', lHistory[1]);
      Assert.AreEqual('writelogINFO', lHistory[2]);
      Assert.AreEqual('writelogWARNING', lHistory[3]);
      Assert.AreEqual('writelogERROR', lHistory[4]);
      Assert.AreEqual('teardown', lHistory[5]);
    finally
      lEvent.Free;
    end;
  finally
    lLock.Free;
  end;
end;

procedure TLoggerProTest.TestOnAppenderError;
var
  lLog: ILogWriter;
  I: Integer;
  lEventsHandlers: TLoggerProEventsHandler;
begin
  lEventsHandlers := TLoggerProEventsHandler.Create;
  try
    lEventsHandlers.OnAppenderError :=
        procedure(const AppenderClassName: String;
        const FailedLogItem: TLogItem; const Reason: TLogErrorReason;
        var Action: TLogErrorAction)
      begin
        if FailedLogItem.RetriesCount > 0 then
          Action := TLogErrorAction.Skip
        else
          Action := TLogErrorAction.Retry;
      end;

    lLog := BuildLogWriter([TMyVerySlowAppender.Create(100000)],
      lEventsHandlers);
    for I := 1 to 2 do
    begin
      lLog.Debug('log message', 'tag');
    end;
    lLog := nil;
  finally
    lEventsHandlers.Free;
  end;

end;

procedure TLoggerProTest.TestTLogItemClone;
var
  lLogItem: TLogItem;
  lClonedLogItem: TLogItem;
begin
  lLogItem := TLogItem.Create(TLogType.Debug, 'message', 'tag', 1);
  try
    lClonedLogItem := lLogItem.Clone;
    try
      LogItemAreEquals(lLogItem, lClonedLogItem);
    finally
      lClonedLogItem.Free;
    end;
  finally
    lLogItem.Free;
  end;
end;

procedure TLoggerProTest.TestTLogItemTypeAsString(aLogType: Byte;
  aExpected: String);
var
  lLogItem: TLogItem;
begin
  lLogItem := TLogItem.Create(TLogType(aLogType), 'message', 'tag', 1);
  try
    Assert.AreEqual(aExpected, lLogItem.LogTypeAsString);
  finally
    lLogItem.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TLoggerProTest);

end.
