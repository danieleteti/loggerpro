program webhook_appender;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  LoggerPro,
  LoggerPro.Builder,
  LoggerPro.WebhookAppender;

var
  lLog: ILogWriter;
  lRequestLog: ILogWriter;

begin
  try
    WriteLn('LoggerPro Webhook Appender Sample');
    WriteLn('==================================');
    WriteLn;
    WriteLn('Sends each log item as one HTTP POST to a webhook endpoint.');
    WriteLn('Default payload is JSON; API key carried in header or query string.');
    WriteLn;

    lLog := LoggerProBuilder
      .WriteToWebhook
        .WithLogLevel(TLogType.Info) //INFO+ (DEBUG level is not sent)
        .WithURL('https://httpbin.org/post')
        .WithContentType(TWebhookContentType.JSON)
        .WithTimeout(5)
        .WithRetryCount(3)
        // API key as HTTP header (defaults to "X-API-Key" when name is empty)
        .WithAPIKey('your-api-key-here', TWebhookAPIKeyLocation.Header, '')
        .WithHeader('X-Application', 'LoggerProSample')
        .Done
      .WriteToSimpleConsole.Done
      .Build;

    WriteLn('Posting log messages to the webhook...');
    WriteLn('---');

    lLog.Debug('Application started', 'webhook');
    lLog.Info('Webhook appender is working', 'webhook');
    lLog.Warn('This is a warning message', 'webhook');
    lLog.Error('This is an error message', 'webhook');

    // Structured context via WithProperty - each property becomes a field
    // in the JSON payload emitted by the webhook appender.
    lRequestLog := lLog
      .WithProperty('endpoint', 'httpbin.org')
      .WithProperty('content_type', 'JSON')
      .WithProperty('timeout_sec', 5);
    lRequestLog.Info('Request context attached to log entries', 'webhook');
    lRequestLog.Debug('Webhook configuration logged', 'webhook');

    Sleep(2000);

    WriteLn('---');
    WriteLn;
    WriteLn('Log messages posted. Check your endpoint for received data.');
    WriteLn('JSON payload fields: timestamp, level, message, tag, hostname, tid.');
    WriteLn;
    WriteLn('Done!');

    lLog := nil;
  except
    on E: Exception do
    begin
      Writeln('ERROR: ' + E.ClassName + ': ' + E.Message);
      ExitCode := 1;
    end;
  end;
end.
