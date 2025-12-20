program callback_appender;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  LoggerPro,
  LoggerPro.CallbackAppender,
  LoggerPro.Builder;

var
  lCallbackAppender: TLoggerProCallbackAppender;
  lLog: ILogWriter;
  lErrorCount: Integer;
  I: Integer;

begin
  try
    WriteLn('LoggerPro Callback Appender Sample');
    WriteLn('===================================');
    WriteLn;

    lErrorCount := 0;

    // Create callback appender with a simple message callback
    // This callback counts errors and displays formatted messages
    lCallbackAppender := TLoggerProCallbackAppender.Create(
      procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
      begin
        // Count errors
        if aLogItem.LogType >= TLogType.Error then
          Inc(lErrorCount);

        // Display with custom prefix based on log type
        case aLogItem.LogType of
          TLogType.Debug:   WriteLn('[D] ' + aFormattedMessage);
          TLogType.Info:    WriteLn('[I] ' + aFormattedMessage);
          TLogType.Warning: WriteLn('[W] ' + aFormattedMessage);
          TLogType.Error:   WriteLn('[E] >>> ' + aFormattedMessage + ' <<<');
          TLogType.Fatal:   WriteLn('[F] !!! ' + aFormattedMessage + ' !!!');
        end;
      end,
      False // Not synchronized to main thread (we're in console app)
    );

    // Create log writer
    // BuildLogWriter is the classic way to create a log writer.
    // The modern and recommended approach is to use LoggerProBuilder.
    //lLog := BuildLogWriter([lCallbackAppender]);
    lLog := LoggerProBuilder
      .WriteToAppender(lCallbackAppender)
      .Build;

    // Log some messages
    WriteLn('Sending log messages through callback appender:');
    WriteLn('---');

    lLog.Debug('Application starting...', 'main');
    lLog.Info('Loading configuration', 'config');
    lLog.Info('Connecting to database', 'db');
    lLog.Warn('Connection pool running low', 'db');
    lLog.Error('Failed to connect to replica', 'db');
    lLog.Info('Fallback to primary succeeded', 'db');
    lLog.Fatal('Critical: Disk space low!', 'system');
    lLog.Debug('Application initialized', 'main');

    // Example using WithProperty for structured context
    var lDbLog := lLog
      .WithProperty('db_host', 'localhost')
      .WithProperty('db_port', 5432);
    lDbLog.Info('Executing query', 'db');
    lDbLog.Debug('Query completed in 42ms', 'db');

    // Wait for async processing
    Sleep(500);

    WriteLn('---');
    WriteLn;
    WriteLn('Total errors/fatals counted: ' + lErrorCount.ToString);

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
