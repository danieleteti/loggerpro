program html_demo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  LoggerPro,
  LoggerPro.Builder;

var
  Log: ILogWriter;
  OrderLog: ILogWriter;
  I, J, lOrderID: Integer;

begin
  try
    Log := LoggerProBuilder
      .WriteToConsole
        .WithColors
        .Done
      .WriteToHTMLFile
        .WithLogsFolder('logs')
        .WithFileBaseName('html_demo')
        .WithTitle('HTML Demo - LoggerPro')
        .WithMaxBackupFiles(3)
        .WithMaxFileSizeInKB(500)
        .Done
      .Build;

    Log.Debug('Boot sequence starting', 'BOOT');
    Log.Info('Application started on port 8080', 'HTTP');
    Log.Info('Listening for connections', 'HTTP');
    Log.Warn('Cache hit ratio below 80%', 'CACHE');
    Log.Warn('Config file version is old; auto-migrating', 'CONFIG');

    lOrderID := 1000;
    for J := 1 to 4 do
    begin
      Sleep(2000);
      // A burst of "request" logs with context.
      OrderLog := Log.WithDefaultTag('ORDERS');
      for I := 1 to 25 do
      begin
        OrderLog.Info('Order placed', 'ORDERS', [
          LogParam.I('order_id', lOrderID),
          LogParam.S('customer', Format('Customer #%d', [I])),
          LogParam.F('amount', 19.95 + I * 10),
          LogParam.B('paid', Odd(I))
        ]);
        Inc(lOrderID);
        Sleep(20);
      end;

      Log.Error('Database connection failed after 3 retries', 'DB');
      Log.Error('Payment gateway timeout', 'ORDERS', [
        LogParam.I('order_id', 1005),
        LogParam.S('gateway', 'stripe')
      ]);

      Log.Fatal('Out of memory - aborting', 'SYS');

      // Context with special characters to prove HTML escaping works.
      Log.Info('User input: <script>alert("xss")</script>', 'SECURITY', [
        LogParam.S('ip', '203.0.113.42'),
        LogParam.S('user-agent', 'curl/8.0 & friends')
      ]);

    end;
    Log.Shutdown;
    Log := nil;

    Writeln;
    Writeln('Done. Open logs/html_demo.00.html in a browser.');
    Sleep(5000);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
