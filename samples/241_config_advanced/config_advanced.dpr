program config_advanced;

{$APPTYPE CONSOLE}

(*
  Articulated config-file example. The JSON wires up six appenders with
  per-appender log-level gates, rotation settings, color schemes and a
  global default tag. The program itself stays trivial: load, log,
  shut down.

  The interesting part is loggerpro.json next to this file:
    - Console       -> colorful "Midnight" scheme, with prefix tag
    - File          -> daily rotation + size-based rotation fallback
    - HTMLFile      -> browser-ready tail view
    - JSONLFile     -> structured records for grep/jq pipelines
    - Memory        -> ring buffer kept in RAM (for in-app diagnostics)
    - OutputDebugString -> wired up for attached debuggers
*)

uses
  System.SysUtils,
  System.IOUtils,
  LoggerPro;

var
  Log: ILogWriter;
  OrderLog: ILogWriter;
  ConfigPath: string;
  i: Integer;

begin
  try
    ConfigPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'loggerpro.json');
    Log := LoggerProFromJSONFile(ConfigPath);

    Log.Info('Application started', 'BOOT');
    Log.Debug('Six appenders wired up via JSON', 'BOOT');
    Log.Warn('Cache hit ratio below 80%', 'CACHE');

    // Structured context: each property lands in JSONL as a field and in
    // HTML/Console as key=value pairs.
    OrderLog := Log.WithDefaultTag('ORDERS');
    for i := 1 to 5 do
      OrderLog.Info('Order placed', 'ORDERS', [
        LogParam.I('order_id', 1000 + i),
        LogParam.S('customer', Format('Customer #%d', [i])),
        LogParam.F('amount', 19.95 + i * 10),
        LogParam.B('paid', Odd(i))
      ]);

    Log.Error('Database connection failed after 3 retries', 'DB');
    Log.Fatal('Out of memory - shutting down', 'SYS');

    Log.Shutdown;
    Log := nil;
    Writeln;
    Writeln('Done. Check the logs/ folder and attached debugger output.');
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
