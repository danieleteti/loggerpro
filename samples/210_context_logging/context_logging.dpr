program context_logging;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  LoggerPro,
  LoggerProConfig in 'LoggerProConfig.pas';

procedure SimulateUserSession(const UserID: Integer; const UserName: string);
var
  SessionLog: ILogWriter;
begin
  // Create a logger with bound context for this user session
  // The context is automatically included in all subsequent log calls
  SessionLog := Log.WithProperty('user_id', UserID).WithProperty('user_name', UserName);

  SessionLog.Info('User session started', 'SESSION');
  SessionLog.Debug('Loading user preferences', 'SESSION');
  SessionLog.Info('User preferences loaded successfully', 'SESSION');

  // One-shot context for additional info in a single call
  SessionLog.Info('User action performed', 'SESSION', [
    LogParam.S('action', 'view_dashboard'),
    LogParam.I('dashboard_id', 42)
  ]);

  SessionLog.Info('User session ended', 'SESSION');
end;

procedure SimulateOrderProcessing;
begin
  // One-shot context - no wrapper needed, zero overhead
  Log.Info('Order received', 'ORDERS', [
    LogParam.S('customer', 'Alice Smith'),
    LogParam.I('order_id', 12345),
    LogParam.F('amount', 299.99),
    LogParam.B('express_shipping', True)
  ]);

  Log.Debug('Validating order', 'ORDERS', [
    LogParam.I('order_id', 12345),
    LogParam.S('status', 'validating')
  ]);

  Log.Info('Payment processed', 'ORDERS', [
    LogParam.I('order_id', 12345),
    LogParam.S('payment_method', 'credit_card'),
    LogParam.S('transaction_id', 'TXN-789-ABC')
  ]);

  Log.Info('Order completed', 'ORDERS', [
    LogParam.I('order_id', 12345),
    LogParam.S('status', 'completed')
  ]);
end;

begin
  try
    WriteLn('LoggerPro Context Logging Sample');
    WriteLn('=================================');
    WriteLn;
    WriteLn('Demonstrating structured logging with key-value context.');
    WriteLn;

    // Standard logging (no context)
    Log.Info('Application started', 'MAIN');

    // Logging with one-shot context (recommended for most cases)
    Log.Info('System initialized', 'MAIN', [
      LogParam.S('version', '2.0.0'),
      LogParam.S('environment', 'development'),
      LogParam.I('worker_threads', 4)
    ]);

    WriteLn('Simulating user sessions...');
    SimulateUserSession(1001, 'john.doe');
    SimulateUserSession(1002, 'jane.smith');

    WriteLn('Simulating order processing...');
    SimulateOrderProcessing;

    // Error logging with context
    Log.Error('Database connection failed', 'DATABASE', [
      LogParam.S('host', 'db.example.com'),
      LogParam.I('port', 5432),
      LogParam.I('retry_count', 3),
      LogParam.B('ssl_enabled', True)
    ]);

    Log.Info('Application shutdown', 'MAIN');

    WriteLn;
    WriteLn('Check the log files in the current directory.');
    WriteLn('  - JSONL format: context_logging.00.jsonl.log');
    WriteLn('  - LogFmt format: context_logging.00.logfmt.log');
    WriteLn;
    WriteLn('Press Enter to exit...');
  except
    on E: Exception do
    begin
      Log.Fatal('Unhandled exception: %s', [E.Message], 'MAIN');
      Writeln(E.ClassName, ': ', E.Message);
    end;
  end;
  ReadLn;
end.
