program config_fallback;

{$APPTYPE CONSOLE}

(*
  "Graceful degradation" pattern: try to load a config file; if it is
  missing, malformed, or points to an unknown appender type, build a
  sensible default in code instead of crashing the application.

  Why this matters:
    - First-run experience: a fresh install often has no config file yet.
    - Misconfigured deployment: a typo in production JSON should not
      take the whole app down - it should log the problem and keep
      going with a safe fallback.

  The fallback here is intentionally spartan (console only) so you can
  see the difference: run it with the JSON in place -> File + Console;
  delete the JSON or break it -> Console-only fallback with an error
  log entry explaining what happened.

  Try these scenarios:
    1) Plain run:       leave loggerpro.json as is               -> config-driven
    2) Missing file:    rename loggerpro.json to loggerpro.bak   -> fallback
    3) Malformed JSON:  introduce a syntax error in the file     -> fallback
    4) Unknown type:    change "Console" to "Cansole"            -> fallback
*)

uses
  System.SysUtils,
  System.IOUtils,
  LoggerPro,
  LoggerPro.Builder;

function BuildFromFileOrFallback(const aConfigPath: string): ILogWriter;
var
  lReason: String;
begin
  lReason := '';
  Result := nil;
  // 1. File missing -> fallback with a clear reason.
  if not TFile.Exists(aConfigPath) then
  begin
    lReason := Format('Config file not found: "%s". Using built-in defaults.', [aConfigPath]);
    Result := LoggerProBuilder
      .WriteToConsole.WithColors.Done
      .WithMinimumLevel(TLogType.Info)
      .Build;
  end;

  if Result = nil then
  begin
    // 2. File present -> try to load. Any parse error falls back too.
    try
      Result := LoggerProFromJSONFile(aConfigPath);
    except
      on E: ELoggerProConfigError do
      begin
        lReason := Format('Config file "%s" is invalid (%s). Using built-in defaults.',
          [aConfigPath, E.Message]);
        Result := LoggerProBuilder
          .WriteToConsole.WithColors.Done
          .WithMinimumLevel(TLogType.Info)
          .Build;
      end;
    end;
  end;

  // Surface the fallback reason in the log stream itself so operators
  // immediately notice the configuration problem on the next search.
  if not lReason.IsEmpty then
  begin
    Result.Warn(lReason, 'CONFIG');
  end;
end;

var
  Log: ILogWriter;
  ConfigPath: string;
begin
  try
    ConfigPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)), 'loggerpro.json');
    Log := BuildFromFileOrFallback(ConfigPath);

    Log.Info('Application started', 'BOOT');
    Log.Debug('Detailed diagnostic - visible only if MinimumLevel allows it', 'DIAG');
    Log.Warn('Cache hit ratio below 80%', 'CACHE');
    Log.Error('Payment gateway timeout', 'ORDERS', [
      LogParam.I('order_id', 42),
      LogParam.S('gateway', 'stripe')
    ]);
    Log.Fatal('Out of memory', 'SYS');

    Log.Shutdown;
    Log := nil;
    Writeln;
    Writeln('Done.');
  except
    on E: Exception do
    begin
      Writeln('Unrecoverable: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
