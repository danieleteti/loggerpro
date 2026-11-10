unit CaptureTestU;

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  LoggerPro,
  LoggerPro.Builder,
  LoggerPro.MemoryAppender;

type
  /// <summary>
  /// The capture hook of LoggerPro: a function that runs on the thread that logs, for Error and Fatal only, and
  /// whose result travels in TLogItem.Captured to the appenders (which run on the thread of the logger).
  /// </summary>
  [TestFixture]
  TTestLoggerCapture = class
  private
    function NewLogger(const ACapture: TLogItemCapture; out AAppender: TLoggerProMemoryRingBufferAppender): ILogWriter;
    // a routine of its own: its closure must not share a frame with the one that holds the capture
    function LogFromAWorkerThread(const ALogger: ILogWriter): TThreadID;
    function WaitForItems(const AAppender: TLoggerProMemoryRingBufferAppender; ACount: Integer): TArray<TLogItem>;
    procedure FreeItems(var AItems: TArray<TLogItem>);
  public
    [Test]
    procedure NoCapture_TheItemsAreAsBefore;
    [Test]
    procedure Capture_RunsOnTheThreadThatLogs;
    [Test]
    procedure Capture_IsCalledForErrorAndFatalOnly;
    [Test]
    procedure Capture_ForAPlainError_ReceivesNil;
    [Test]
    procedure Capture_ForLogException_ReceivesTheException;
    [Test]
    procedure Capture_ForAnErrorInsideAnExceptBlock_ReceivesTheException;
    [Test]
    procedure Capture_DoesNotChangeTheMessage;
    [Test]
    procedure Capture_Clone_KeepsCaptured;
    [Test]
    procedure Capture_ThatRaises_DoesNotBreakLogging;
  end;

implementation

{ TTestLoggerCapture }

function TTestLoggerCapture.NewLogger(const ACapture: TLogItemCapture;
  out AAppender: TLoggerProMemoryRingBufferAppender): ILogWriter;
var
  lBuilder: ILoggerProBuilder;
begin
  AAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lBuilder := LoggerProBuilder.WithMinimumLevel(TLogType.Debug).WriteToAppender(AAppender);
  if Assigned(ACapture) then
    lBuilder := lBuilder.WithCapture(ACapture);
  Result := lBuilder.Build;
end;

function TTestLoggerCapture.WaitForItems(const AAppender: TLoggerProMemoryRingBufferAppender;
  ACount: Integer): TArray<TLogItem>;
var
  lItems: TList<TLogItem>;
  I, lTry: Integer;
begin
  // the appender runs on the thread of the logger: wait for it, at most two seconds
  for lTry := 1 to 200 do
  begin
    lItems := AAppender.GetLogItems;
    try
      if lItems.Count >= ACount then
      begin
        SetLength(Result, lItems.Count);
        for I := 0 to lItems.Count - 1 do
          Result[I] := lItems[I];
        Exit;
      end;
      for I := 0 to lItems.Count - 1 do
        lItems[I].Free;
    finally
      lItems.Free;
    end;
    Sleep(10);
  end;
  SetLength(Result, 0);
end;

function TTestLoggerCapture.LogFromAWorkerThread(const ALogger: ILogWriter): TThreadID;
var
  lWorker: TThread;
begin
  lWorker := TThread.CreateAnonymousThread(
    procedure
    begin
      ALogger.Error('from a worker', 'tag');
    end);
  lWorker.FreeOnTerminate := False;
  lWorker.Start;
  lWorker.WaitFor;
  Result := lWorker.ThreadID;
  lWorker.Free;
end;

procedure TTestLoggerCapture.FreeItems(var AItems: TArray<TLogItem>);
var
  lItem: TLogItem;
begin
  for lItem in AItems do
    lItem.Free;
  SetLength(AItems, 0);
end;

procedure TTestLoggerCapture.NoCapture_TheItemsAreAsBefore;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLogger: ILogWriter;
  lItems: TArray<TLogItem>;
  lE: Exception;
begin
  lLogger := NewLogger(nil, lAppender);
  lLogger.Error('plain', 'tag');
  lE := Exception.Create('x');
  try
    lLogger.LogException(lE, 'with exception', 'tag');
  finally
    lE.Free;
  end;
  lItems := WaitForItems(lAppender, 2);
  try
    Assert.AreEqual(2, Integer(Length(lItems)));
    Assert.AreEqual('', lItems[0].Captured);
    Assert.AreEqual('', lItems[1].Captured);
    Assert.AreEqual('plain', lItems[0].LogMessage);
  finally
    FreeItems(lItems);
  end;
end;

procedure TTestLoggerCapture.Capture_RunsOnTheThreadThatLogs;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLogger: ILogWriter;
  lItems: TArray<TLogItem>;
  lWorkerThread: TThreadID;
begin
  lLogger := NewLogger(
    function(const AException: Exception): string
    begin
      Result := 'thread=' + IntToStr(TThread.CurrentThread.ThreadID);
    end, lAppender);
  lLogger.Error('from the main thread', 'tag');
  lWorkerThread := LogFromAWorkerThread(lLogger);
  lItems := WaitForItems(lAppender, 2);
  try
    Assert.AreEqual(2, Integer(Length(lItems)));
    // the appender and the logger run on another thread: the capture ran where the item was born
    Assert.AreEqual('thread=' + IntToStr(lItems[0].ThreadID), lItems[0].Captured);
    Assert.AreEqual('thread=' + IntToStr(lWorkerThread), lItems[1].Captured);
    Assert.AreNotEqual(lItems[0].Captured, lItems[1].Captured);
  finally
    FreeItems(lItems);
  end;
end;

procedure TTestLoggerCapture.Capture_IsCalledForErrorAndFatalOnly;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLogger: ILogWriter;
  lItems: TArray<TLogItem>;
begin
  lLogger := NewLogger(
    function(const AException: Exception): string
    begin
      Result := 'captured';
    end, lAppender);
  lLogger.Debug('d', 'tag');
  lLogger.Info('i', 'tag');
  lLogger.Warn('w', 'tag');
  lLogger.Error('e', 'tag');
  lLogger.Fatal('f', 'tag');
  lItems := WaitForItems(lAppender, 5);
  try
    Assert.AreEqual(5, Integer(Length(lItems)));
    Assert.AreEqual('', lItems[0].Captured, 'debug');
    Assert.AreEqual('', lItems[1].Captured, 'info');
    Assert.AreEqual('', lItems[2].Captured, 'warning');
    Assert.AreEqual('captured', lItems[3].Captured, 'error');
    Assert.AreEqual('captured', lItems[4].Captured, 'fatal');
  finally
    FreeItems(lItems);
  end;
end;

procedure TTestLoggerCapture.Capture_ForAPlainError_ReceivesNil;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLogger: ILogWriter;
  lItems: TArray<TLogItem>;
begin
  lLogger := NewLogger(
    function(const AException: Exception): string
    begin
      if AException = nil then
        Result := 'nil'
      else
        Result := 'exception';
    end, lAppender);
  lLogger.Error('plain', 'tag');
  lItems := WaitForItems(lAppender, 1);
  try
    Assert.AreEqual('nil', lItems[0].Captured);
  finally
    FreeItems(lItems);
  end;
end;

procedure TTestLoggerCapture.Capture_ForLogException_ReceivesTheException;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLogger: ILogWriter;
  lItems: TArray<TLogItem>;
  lE, lReceived: Exception;
begin
  lReceived := nil;
  lLogger := NewLogger(
    function(const AException: Exception): string
    begin
      lReceived := AException;
      Result := 'x';
    end, lAppender);
  lE := Exception.Create('the exception');
  try
    lLogger.LogException(lE, 'it failed', 'tag');
    lItems := WaitForItems(lAppender, 1);
    try
      Assert.AreSame(lE, lReceived);
      Assert.AreEqual('x', lItems[0].Captured);
    finally
      FreeItems(lItems);
    end;
  finally
    lE.Free;
  end;
end;

procedure TTestLoggerCapture.Capture_ForAnErrorInsideAnExceptBlock_ReceivesTheException;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLogger: ILogWriter;
  lItems: TArray<TLogItem>;
  lReceived: Exception;
  lSame: Boolean;
begin
  lReceived := nil;
  lLogger := NewLogger(
    function(const AException: Exception): string
    begin
      lReceived := AException;
      Result := 'stack';
    end, lAppender);
  try
    raise Exception.Create('the exception');
  except
    on E: Exception do
    begin
      // a plain Error, the caller's own text: the capture gets the exception being handled
      lLogger.Error('my own text', 'tag');
      lSame := lReceived = E;
    end;
  end;
  lItems := WaitForItems(lAppender, 1);
  try
    Assert.IsTrue(lSame, 'the capture did not receive the exception being handled');
    Assert.AreEqual('my own text', lItems[0].LogMessage);
    Assert.AreEqual('stack', lItems[0].Captured);
  finally
    FreeItems(lItems);
  end;
end;

procedure TTestLoggerCapture.Capture_DoesNotChangeTheMessage;
var
  lAppenderA, lAppenderB: TLoggerProMemoryRingBufferAppender;
  lLoggerA, lLoggerB: ILogWriter;
  lItemsA, lItemsB: TArray<TLogItem>;
  lE: Exception;
begin
  lLoggerA := NewLogger(nil, lAppenderA);
  lLoggerB := NewLogger(
    function(const AException: Exception): string
    begin
      Result := 'a stack';
    end, lAppenderB);
  lE := Exception.Create('same text');
  try
    lLoggerA.LogException(lE, 'it failed', 'tag');
    lLoggerB.LogException(lE, 'it failed', 'tag');
    lItemsA := WaitForItems(lAppenderA, 1);
    lItemsB := WaitForItems(lAppenderB, 1);
    try
      Assert.AreEqual(lItemsA[0].LogMessage, lItemsB[0].LogMessage);
      Assert.AreEqual(lItemsA[0].LogTag, lItemsB[0].LogTag);
      Assert.IsTrue(lItemsA[0].LogType = lItemsB[0].LogType);
    finally
      FreeItems(lItemsA);
      FreeItems(lItemsB);
    end;
  finally
    lE.Free;
  end;
end;

procedure TTestLoggerCapture.Capture_Clone_KeepsCaptured;
var
  lItem, lClone: TLogItem;
begin
  lItem := TLogItem.Create(TLogType.Error, 'm', 't');
  try
    lItem.Captured := 'the stack';
    lClone := lItem.Clone;
    try
      Assert.AreEqual('the stack', lClone.Captured);
    finally
      lClone.Free;
    end;
  finally
    lItem.Free;
  end;
end;

procedure TTestLoggerCapture.Capture_ThatRaises_DoesNotBreakLogging;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLogger: ILogWriter;
  lItems: TArray<TLogItem>;
begin
  lLogger := NewLogger(
    function(const AException: Exception): string
    begin
      raise Exception.Create('the capture failed');
    end, lAppender);
  lLogger.Error('still logged', 'tag');
  lLogger.Info('and the next one', 'tag');
  lItems := WaitForItems(lAppender, 2);
  try
    Assert.AreEqual(2, Integer(Length(lItems)), 'logging goes on');
    Assert.AreEqual('still logged', lItems[0].LogMessage);
    Assert.AreEqual('', lItems[0].Captured);
  finally
    FreeItems(lItems);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestLoggerCapture);

end.
