program time_rotating_appender;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.IOUtils,
  LoggerPro,
  LoggerPro.TimeRotatingFileAppender,
  LoggerPro.Builder;

var
  lTimeRotatingAppender: TLoggerProTimeRotatingFileAppender;
  lLog: ILogWriter;
  lLogsFolder: string;
  lFiles: TArray<string>;
  I: Integer;

begin
  try
    WriteLn('LoggerPro Time Rotating File Appender Sample');
    WriteLn('=============================================');
    WriteLn;

    lLogsFolder := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'logs');
    WriteLn('Log folder: ' + lLogsFolder);
    WriteLn;

    // Create time rotating appender with daily rotation
    // Keeps max 7 backup files
    lTimeRotatingAppender := TLoggerProTimeRotatingFileAppender.Create(
      TTimeRotationInterval.Daily,  // Rotate daily
      7,                            // Keep 7 days of logs
      lLogsFolder,                  // Custom logs folder
      'myapp'                       // Base file name
    );

    // Create log writer
    // BuildLogWriter is the classic way to create a log writer.
    // The modern and recommended approach is to use LoggerProBuilder.
    //lLog := BuildLogWriter([lTimeRotatingAppender]);
    lLog := LoggerProBuilder
      .WriteToAppender(lTimeRotatingAppender)
      .Build;

    // Log some messages
    WriteLn('Logging messages...');
    lLog.Debug('Application started', 'main');
    lLog.Info('Time rotating appender demonstration', 'main');
    lLog.Info('Log files are named: myapp.YYYYMMDD.log', 'main');
    lLog.Warn('Old log files are automatically cleaned up', 'main');
    lLog.Error('This is an error for demonstration', 'main');
    lLog.Info('Supported intervals: Hourly, Daily, Weekly, Monthly', 'main');
    lLog.Debug('Application finished', 'main');

    // Wait for async processing
    Sleep(500);

    // Show created log files
    WriteLn;
    WriteLn('Log files in folder:');
    if TDirectory.Exists(lLogsFolder) then
    begin
      lFiles := TDirectory.GetFiles(lLogsFolder, '*.log');
      for I := 0 to Length(lFiles) - 1 do
        WriteLn('  ' + TPath.GetFileName(lFiles[I]));
    end;

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
