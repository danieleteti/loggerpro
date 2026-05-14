program filebysource_appender;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  LoggerPro,
  LoggerProConfig in 'LoggerProConfig.pas';

procedure SimulateMultiTenantLogs;
var
  lClientA, lClientB, lClientC: ILogWriter;
begin
  // Bind 'source' once per tenant -> all logs land in that tenant's folder.
  lClientA := Log.WithProperty('source', 'ClientA');
  lClientB := Log.WithProperty('source', 'ClientB');
  lClientC := Log.WithProperty('source', 'ClientC');

  // Different tags inside the same source -> different files in same folder.
  lClientA.Info('order #1001 received', 'ORDERS');
  lClientA.Info('order #1002 received', 'ORDERS');
  lClientA.Warn('payment retry for #1001', 'PAYMENTS');
  lClientA.Error('payment failed for #1001', 'PAYMENTS');

  lClientB.Info('GET /api/users -> 200', 'API');
  lClientB.Info('GET /api/orders -> 200', 'API');
  lClientB.Warn('slow query 1.2s', 'DB');

  lClientC.Info('login user=alice', 'AUTH');
  lClientC.Error('login failed user=bob', 'AUTH');
end;

procedure SimulateInlineSourceOverride;
var
  lScoped: ILogWriter;
begin
  // 'source' bound here ('worker-1') can be overridden per-call.
  lScoped := Log.WithProperty('source', 'worker-1');
  lScoped.Info('starting job', 'JOBS');

  // Inline LogParam.S('source', ...) wins over the bound one.
  lScoped.Info('handoff to worker-2',
    'JOBS',
    [LogParam.S('source', 'worker-2')]);

  lScoped.Info('job done', 'JOBS');
end;

procedure SimulateUnclassifiedLogs;
begin
  // No 'source' in context -> goes to <DefaultSource> folder ('default').
  Log.Info('startup completed');
  Log.Warn('config file missing, using defaults');
end;

begin
  try
    WriteLn('LoggerPro - FileBySource Appender Sample');
    WriteLn('========================================');
    WriteLn;
    WriteLn('Watch the "logs" folder: one subfolder per source.');
    WriteLn;

    SimulateUnclassifiedLogs;
    SimulateMultiTenantLogs;
    SimulateInlineSourceOverride;

    WriteLn;
    WriteLn('Done. Check the logs/ folder tree.');
    WriteLn('Press Enter to exit...');
    ReadLn;
  except
    on E: Exception do
    begin
      Log.LogException(E, 'Unhandled exception');
      WriteLn(E.ClassName, ': ', E.Message);
      ReadLn;
    end;
  end;
end.
