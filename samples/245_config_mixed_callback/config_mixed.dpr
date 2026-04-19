program config_mixed;

{$APPTYPE CONSOLE}

(*
  JSON base + a runtime Callback appender chained from code.

  This is the pattern to use when part of the logger shape must stay
  in configuration (ship to ops, toggle at deploy time) while another
  part MUST stay in code because it references a live runtime object
  - a callback, a TStrings, a VCL component, a TFDConnection.

  In this sample, loggerpro.json defines Console + File. The code
  chains a Callback appender that mirrors every log line to an
  in-memory "audit" list the application queries later.
*)

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  LoggerPro,
  LoggerPro.Builder;

var
  Log: ILogWriter;
  ConfigPath: string;
  AuditLog: TStringList;
  i: Integer;

begin
  AuditLog := TStringList.Create;
  try
    ConfigPath := TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
                                'loggerpro.json');

    // Load Console + File from JSON, THEN chain Callback from code.
    // The builder-returning variant is the key: it stops short of
    // calling .Build so the caller keeps chaining.
    Log := LoggerProBuilderFromJSONFile(ConfigPath)
      .WriteToCallback
        .WithCallback(
          procedure(const aLogItem: TLogItem; const aFormattedMessage: string)
          begin
            // Runs on the logger thread - the audit TStringList is
            // private to this thread's drain loop, no lock needed.
            AuditLog.Add(aFormattedMessage);
          end)
        .Done
      .Build;

    Log.Info('Application started', 'BOOT');
    for i := 1 to 5 do
      Log.Info('Order placed', 'ORDERS', [
        LogParam.I('order_id', 1000 + i),
        LogParam.F('amount', 19.95 + i * 10)
      ]);
    Log.Warn('Cache hit ratio below 80%', 'CACHE');
    Log.Error('Payment gateway timeout', 'ORDERS',
              [LogParam.I('order_id', 1005)]);

    Log.Shutdown;
    Log := nil;

    Writeln;
    Writeln(Format('In-memory audit captured %d lines:', [AuditLog.Count]));
    Writeln('---');
    Writeln(AuditLog.Text);
    Writeln('---');
    Writeln('Done. Console + File came from JSON; the audit callback came from code.');
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
  AuditLog.Free;
end.
