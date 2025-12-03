program http_appender;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  LoggerPro,
  LoggerPro.HTTPAppender,
  LoggerPro.SimpleConsoleAppender;

var
  lHTTPAppender: TLoggerProHTTPAppender;
  lConsoleAppender: TLoggerProSimpleConsoleAppender;
  lLog: ILogWriter;

begin
  try
    WriteLn('LoggerPro HTTP Appender Sample');
    WriteLn('===============================');
    WriteLn;
    WriteLn('This sample demonstrates sending logs via HTTP POST.');
    WriteLn('Configure the URL below to point to your log collector.');
    WriteLn;

    // Create HTTP appender
    // Point this to your log collector endpoint (e.g., Logstash, custom webhook)
    // For testing, you can use services like https://webhook.site
    lHTTPAppender := TLoggerProHTTPAppender.Create(
      'https://httpbin.org/post',     // Test endpoint that echoes back
      THTTPContentType.JSON,          // Send as JSON
      5                               // 5 second timeout
    );

    // Add custom headers if needed (e.g., API key)
    lHTTPAppender.AddHeader('X-API-Key', 'your-api-key-here');
    lHTTPAppender.AddHeader('X-Application', 'LoggerProSample');

    // Also log to console so we can see what's being sent
    lConsoleAppender := TLoggerProSimpleConsoleAppender.Create;

    // Create log writer with both appenders
    lLog := BuildLogWriter([lHTTPAppender, lConsoleAppender]);

    // Log some messages
    WriteLn('Sending log messages via HTTP...');
    WriteLn('---');

    lLog.Debug('Application started', 'http_sample');
    lLog.Info('HTTP appender is working', 'http_sample');
    lLog.Warn('This is a warning message', 'http_sample');
    lLog.Error('This is an error message', 'http_sample');

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
