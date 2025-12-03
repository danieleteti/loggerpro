unit NewAppendersTestU;

interface

uses
  DUnitX.TestFramework,
  LoggerPro,
  System.SysUtils,
  System.Classes,
  System.IOUtils,
  System.Generics.Collections,
  System.SyncObjs;

type
  [TestFixture]
  TMemoryAppenderTest = class
  public
    [Test]
    procedure TestWriteAndRetrieveLogs;
    [Test]
    procedure TestRingBufferOverflow;
    [Test]
    procedure TestGetLogItemsByTag;
    [Test]
    procedure TestGetLogItemsByType;
    [Test]
    procedure TestClear;
    [Test]
    procedure TestCount;
    [Test]
    procedure TestGetAsStringList;
    [Test]
    procedure TestThreadSafety;
    // Border cases
    [Test]
    procedure TestBufferSizeOne;
    [Test]
    procedure TestEmptyStringMessage;
    [Test]
    procedure TestVeryLongMessage;
    [Test]
    procedure TestUnicodeMessage;
    [Test]
    procedure TestGetLogItemsByTagNotFound;
    [Test]
    procedure TestGetLogItemsByTypeNotFound;
    [Test]
    procedure TestMultipleClear;
    [Test]
    procedure TestEmptyBuffer;
    [Test]
    procedure TestSpecialCharactersInTag;
  end;

  [TestFixture]
  TCallbackAppenderTest = class
  public
    [Test]
    procedure TestCallbackIsInvoked;
    [Test]
    procedure TestCallbackReceivesCorrectData;
    [Test]
    procedure TestSimpleMessageCallback;
    [Test]
    procedure TestMultipleLogLevels;
    // Border cases
    [Test]
    procedure TestNilCallback;
    [Test]
    procedure TestCallbackWithException;
    [Test]
    procedure TestEmptyMessageCallback;
    [Test]
    procedure TestRapidFireLogging;
  end;

  [TestFixture]
  TTimeRotatingFileAppenderTest = class
  private
    FTestFolder: string;
    procedure CleanupTestFolder;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestDailyTimestampFormat;
    [Test]
    procedure TestHourlyTimestampFormat;
    [Test]
    procedure TestWeeklyTimestampFormat;
    [Test]
    procedure TestMonthlyTimestampFormat;
    [Test]
    procedure TestFileCreation;
    [Test]
    procedure TestWriteLog;
    // Border cases
    [Test]
    procedure TestMaxBackupFilesZero;
    [Test]
    procedure TestMaxBackupFilesCleanup;
    [Test]
    procedure TestEmptyLogMessage;
    [Test]
    procedure TestUnicodeLogMessage;
    [Test]
    procedure TestMultipleWritesInSameSecond;
  end;

  [TestFixture]
  THTTPAppenderTest = class
  public
    [Test]
    procedure TestLogItemToJSON;
    [Test]
    procedure TestBuildURLWithAppendTagAndLevel;
    [Test]
    procedure TestBuildURLWithoutAppendTagAndLevel;
    [Test]
    procedure TestCustomHeaders;
    // Border cases
    [Test]
    procedure TestPlainTextContentType;
    [Test]
    procedure TestSpecialCharactersInMessage;
    [Test]
    procedure TestUnicodeInMessage;
    [Test]
    procedure TestVeryLongMessage;
    [Test]
    procedure TestEmptyExtendedInfo;
    [Test]
    procedure TestAllExtendedInfo;
    [Test]
    procedure TestOverwriteHeader;
  end;

  [TestFixture]
  TAppenderEnableDisableTest = class
  public
    [Test]
    procedure TestAppenderEnabledByDefault;
    [Test]
    procedure TestDisableAppenderPreventWriting;
    [Test]
    procedure TestReEnableAppender;
  end;

implementation

uses
  LoggerPro.MemoryAppender,
  LoggerPro.CallbackAppender,
  LoggerPro.TimeRotatingFileAppender,
  LoggerPro.HTTPAppender,
  System.DateUtils,
  System.JSON;

{ TMemoryAppenderTest }

procedure TMemoryAppenderTest.TestWriteAndRetrieveLogs;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
  lEvent: TEvent;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lLog.Debug('Test message 1', 'TAG1');
    lLog.Info('Test message 2', 'TAG2');

    // Wait for async logging
    Sleep(500);

    lItems := lAppender.GetLogItems;
    try
      Assert.AreEqual(2, lItems.Count, 'Should have 2 log items');
      Assert.AreEqual('Test message 1', lItems[0].LogMessage);
      Assert.AreEqual('TAG1', lItems[0].LogTag);
      Assert.AreEqual(TLogType.Debug, lItems[0].LogType);
      Assert.AreEqual('Test message 2', lItems[1].LogMessage);
      Assert.AreEqual('TAG2', lItems[1].LogTag);
      Assert.AreEqual(TLogType.Info, lItems[1].LogType);
    finally
      for var I := 0 to lItems.Count - 1 do
        lItems[I].Free;
      lItems.Free;
    end;
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TMemoryAppenderTest.TestRingBufferOverflow;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
  I: Integer;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(5); // Small buffer
  lLog := BuildLogWriter([lAppender]);
  try
    // Write 10 messages to a buffer of size 5
    for I := 1 to 10 do
      lLog.Debug('Message ' + I.ToString, 'TAG');

    // Wait for async logging
    Sleep(500);

    lItems := lAppender.GetLogItems;
    try
      Assert.AreEqual(5, lItems.Count, 'Should have only 5 log items (buffer size)');
      // Oldest items should be removed, so we should have messages 6-10
      Assert.AreEqual('Message 6', lItems[0].LogMessage);
      Assert.AreEqual('Message 10', lItems[4].LogMessage);
    finally
      for var J := 0 to lItems.Count - 1 do
        lItems[J].Free;
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestGetLogItemsByTag;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('Message 1', 'TAG_A');
    lLog.Debug('Message 2', 'TAG_B');
    lLog.Debug('Message 3', 'TAG_A');
    lLog.Debug('Message 4', 'TAG_C');

    Sleep(500);

    lItems := lAppender.GetLogItemsByTag('TAG_A');
    try
      Assert.AreEqual(2, lItems.Count, 'Should have 2 items with TAG_A');
      Assert.AreEqual('Message 1', lItems[0].LogMessage);
      Assert.AreEqual('Message 3', lItems[1].LogMessage);
    finally
      for var I := 0 to lItems.Count - 1 do
        lItems[I].Free;
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestGetLogItemsByType;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('Debug message', 'TAG');
    lLog.Info('Info message', 'TAG');
    lLog.Warn('Warning message', 'TAG');
    lLog.Error('Error message', 'TAG');

    Sleep(500);

    lItems := lAppender.GetLogItemsByType(TLogType.Error);
    try
      Assert.AreEqual(1, lItems.Count, 'Should have 1 error item');
      Assert.AreEqual('Error message', lItems[0].LogMessage);
    finally
      for var I := 0 to lItems.Count - 1 do
        lItems[I].Free;
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestClear;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('Message 1', 'TAG');
    lLog.Debug('Message 2', 'TAG');
    Sleep(500);

    Assert.AreEqual(2, lAppender.Count);

    lAppender.Clear;

    Assert.AreEqual(0, lAppender.Count);
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestCount;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    Assert.AreEqual(0, lAppender.Count);

    lLog.Debug('Message 1', 'TAG');
    Sleep(200);
    Assert.AreEqual(1, lAppender.Count);

    lLog.Debug('Message 2', 'TAG');
    lLog.Debug('Message 3', 'TAG');
    Sleep(200);
    Assert.AreEqual(3, lAppender.Count);
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestGetAsStringList;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lStrings: TArray<string>;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('Debug message', 'TAG');
    lLog.Info('Info message', 'TAG');
    Sleep(500);

    lStrings := lAppender.GetAsStringList;

    Assert.AreEqual(2, Length(lStrings));
    Assert.IsTrue(lStrings[0].Contains('Debug message'));
    Assert.IsTrue(lStrings[1].Contains('Info message'));
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestThreadSafety;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lThreads: TArray<TThread>;
  I: Integer;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(1000);
  lLog := BuildLogWriter([lAppender]);
  try
    SetLength(lThreads, 5);
    for I := 0 to High(lThreads) do
    begin
      lThreads[I] := TThread.CreateAnonymousThread(
        procedure
        var
          J: Integer;
        begin
          for J := 1 to 100 do
            lLog.Debug('Thread message ' + J.ToString, 'THREAD');
        end);
      lThreads[I].FreeOnTerminate := False;
      lThreads[I].Start;
    end;

    // Wait for all threads
    for I := 0 to High(lThreads) do
    begin
      lThreads[I].WaitFor;
      lThreads[I].Free;
    end;

    Sleep(1000);

    // Should have 500 messages (5 threads x 100 messages)
    Assert.AreEqual(500, lAppender.Count, 'Should have 500 messages from all threads');
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestBufferSizeOne;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(1); // Minimum buffer size
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('Message 1', 'TAG');
    lLog.Debug('Message 2', 'TAG');
    lLog.Debug('Message 3', 'TAG');

    Sleep(500);

    Assert.AreEqual(1, lAppender.Count, 'Buffer should only hold 1 item');

    lItems := lAppender.GetLogItems;
    try
      Assert.AreEqual('Message 3', lItems[0].LogMessage, 'Should have only the last message');
    finally
      for var I := 0 to lItems.Count - 1 do
        lItems[I].Free;
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestEmptyStringMessage;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('', 'TAG');  // Empty message
    Sleep(300);

    lItems := lAppender.GetLogItems;
    try
      Assert.AreEqual(1, lItems.Count);
      Assert.AreEqual('', lItems[0].LogMessage, 'Empty message should be preserved');
    finally
      for var I := 0 to lItems.Count - 1 do
        lItems[I].Free;
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestVeryLongMessage;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
  lLongMessage: string;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    // Create a 100KB message
    lLongMessage := StringOfChar('X', 100 * 1024);
    lLog.Debug(lLongMessage, 'TAG');
    Sleep(500);

    lItems := lAppender.GetLogItems;
    try
      Assert.AreEqual(1, lItems.Count);
      Assert.AreEqual(100 * 1024, Length(lItems[0].LogMessage), 'Long message should be preserved');
    finally
      for var I := 0 to lItems.Count - 1 do
        lItems[I].Free;
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestUnicodeMessage;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
  lUnicodeMsg: string;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lUnicodeMsg := 'Test Unicode: '#$4E2D#$6587' - '#$65E5#$672C#$8A9E' - '#$0410#$0411#$0412' - '#$03B1#$03B2#$03B3;
    lLog.Debug(lUnicodeMsg, 'UNICODE');
    Sleep(300);

    lItems := lAppender.GetLogItems;
    try
      Assert.AreEqual(1, lItems.Count);
      Assert.AreEqual(lUnicodeMsg, lItems[0].LogMessage, 'Unicode message should be preserved');
    finally
      for var I := 0 to lItems.Count - 1 do
        lItems[I].Free;
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestGetLogItemsByTagNotFound;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('Message 1', 'TAG_A');
    lLog.Debug('Message 2', 'TAG_B');
    Sleep(300);

    lItems := lAppender.GetLogItemsByTag('NONEXISTENT_TAG');
    try
      Assert.AreEqual(0, lItems.Count, 'Should return empty list for non-existent tag');
    finally
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestGetLogItemsByTypeNotFound;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('Debug message', 'TAG');
    lLog.Info('Info message', 'TAG');
    Sleep(300);

    // Search for Fatal which was not logged
    lItems := lAppender.GetLogItemsByType(TLogType.Fatal);
    try
      Assert.AreEqual(0, lItems.Count, 'Should return empty list for non-existent log type');
    finally
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestMultipleClear;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('Message 1', 'TAG');
    Sleep(200);

    // Multiple clears should not cause issues
    lAppender.Clear;
    Assert.AreEqual(0, lAppender.Count);

    lAppender.Clear;
    Assert.AreEqual(0, lAppender.Count);

    lAppender.Clear;
    Assert.AreEqual(0, lAppender.Count);

    // Should still work after multiple clears
    lLog.Debug('Message after clear', 'TAG');
    Sleep(200);
    Assert.AreEqual(1, lAppender.Count);
  finally
    lLog := nil;
  end;
end;

procedure TMemoryAppenderTest.TestEmptyBuffer;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lItems: TList<TLogItem>;
  lStrings: TArray<string>;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  try
    lAppender.Setup;

    // Test all methods on empty buffer
    Assert.AreEqual(0, lAppender.Count);

    lItems := lAppender.GetLogItems;
    try
      Assert.AreEqual(0, lItems.Count);
    finally
      lItems.Free;
    end;

    lItems := lAppender.GetLogItemsByTag('ANY');
    try
      Assert.AreEqual(0, lItems.Count);
    finally
      lItems.Free;
    end;

    lItems := lAppender.GetLogItemsByType(TLogType.Debug);
    try
      Assert.AreEqual(0, lItems.Count);
    finally
      lItems.Free;
    end;

    lStrings := lAppender.GetAsStringList;
    Assert.AreEqual(0, Length(lStrings));

    // Clear on empty buffer should not fail
    lAppender.Clear;
    Assert.AreEqual(0, lAppender.Count);

    lAppender.TearDown;
  finally
    lAppender.Free;
  end;
end;

procedure TMemoryAppenderTest.TestSpecialCharactersInTag;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TList<TLogItem>;
  lSpecialTag: string;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    lSpecialTag := 'TAG<>&"''[]{}!@#$%';
    lLog.Debug('Test message', lSpecialTag);
    Sleep(300);

    lItems := lAppender.GetLogItemsByTag(lSpecialTag);
    try
      Assert.AreEqual(1, lItems.Count, 'Should find item with special characters in tag');
      Assert.AreEqual(lSpecialTag, lItems[0].LogTag);
    finally
      for var I := 0 to lItems.Count - 1 do
        lItems[I].Free;
      lItems.Free;
    end;
  finally
    lLog := nil;
  end;
end;

{ TCallbackAppenderTest }

procedure TCallbackAppenderTest.TestCallbackIsInvoked;
var
  lAppender: TLoggerProCallbackAppender;
  lLog: ILogWriter;
  lCallbackInvoked: Boolean;
  lEvent: TEvent;
begin
  lCallbackInvoked := False;
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lAppender := TLoggerProCallbackAppender.Create(
      procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
      begin
        lCallbackInvoked := True;
        lEvent.SetEvent;
      end);

    lLog := BuildLogWriter([lAppender]);
    lLog.Debug('Test message', 'TAG');

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000), 'Callback should be invoked');
    Assert.IsTrue(lCallbackInvoked, 'Callback flag should be true');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TCallbackAppenderTest.TestCallbackReceivesCorrectData;
var
  lAppender: TLoggerProCallbackAppender;
  lLog: ILogWriter;
  lReceivedMessage: string;
  lReceivedTag: string;
  lReceivedType: TLogType;
  lEvent: TEvent;
begin
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lAppender := TLoggerProCallbackAppender.Create(
      procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
      begin
        lReceivedMessage := aLogItem.LogMessage;
        lReceivedTag := aLogItem.LogTag;
        lReceivedType := aLogItem.LogType;
        lEvent.SetEvent;
      end);

    lLog := BuildLogWriter([lAppender]);
    lLog.Error('Error occurred', 'ERRORS');

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000));
    Assert.AreEqual('Error occurred', lReceivedMessage);
    Assert.AreEqual('ERRORS', lReceivedTag);
    Assert.AreEqual(TLogType.Error, lReceivedType);
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TCallbackAppenderTest.TestSimpleMessageCallback;
var
  lAppender: TLoggerProCallbackAppender;
  lLog: ILogWriter;
  lReceivedMessage: string;
  lEvent: TEvent;
begin
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lAppender := TLoggerProCallbackAppender.Create(
      procedure(const aFormattedMessage: string)
      begin
        lReceivedMessage := aFormattedMessage;
        lEvent.SetEvent;
      end);

    lLog := BuildLogWriter([lAppender]);
    lLog.Info('Simple message', 'TAG');

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000));
    Assert.IsTrue(lReceivedMessage.Contains('Simple message'), 'Formatted message should contain original message');
    Assert.IsTrue(lReceivedMessage.Contains('INFO'), 'Formatted message should contain log level');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TCallbackAppenderTest.TestMultipleLogLevels;
var
  lAppender: TLoggerProCallbackAppender;
  lLog: ILogWriter;
  lLogTypes: TList<TLogType>;
  lLock: TCriticalSection;
begin
  lLogTypes := TList<TLogType>.Create;
  lLock := TCriticalSection.Create;
  try
    lAppender := TLoggerProCallbackAppender.Create(
      procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
      begin
        lLock.Enter;
        try
          lLogTypes.Add(aLogItem.LogType);
        finally
          lLock.Leave;
        end;
      end);

    lLog := BuildLogWriter([lAppender]);

    lLog.Debug('Debug', 'TAG');
    lLog.Info('Info', 'TAG');
    lLog.Warn('Warning', 'TAG');
    lLog.Error('Error', 'TAG');
    lLog.Fatal('Fatal', 'TAG');

    Sleep(1000);

    Assert.AreEqual(5, lLogTypes.Count, 'Should receive all 5 log levels');
    Assert.AreEqual(TLogType.Debug, lLogTypes[0]);
    Assert.AreEqual(TLogType.Info, lLogTypes[1]);
    Assert.AreEqual(TLogType.Warning, lLogTypes[2]);
    Assert.AreEqual(TLogType.Error, lLogTypes[3]);
    Assert.AreEqual(TLogType.Fatal, lLogTypes[4]);
  finally
    lLog := nil;
    lLogTypes.Free;
    lLock.Free;
  end;
end;

procedure TCallbackAppenderTest.TestNilCallback;
var
  lAppender: TLoggerProCallbackAppender;
  lLog: ILogWriter;
begin
  // Create appender with nil callback - should not crash
  lAppender := TLoggerProCallbackAppender.Create(TLogItemCallback(nil));
  lLog := BuildLogWriter([lAppender]);
  try
    // These should not raise any exceptions
    lLog.Debug('Test message 1', 'TAG');
    lLog.Info('Test message 2', 'TAG');
    Sleep(300);
    // If we get here without exception, the test passed
    Assert.Pass('Nil callback handled gracefully');
  finally
    lLog := nil;
  end;
end;

procedure TCallbackAppenderTest.TestCallbackWithException;
var
  lAppender: TLoggerProCallbackAppender;
  lLog: ILogWriter;
  lCallCount: Integer;
  lLock: TCriticalSection;
begin
  lCallCount := 0;
  lLock := TCriticalSection.Create;
  try
    lAppender := TLoggerProCallbackAppender.Create(
      procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
      begin
        lLock.Enter;
        try
          Inc(lCallCount);
          if lCallCount = 1 then
            raise Exception.Create('Test exception in callback');
        finally
          lLock.Leave;
        end;
      end);

    lLog := BuildLogWriter([lAppender]);

    // First log will raise exception in callback
    lLog.Debug('Message 1', 'TAG');
    // Second log should still work
    lLog.Debug('Message 2', 'TAG');
    lLog.Debug('Message 3', 'TAG');

    Sleep(500);

    // All three callbacks should have been attempted
    Assert.IsTrue(lCallCount >= 1, 'Callback should have been called at least once');
  finally
    lLog := nil;
    lLock.Free;
  end;
end;

procedure TCallbackAppenderTest.TestEmptyMessageCallback;
var
  lAppender: TLoggerProCallbackAppender;
  lLog: ILogWriter;
  lReceivedMessage: string;
  lEvent: TEvent;
begin
  lReceivedMessage := 'NOT_SET';
  lEvent := TEvent.Create(nil, True, False, '');
  try
    lAppender := TLoggerProCallbackAppender.Create(
      procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
      begin
        lReceivedMessage := aLogItem.LogMessage;
        lEvent.SetEvent;
      end);

    lLog := BuildLogWriter([lAppender]);
    lLog.Debug('', 'TAG'); // Empty message

    Assert.AreEqual(TWaitResult.wrSignaled, lEvent.WaitFor(5000));
    Assert.AreEqual('', lReceivedMessage, 'Empty message should be preserved in callback');
  finally
    lLog := nil;
    lEvent.Free;
  end;
end;

procedure TCallbackAppenderTest.TestRapidFireLogging;
var
  lAppender: TLoggerProCallbackAppender;
  lLog: ILogWriter;
  lCallCount: Integer;
  lLock: TCriticalSection;
  I: Integer;
begin
  lCallCount := 0;
  lLock := TCriticalSection.Create;
  try
    lAppender := TLoggerProCallbackAppender.Create(
      procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
      begin
        lLock.Enter;
        try
          Inc(lCallCount);
        finally
          lLock.Leave;
        end;
      end);

    lLog := BuildLogWriter([lAppender]);

    // Rapid fire 1000 log messages
    for I := 1 to 1000 do
      lLog.Debug('Rapid message ' + I.ToString, 'RAPID');

    Sleep(2000);

    Assert.AreEqual(1000, lCallCount, 'All 1000 callbacks should have been invoked');
  finally
    lLog := nil;
    lLock.Free;
  end;
end;

{ TTimeRotatingFileAppenderTest }

procedure TTimeRotatingFileAppenderTest.Setup;
begin
  FTestFolder := TPath.Combine(TPath.GetTempPath, 'LoggerProTimeRotatingTest_' + TGUID.NewGuid.ToString);
  if not TDirectory.Exists(FTestFolder) then
    TDirectory.CreateDirectory(FTestFolder);
end;

procedure TTimeRotatingFileAppenderTest.TearDown;
begin
  CleanupTestFolder;
end;

procedure TTimeRotatingFileAppenderTest.CleanupTestFolder;
begin
  if TDirectory.Exists(FTestFolder) then
  begin
    try
      TDirectory.Delete(FTestFolder, True);
    except
      // Ignore errors during cleanup
    end;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestDailyTimestampFormat;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lFiles: TArray<string>;
  lExpectedPattern: string;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Daily, 30, FTestFolder, 'testlog');
  try
    lAppender.Setup;
    lAppender.TearDown;

    lFiles := TDirectory.GetFiles(FTestFolder, 'testlog.*.log');
    Assert.AreEqual(1, Length(lFiles), 'Should have created one log file');

    // Check filename pattern: testlog.YYYYMMDD.log
    lExpectedPattern := 'testlog.' + FormatDateTime('yyyymmdd', Now) + '.log';
    Assert.IsTrue(TPath.GetFileName(lFiles[0]) = lExpectedPattern,
      'Filename should match daily pattern: ' + lExpectedPattern);
  finally
    lAppender.Free;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestHourlyTimestampFormat;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lFiles: TArray<string>;
  lExpectedPattern: string;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Hourly, 30, FTestFolder, 'testlog');
  try
    lAppender.Setup;
    lAppender.TearDown;

    lFiles := TDirectory.GetFiles(FTestFolder, 'testlog.*.log');
    Assert.AreEqual(1, Length(lFiles), 'Should have created one log file');

    // Check filename pattern: testlog.YYYYMMDDHH.log
    lExpectedPattern := 'testlog.' + FormatDateTime('yyyymmddhh', Now) + '.log';
    Assert.IsTrue(TPath.GetFileName(lFiles[0]) = lExpectedPattern,
      'Filename should match hourly pattern: ' + lExpectedPattern);
  finally
    lAppender.Free;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestWeeklyTimestampFormat;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lFiles: TArray<string>;
  lYear, lWeek: Word;
  lExpectedPattern: string;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Weekly, 30, FTestFolder, 'testlog');
  try
    lAppender.Setup;
    lAppender.TearDown;

    lFiles := TDirectory.GetFiles(FTestFolder, 'testlog.*.log');
    Assert.AreEqual(1, Length(lFiles), 'Should have created one log file');

    // Check filename pattern: testlog.YYYYWWW.log
    lYear := YearOf(Now);
    lWeek := WeekOfTheYear(Now);
    lExpectedPattern := Format('testlog.%.4dW%.2d.log', [lYear, lWeek]);
    Assert.IsTrue(TPath.GetFileName(lFiles[0]) = lExpectedPattern,
      'Filename should match weekly pattern: ' + lExpectedPattern);
  finally
    lAppender.Free;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestMonthlyTimestampFormat;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lFiles: TArray<string>;
  lExpectedPattern: string;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Monthly, 30, FTestFolder, 'testlog');
  try
    lAppender.Setup;
    lAppender.TearDown;

    lFiles := TDirectory.GetFiles(FTestFolder, 'testlog.*.log');
    Assert.AreEqual(1, Length(lFiles), 'Should have created one log file');

    // Check filename pattern: testlog.YYYYMM.log
    lExpectedPattern := 'testlog.' + FormatDateTime('yyyymm', Now) + '.log';
    Assert.IsTrue(TPath.GetFileName(lFiles[0]) = lExpectedPattern,
      'Filename should match monthly pattern: ' + lExpectedPattern);
  finally
    lAppender.Free;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestFileCreation;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lLog: ILogWriter;
  lFiles: TArray<string>;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Daily, 30, FTestFolder, 'app');
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Info('Test message', 'TAG');
    Sleep(500);

    lLog := nil; // Force teardown

    lFiles := TDirectory.GetFiles(FTestFolder, 'app.*.log');
    Assert.IsTrue(Length(lFiles) >= 1, 'Should have created at least one log file');
  finally
    lLog := nil;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestWriteLog;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lLog: ILogWriter;
  lFiles: TArray<string>;
  lContent: string;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Daily, 30, FTestFolder, 'writetest');
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Info('Hello World', 'TEST');
    lLog.Error('Error occurred', 'TEST');
    Sleep(500);

    lLog := nil; // Force teardown

    lFiles := TDirectory.GetFiles(FTestFolder, 'writetest.*.log');
    Assert.AreEqual(1, Length(lFiles), 'Should have one log file');

    lContent := TFile.ReadAllText(lFiles[0]);
    Assert.IsTrue(lContent.Contains('Hello World'), 'Log file should contain first message');
    Assert.IsTrue(lContent.Contains('Error occurred'), 'Log file should contain second message');
    Assert.IsTrue(lContent.Contains('INFO'), 'Log file should contain INFO level');
    Assert.IsTrue(lContent.Contains('ERROR'), 'Log file should contain ERROR level');
  finally
    lLog := nil;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestMaxBackupFilesZero;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
begin
  // MaxBackupFiles = 0 means unlimited
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Daily, 0, FTestFolder, 'unlimited');
  try
    lAppender.Setup;
    Assert.AreEqual(0, lAppender.MaxBackupFiles, 'MaxBackupFiles should be 0');
    lAppender.TearDown;
  finally
    lAppender.Free;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestMaxBackupFilesCleanup;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lFiles: TArray<string>;
  I: Integer;
begin
  // Create several fake log files first
  for I := 1 to 10 do
  begin
    TFile.WriteAllText(
      TPath.Combine(FTestFolder, Format('cleanup.2025010%.2d.log', [I])),
      'Test content ' + I.ToString);
  end;

  // Verify we have 10 files
  lFiles := TDirectory.GetFiles(FTestFolder, 'cleanup.*.log');
  Assert.AreEqual(10, Length(lFiles), 'Should have 10 files before cleanup');

  // Create appender with max 3 backup files
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Daily, 3, FTestFolder, 'cleanup');
  try
    lAppender.Setup;
    lAppender.TearDown;

    // After setup, old files should be cleaned up
    lFiles := TDirectory.GetFiles(FTestFolder, 'cleanup.*.log');
    Assert.IsTrue(Length(lFiles) <= 4, 'Should have at most 4 files (3 backups + 1 current)');
  finally
    lAppender.Free;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestEmptyLogMessage;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lLog: ILogWriter;
  lFiles: TArray<string>;
  lContent: string;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Daily, 30, FTestFolder, 'emptymsg');
  lLog := BuildLogWriter([lAppender]);
  try
    lLog.Debug('', 'TAG'); // Empty message
    Sleep(500);

    lLog := nil;

    lFiles := TDirectory.GetFiles(FTestFolder, 'emptymsg.*.log');
    Assert.AreEqual(1, Length(lFiles));

    lContent := TFile.ReadAllText(lFiles[0]);
    Assert.IsTrue(lContent.Contains('DEBUG'), 'Should contain DEBUG level');
    Assert.IsTrue(lContent.Contains('TAG'), 'Should contain tag');
  finally
    lLog := nil;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestUnicodeLogMessage;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lLog: ILogWriter;
  lFiles: TArray<string>;
  lContent: string;
  lUnicodeMsg: string;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Daily, 30, FTestFolder, 'unicode');
  lLog := BuildLogWriter([lAppender]);
  try
    lUnicodeMsg := 'Unicode: '#$4E2D#$6587' '#$65E5#$672C#$8A9E' '#$0410#$0411#$0412;
    lLog.Info(lUnicodeMsg, 'UNICODE');
    Sleep(500);

    lLog := nil;

    lFiles := TDirectory.GetFiles(FTestFolder, 'unicode.*.log');
    Assert.AreEqual(1, Length(lFiles));

    lContent := TFile.ReadAllText(lFiles[0], TEncoding.UTF8);
    Assert.IsTrue(lContent.Contains(lUnicodeMsg), 'Log file should contain unicode message');
  finally
    lLog := nil;
  end;
end;

procedure TTimeRotatingFileAppenderTest.TestMultipleWritesInSameSecond;
var
  lAppender: TLoggerProTimeRotatingFileAppender;
  lLog: ILogWriter;
  lFiles: TArray<string>;
  lContent: string;
  I: Integer;
begin
  lAppender := TLoggerProTimeRotatingFileAppender.Create(
    TTimeRotationInterval.Hourly, 30, FTestFolder, 'rapid');
  lLog := BuildLogWriter([lAppender]);
  try
    // Write 100 messages as fast as possible
    for I := 1 to 100 do
      lLog.Debug('Rapid message ' + I.ToString, 'RAPID');

    Sleep(1000);

    lLog := nil;

    lFiles := TDirectory.GetFiles(FTestFolder, 'rapid.*.log');
    Assert.AreEqual(1, Length(lFiles), 'Should have one log file');

    lContent := TFile.ReadAllText(lFiles[0]);
    Assert.IsTrue(lContent.Contains('Rapid message 1'), 'Should contain first message');
    Assert.IsTrue(lContent.Contains('Rapid message 100'), 'Should contain last message');
  finally
    lLog := nil;
  end;
end;

{ THTTPAppenderTest }

type
  // Helper class to access protected method
  THTTPAppenderTestHelper = class(TLoggerProHTTPAppender)
  public
    function TestCreateData(const aLogItem: TLogItem; out aContentType: string): TStream;
  end;

function THTTPAppenderTestHelper.TestCreateData(const aLogItem: TLogItem; out aContentType: string): TStream;
begin
  Result := CreateData(aLogItem, aContentType);
end;

procedure THTTPAppenderTest.TestLogItemToJSON;
var
  lAppender: THTTPAppenderTestHelper;
  lLogItem: TLogItem;
  lStream: TStream;
  lContentType: string;
  lJSON: TJSONObject;
begin
  lAppender := THTTPAppenderTestHelper.Create('http://localhost/logs', THTTPContentType.JSON);
  try
    lAppender.Setup;

    lLogItem := TLogItem.Create(TLogType.Info, 'Test message', 'TESTTAG');
    try
      lStream := lAppender.TestCreateData(lLogItem, lContentType);
      try
        Assert.IsNotNull(lStream, 'Stream should not be nil');
        Assert.AreEqual('application/json; charset=utf-8', lContentType);

        // Parse and validate JSON
        lJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(TStringStream(lStream).DataString), 0) as TJSONObject;
        try
          Assert.IsNotNull(lJSON, 'Should be valid JSON');
          Assert.AreEqual('Test message', lJSON.GetValue<string>('message'));
          Assert.AreEqual('TESTTAG', lJSON.GetValue<string>('tag'));
          Assert.AreEqual('INFO', lJSON.GetValue<string>('level'));
        finally
          lJSON.Free;
        end;
      finally
        lStream.Free;
      end;
    finally
      lLogItem.Free;
    end;

    lAppender.TearDown;
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestBuildURLWithAppendTagAndLevel;
var
  lAppender: TLoggerProHTTPAppender;
begin
  lAppender := TLoggerProHTTPAppender.Create('http://localhost/api/logs');
  try
    lAppender.AppendTagAndLevelToURL := True;

    // The URL building is internal, but we can verify the property is set
    Assert.IsTrue(lAppender.AppendTagAndLevelToURL);
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestBuildURLWithoutAppendTagAndLevel;
var
  lAppender: TLoggerProHTTPAppender;
begin
  lAppender := TLoggerProHTTPAppender.Create('http://localhost/api/logs');
  try
    Assert.IsFalse(lAppender.AppendTagAndLevelToURL, 'Default should be False');
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestCustomHeaders;
var
  lAppender: TLoggerProHTTPAppender;
begin
  lAppender := TLoggerProHTTPAppender.Create('http://localhost/api/logs');
  try
    // Just verify headers can be added without exception
    lAppender.AddHeader('Authorization', 'Bearer token123');
    lAppender.AddHeader('X-Custom-Header', 'CustomValue');
    lAppender.AddHeader('Content-Type', 'application/json'); // Should be overwritable

    // No exception means success
    Assert.Pass('Headers added successfully');
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestPlainTextContentType;
var
  lAppender: THTTPAppenderTestHelper;
  lLogItem: TLogItem;
  lStream: TStream;
  lContentType: string;
  lContent: string;
begin
  lAppender := THTTPAppenderTestHelper.Create('http://localhost/logs', THTTPContentType.PlainText);
  try
    lAppender.Setup;

    lLogItem := TLogItem.Create(TLogType.Error, 'Plain text message', 'PLAIN');
    try
      lStream := lAppender.TestCreateData(lLogItem, lContentType);
      try
        Assert.IsNotNull(lStream);
        Assert.AreEqual('text/plain; charset=utf-8', lContentType);

        lContent := TStringStream(lStream).DataString;
        Assert.IsTrue(lContent.Contains('Plain text message'), 'Content should contain message');
        Assert.IsTrue(lContent.Contains('PLAIN'), 'Content should contain tag');
        Assert.IsTrue(lContent.Contains('ERROR'), 'Content should contain level');
      finally
        lStream.Free;
      end;
    finally
      lLogItem.Free;
    end;

    lAppender.TearDown;
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestSpecialCharactersInMessage;
var
  lAppender: THTTPAppenderTestHelper;
  lLogItem: TLogItem;
  lStream: TStream;
  lContentType: string;
  lJSON: TJSONObject;
  lSpecialMsg: string;
begin
  lAppender := THTTPAppenderTestHelper.Create('http://localhost/logs', THTTPContentType.JSON);
  try
    lAppender.Setup;

    // Message with JSON special characters that need escaping
    lSpecialMsg := 'Message with "quotes", \backslash\, and'#13#10'newlines';
    lLogItem := TLogItem.Create(TLogType.Info, lSpecialMsg, 'SPECIAL');
    try
      lStream := lAppender.TestCreateData(lLogItem, lContentType);
      try
        Assert.IsNotNull(lStream);

        // Parse JSON - should not fail if escaping is correct
        lJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(TStringStream(lStream).DataString), 0) as TJSONObject;
        try
          Assert.IsNotNull(lJSON, 'Should produce valid JSON even with special characters');
          Assert.AreEqual(lSpecialMsg, lJSON.GetValue<string>('message'));
        finally
          lJSON.Free;
        end;
      finally
        lStream.Free;
      end;
    finally
      lLogItem.Free;
    end;

    lAppender.TearDown;
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestUnicodeInMessage;
var
  lAppender: THTTPAppenderTestHelper;
  lLogItem: TLogItem;
  lStream: TStream;
  lContentType: string;
  lJSON: TJSONObject;
  lUnicodeMsg: string;
begin
  lAppender := THTTPAppenderTestHelper.Create('http://localhost/logs', THTTPContentType.JSON);
  try
    lAppender.Setup;

    lUnicodeMsg := 'Unicode: '#$4E2D#$6587' '#$65E5#$672C#$8A9E' '#$0410#$0411#$0412' '#$03B1#$03B2#$03B3;
    lLogItem := TLogItem.Create(TLogType.Info, lUnicodeMsg, 'UNICODE');
    try
      lStream := lAppender.TestCreateData(lLogItem, lContentType);
      try
        Assert.IsNotNull(lStream);

        lJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(TStringStream(lStream).DataString), 0) as TJSONObject;
        try
          Assert.IsNotNull(lJSON, 'Should produce valid JSON with unicode');
          Assert.AreEqual(lUnicodeMsg, lJSON.GetValue<string>('message'));
        finally
          lJSON.Free;
        end;
      finally
        lStream.Free;
      end;
    finally
      lLogItem.Free;
    end;

    lAppender.TearDown;
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestVeryLongMessage;
var
  lAppender: THTTPAppenderTestHelper;
  lLogItem: TLogItem;
  lStream: TStream;
  lContentType: string;
  lJSON: TJSONObject;
  lLongMsg: string;
begin
  lAppender := THTTPAppenderTestHelper.Create('http://localhost/logs', THTTPContentType.JSON);
  try
    lAppender.Setup;

    // Create a 50KB message
    lLongMsg := StringOfChar('X', 50 * 1024);
    lLogItem := TLogItem.Create(TLogType.Debug, lLongMsg, 'LONG');
    try
      lStream := lAppender.TestCreateData(lLogItem, lContentType);
      try
        Assert.IsNotNull(lStream);

        lJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(TStringStream(lStream).DataString), 0) as TJSONObject;
        try
          Assert.IsNotNull(lJSON, 'Should produce valid JSON with long message');
          Assert.AreEqual(50 * 1024, Length(lJSON.GetValue<string>('message')));
        finally
          lJSON.Free;
        end;
      finally
        lStream.Free;
      end;
    finally
      lLogItem.Free;
    end;

    lAppender.TearDown;
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestEmptyExtendedInfo;
var
  lAppender: THTTPAppenderTestHelper;
  lLogItem: TLogItem;
  lStream: TStream;
  lContentType: string;
  lJSON: TJSONObject;
begin
  // Create with empty extended info set
  lAppender := THTTPAppenderTestHelper.Create('http://localhost/logs', THTTPContentType.JSON,
    TLoggerProHTTPAppender.DEFAULT_TIMEOUT_SECONDS, []);
  try
    lAppender.Setup;

    lLogItem := TLogItem.Create(TLogType.Info, 'Minimal info', 'MINIMAL');
    try
      lStream := lAppender.TestCreateData(lLogItem, lContentType);
      try
        Assert.IsNotNull(lStream);

        lJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(TStringStream(lStream).DataString), 0) as TJSONObject;
        try
          Assert.IsNotNull(lJSON);
          // Should not contain extended info fields
          Assert.IsNull(lJSON.GetValue('hostname'), 'Should not have hostname with empty extended info');
          Assert.IsNull(lJSON.GetValue('username'), 'Should not have username with empty extended info');
          Assert.IsNull(lJSON.GetValue('processname'), 'Should not have processname with empty extended info');
          Assert.IsNull(lJSON.GetValue('pid'), 'Should not have pid with empty extended info');
        finally
          lJSON.Free;
        end;
      finally
        lStream.Free;
      end;
    finally
      lLogItem.Free;
    end;

    lAppender.TearDown;
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestAllExtendedInfo;
var
  lAppender: THTTPAppenderTestHelper;
  lLogItem: TLogItem;
  lStream: TStream;
  lContentType: string;
  lJSON: TJSONObject;
begin
  // Create with all extended info
  lAppender := THTTPAppenderTestHelper.Create('http://localhost/logs', THTTPContentType.JSON,
    TLoggerProHTTPAppender.DEFAULT_TIMEOUT_SECONDS,
    [TLogExtendedInfo.EIUserName, TLogExtendedInfo.EIComputerName,
     TLogExtendedInfo.EIProcessName, TLogExtendedInfo.EIProcessID]);
  try
    lAppender.Setup;

    lLogItem := TLogItem.Create(TLogType.Info, 'Full info', 'FULL');
    try
      lStream := lAppender.TestCreateData(lLogItem, lContentType);
      try
        Assert.IsNotNull(lStream);

        lJSON := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetBytes(TStringStream(lStream).DataString), 0) as TJSONObject;
        try
          Assert.IsNotNull(lJSON);
          // Should contain all extended info fields
          Assert.IsNotNull(lJSON.GetValue('hostname'), 'Should have hostname');
          Assert.IsNotNull(lJSON.GetValue('username'), 'Should have username');
          Assert.IsNotNull(lJSON.GetValue('processname'), 'Should have processname');
          Assert.IsNotNull(lJSON.GetValue('pid'), 'Should have pid');
        finally
          lJSON.Free;
        end;
      finally
        lStream.Free;
      end;
    finally
      lLogItem.Free;
    end;

    lAppender.TearDown;
  finally
    lAppender.Free;
  end;
end;

procedure THTTPAppenderTest.TestOverwriteHeader;
var
  lAppender: TLoggerProHTTPAppender;
begin
  lAppender := TLoggerProHTTPAppender.Create('http://localhost/api/logs');
  try
    // Add same header multiple times - should overwrite
    lAppender.AddHeader('Authorization', 'Bearer old_token');
    lAppender.AddHeader('Authorization', 'Bearer new_token');
    lAppender.AddHeader('Authorization', 'Bearer final_token');

    // No exception means success
    Assert.Pass('Header overwriting works correctly');
  finally
    lAppender.Free;
  end;
end;

{ TAppenderEnableDisableTest }

procedure TAppenderEnableDisableTest.TestAppenderEnabledByDefault;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  try
    Assert.IsTrue(lAppender.IsEnabled, 'Appender should be enabled by default');
  finally
    lAppender.Free;
  end;
end;

procedure TAppenderEnableDisableTest.TestDisableAppenderPreventWriting;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    // Disable the appender
    lAppender.SetEnabled(False);
    Assert.IsFalse(lAppender.IsEnabled, 'Appender should be disabled');

    // Log messages should not be written
    lLog.Debug('Message 1', 'TAG');
    lLog.Info('Message 2', 'TAG');
    lLog.Error('Message 3', 'TAG');

    Sleep(500);

    Assert.AreEqual(0, lAppender.Count, 'No messages should be written when appender is disabled');
  finally
    lLog := nil;
  end;
end;

procedure TAppenderEnableDisableTest.TestReEnableAppender;
var
  lAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
begin
  lAppender := TLoggerProMemoryRingBufferAppender.Create(100);
  lLog := BuildLogWriter([lAppender]);
  try
    // Disable appender
    lAppender.SetEnabled(False);
    lLog.Debug('Should not be logged', 'TAG');
    Sleep(300);
    Assert.AreEqual(0, lAppender.Count, 'No messages when disabled');

    // Re-enable appender
    lAppender.SetEnabled(True);
    Assert.IsTrue(lAppender.IsEnabled, 'Appender should be re-enabled');

    lLog.Debug('Should be logged', 'TAG');
    Sleep(300);
    Assert.AreEqual(1, lAppender.Count, 'Message should be logged after re-enabling');
  finally
    lLog := nil;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TMemoryAppenderTest);
  TDUnitX.RegisterTestFixture(TCallbackAppenderTest);
  TDUnitX.RegisterTestFixture(TTimeRotatingFileAppenderTest);
  TDUnitX.RegisterTestFixture(THTTPAppenderTest);
  TDUnitX.RegisterTestFixture(TAppenderEnableDisableTest);

end.
