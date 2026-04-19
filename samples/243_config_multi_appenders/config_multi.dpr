program config_multi;

{$APPTYPE CONSOLE}

(*
  Multi-appender setup driven entirely by JSON config.

  Same result as sample 10_multiple_appenders (Console + File +
  OutputDebugString) but the appender list lives in loggerpro.json
  next to the EXE. Operators can swap backends, tune rotation, turn
  colors on/off without rebuilding the app.

  The Delphi side is a single call:

      Log := LoggerProFromJSONFile('loggerpro.json');
*)

uses
  System.SysUtils,
  System.IOUtils,
  LoggerPro;

var
  Log: ILogWriter;
  ConfigPath: string;
  i: Integer;

begin
  try
    ConfigPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
                                'loggerpro.json');
    Log := LoggerProFromJSONFile(ConfigPath);

    Log.Info('Application started', 'BOOT');
    Log.Debug('Debug diagnostic (visible only if minimumLevel allows)', 'BOOT');

    for i := 1 to 3 do
      Log.Info('Processed item', 'WORK', [
        LogParam.I('item_id', 1000 + i),
        LogParam.F('elapsed_ms', 15.5 * i)
      ]);

    Log.Warn('Cache hit ratio below 80%', 'CACHE');
    Log.Error('Payment gateway timeout', 'ORDERS',
              [LogParam.I('order_id', 4242)]);

    Log.Shutdown;
    Log := nil;

    Writeln;
    Writeln('Done. Same appender set as sample 10, but configured via JSON.');
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
