program config_simple;

{$APPTYPE CONSOLE}

(*
  Simplest config-file usage. Single JSON, single call:
      Log := LoggerProFromJSONFile('loggerpro.json');

  Change the JSON next to the EXE to reshape the logger without
  rebuilding. This sample deliberately sticks to one appender
  (Console + colors) so the JSON fits on a postcard.
*)

uses
  System.SysUtils,
  System.IOUtils,
  LoggerPro;

var
  Log: ILogWriter;
  ConfigPath: string;

begin
  try
    // The config is expected next to the executable.
    ConfigPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'loggerpro.json');
    Log := LoggerProFromJSONFile(ConfigPath);

    Log.Debug('Boot sequence starting', 'BOOT');
    Log.Info('Config loaded from ' + ExtractFileName(ConfigPath), 'CONFIG');
    Log.Info('Application started on port 8080', 'HTTP');
    Log.Warn('Cache hit ratio below 80%', 'CACHE');
    Log.Error('Database connection failed', 'DB');
    Log.Fatal('Out of memory', 'SYS');

    Log.Shutdown;
    Log := nil;
    Writeln;
    Writeln('Done.');
  except
    on E: ELoggerProConfigError do
    begin
      Writeln('Config error: ', E.Message);
      ExitCode := 1;
    end;
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
