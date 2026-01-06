program console_logger;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  LoggerPro,
  LoggerProConfig in 'LoggerProConfig.pas';

begin
  try
    WriteLn('LoggerPro 2.0 Console Sample');
    WriteLn('=============================');
    WriteLn;

    // -------------------------------------------------------------------------
    // Basic logging - all log levels
    // -------------------------------------------------------------------------
    Log.Debug('Application started');  // Uses default tag 'main' from config
    Log.Info('This is an info message');
    Log.Warn('This is a warning message');
    Log.Error('This is an error message');
    Log.Fatal('This is a fatal message');

    WriteLn;

    // -------------------------------------------------------------------------
    // Format string logging
    // -------------------------------------------------------------------------
    Log.Info('Processing item %d of %d', [1, 10], 'processing');
    Log.Info('Processing item %d of %d', [5, 10], 'processing');
    Log.Info('Processing item %d of %d', [10, 10], 'processing');

    WriteLn;

    // -------------------------------------------------------------------------
    // LoggerPro 2.0: WithProperty for structured context
    // -------------------------------------------------------------------------
    // Create a sub-logger with bound context properties.
    // All subsequent logs from this logger will include these properties.
    var lCtxLog := Log
      .WithProperty('user_id', 42)
      .WithProperty('session', 'abc123');
    lCtxLog.Info('User logged in', 'auth');
    lCtxLog.Debug('Loading preferences', 'auth');

    WriteLn;

    // -------------------------------------------------------------------------
    // LoggerPro 2.0: LogException for exception logging
    // -------------------------------------------------------------------------
    WriteLn('Demonstrating exception logging...');
    try
      raise Exception.Create('Simulated error for demonstration');
    except
      on E: Exception do
      begin
        // Simple exception logging
        Log.LogException(E);

        // Exception with custom message
        Log.LogException(E, 'Failed during demo');

        // Exception with custom message and tag
        Log.LogException(E, 'Critical failure in demo', 'CRITICAL');
      end;
    end;

    WriteLn;

    // -------------------------------------------------------------------------
    // LoggerPro 2.0: WithDefaultTag for sub-loggers
    // -------------------------------------------------------------------------
    // Create a sub-logger with a different default tag
    var OrderLog := Log.WithDefaultTag('ORDERS');
    OrderLog.Info('New order received');  // Tag = 'ORDERS'
    OrderLog.Debug('Validating order');   // Tag = 'ORDERS'

    Log.Debug('Application finished');

    WriteLn;
    WriteLn('All log messages sent. Check the logs folder.');
    WriteLn('Press Enter to exit...');
  except
    on E: Exception do
    begin
      Log.LogException(E, 'Unhandled exception');
      Writeln(E.ClassName, ': ', E.Message);
    end;
  end;
  ReadLn;
end.
