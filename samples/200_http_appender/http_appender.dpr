program http_appender;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  LoggerPro,
  LoggerPro.Builder;

var
  lLog: ILogWriter;

begin
  try
    WriteLn('LoggerPro HTTP Appender Sample');
    WriteLn('===============================');
    WriteLn;
    WriteLn('This sample demonstrates sending logs via HTTP POST.');
    WriteLn('Configure the URL below to point to your log collector.');
    WriteLn;

    // Create log writer with HTTP appender using fluent builder
    lLog := LoggerProBuilder
      .WriteToHTTP
        .WithURL('https://httpbin.org/post')
        .WithContentType(THTTPContentType.JSON)
        .WithTimeout(5)
        .WithHeader('X-API-Key', 'your-api-key-here')
        .WithHeader('X-Application', 'LoggerProSample')
        .Done
      .WriteToSimpleConsole.Done
      .Build;

    // Log some messages
    WriteLn('Sending log messages via HTTP...');
    WriteLn('---');

    lLog.Debug('Application started', 'http_sample');
    lLog.Info('HTTP appender is working', 'http_sample');
    lLog.Warn('This is a warning message', 'http_sample');
    lLog.Error('This is an error message', 'http_sample');

    // Example using WithProperty for structured context
    var lRequestLog := lLog
      .WithProperty('endpoint', 'httpbin.org')
      .WithProperty('content_type', 'JSON')
      .WithProperty('timeout_sec', 5);
    lRequestLog.Info('Request context attached to log entries', 'http_sample');
    lRequestLog.Debug('HTTP appender configuration logged', 'http_sample');

    // Wait for HTTP requests to complete
    Sleep(2000);

    WriteLn('---');
    WriteLn;
    WriteLn('Log messages sent! Check your endpoint for received data.');
    WriteLn('The JSON payload includes: timestamp, level, message, tag, hostname, tid');
    WriteLn;
    WriteLn('Done!');

    // Cleanup
    lLog := nil;

  except
    on E: Exception do
    begin
      Writeln('ERROR: ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
