program memory_appender;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Generics.Collections,
  LoggerPro,
  LoggerPro.MemoryAppender,
  LoggerPro.Builder;

var
  lMemoryAppender: TLoggerProMemoryRingBufferAppender;
  lLog: ILogWriter;
  lItems: TArray<string>;
  lLogItems: TList<TLogItem>;
  I: Integer;

begin
  try
    WriteLn('LoggerPro Memory Ring Buffer Appender Sample');
    WriteLn('=============================================');
    WriteLn;

    // Create memory appender with max 50 items
    lMemoryAppender := TLoggerProMemoryRingBufferAppender.Create(50);

    // Create log writer
    // BuildLogWriter is the classic way to create a log writer.
    // The modern and recommended approach is to use LoggerProBuilder.
    //lLog := BuildLogWriter([lMemoryAppender]);
    lLog := LoggerProBuilder
      .WriteToAppender(lMemoryAppender)
      .Build;

    // Log some messages
    WriteLn('Logging 10 messages...');
    for I := 1 to 10 do
    begin
      case I mod 5 of
        0: lLog.Fatal('Fatal message #' + I.ToString, 'test');
        1: lLog.Debug('Debug message #' + I.ToString, 'test');
        2: lLog.Info('Info message #' + I.ToString, 'test');
        3: lLog.Warn('Warning message #' + I.ToString, 'test');
        4: lLog.Error('Error message #' + I.ToString, 'test');
      end;
    end;

    // Wait for async processing
    Sleep(500);

    // Show buffer contents
    WriteLn;
    WriteLn('Memory buffer contains ' + lMemoryAppender.Count.ToString + ' items:');
    WriteLn('---');
    lItems := lMemoryAppender.GetAsStringList;
    for I := 0 to Length(lItems) - 1 do
      WriteLn(lItems[I]);
    WriteLn('---');

    // Show filtered by type (errors only)
    WriteLn;
    WriteLn('Filtering ERROR messages only:');
    lLogItems := lMemoryAppender.GetLogItemsByType(TLogType.Error);
    try
      for I := 0 to lLogItems.Count - 1 do
        WriteLn('  ' + lLogItems[I].LogMessage);
    finally
      for I := 0 to lLogItems.Count - 1 do
        lLogItems[I].Free;
      lLogItems.Free;
    end;

    // Clear buffer
    WriteLn;
    WriteLn('Clearing buffer...');
    lMemoryAppender.Clear;
    WriteLn('Buffer now contains ' + lMemoryAppender.Count.ToString + ' items');

    WriteLn;
    WriteLn('Done!');

    // Cleanup
    lLog := nil;

  except
    on E: Exception do
    begin
      Writeln('ERROR: ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
