program config_per_level;

{$APPTYPE CONSOLE}

(*
  Per-appender log levels driven from JSON.

  Parallel to sample 15_appenders_with_different_log_levels - same
  pattern (one file for Info+, another file for Error+, plus
  OutputDebugString for Debug+), but the levels live in
  loggerpro.json so production operators can adjust them without a
  rebuild.

  Typical use: on-call escalation. Dev sees everything on the
  console; the main rotated file keeps Info and above; a separate
  "errors-only" file is small enough to attach to a bug report or
  email.
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

    Log.Debug('Boot sequence starting (console only)', 'BOOT');
    Log.Info('Application started on port 8080', 'HTTP');

    for i := 1 to 3 do
      Log.Info('Order placed', 'ORDERS',
               [LogParam.I('order_id', 1000 + i)]);

    Log.Warn('Cache hit ratio below 80% - console + logs/', 'CACHE');
    Log.Error('Payment gateway timeout - lands in BOTH files', 'ORDERS',
              [LogParam.I('order_id', 1005)]);
    Log.Fatal('Out of memory - also in errors-only', 'SYS');

    Log.Shutdown;
    Log := nil;

    Writeln;
    Writeln('Done. Tail logs/ for Info+, logs_errors/ for Error+ only.');
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
