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
  Result := True;
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
  lAppenders: TArray<String>;
  lSavedLoggerProAppenderQueueSize: Cardinal;
  lOldestsDiscarded: Int64;
  lNewestsSkipped: Int64;
  lCount: Int64;
  lTempCount: Int64;
begin
  lCount := 0;
  lSavedLoggerProAppenderQueueSize := DefaultLoggerProAppenderQueueSize;
  DefaultLoggerProAppenderQueueSize := 0;

  lNewestsSkipped := 0;
  lOldestsDiscarded := 0;
  lEventsHandlers := TLoggerProEventsHandler.Create;
  try
    lEventsHandlers.OnAppenderError :=
        procedure(const AppenderClassName: String;
        const FailedLogItem: TLogItem; const Reason: TLogErrorReason;
        var Action: TLogErrorAction)
      var
        lLocalCount: Int64;
      begin
        lLocalCount := TInterlocked.Add(lCount, 1);
        if lLocalCount <= 20 then
        begin
          Action := TLogErrorAction.SkipNewest;
          TInterlocked.Increment(lNewestsSkipped);
        end
        else
        begin
          Action := TLogErrorAction.DiscardOlder;
          TInterlocked.Increment(lOldestsDiscarded);
        end;
      end;

    lLog := BuildLogWriter([TMyVerySlowAppender.Create(1)], lEventsHandlers);
    for I := 1 to 40 do
    begin
      lLog.Debug('log message ' + I.ToString, 'tag');
    end;

    while True do
    begin
      lTempCount := TInterlocked.Read(lNewestsSkipped);
      if lTempCount < 20 then
        Sleep(10)
      else
        break;
    end;

    while True do
    begin
      lTempCount := TInterlocked.Read(lOldestsDiscarded);
      if lTempCount < 20 then
        Sleep(10)
      else
        break;
    end;

    while TInterlocked.Read(lCount) < 40 do
      Sleep(100);

    lAppenders := lLog.GetAppendersClassNames;
    Assert.AreEqual(1, Length(lAppenders));
    Assert.AreEqual('TMyVerySlowAppender', lAppenders[0]);
    lLog := nil;
  finally
    DefaultLoggerProAppenderQueueSize := lSavedLoggerProAppenderQueueSize;
    lEventsHandlers.Free;
  end;

end;

procedure TLoggerProTest.TestTLogItemClone;
var
  lLogItem: TLogItem;
  lClonedLogItem: TLogItem;
begin
  lLogItem := TLogItem.Create(TLogType.Debug, 'message', 'tag');
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
  lLogItem := TLogItem.Create(TLogType(aLogType), 'message', 'tag');
  try
    Assert.AreEqual(aExpected, lLogItem.LogTypeAsString);
  finally
    lLogItem.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TLoggerProTest);

end.
