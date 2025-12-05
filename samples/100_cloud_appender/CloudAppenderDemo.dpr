program CloudAppenderDemo;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  LoggerPro,
  LoggerPro.FileAppender,
  LoggerPro.ConsoleAppender,
  LoggerPro.CloudAppender;

const
  // Replace with your actual API key and customer ID
  API_KEY = 'lpc_desk_pc0b2YcamAfijVlTRb2207Z80bVmGmDBFGu8B-trYIs';
  CUSTOMER_ID = 'loggerpro-demo';
  ENDPOINT = 'http://localhost:8000';  // For local development

var
  Log: ILogWriter;
  I: Integer;
  Input: string;

procedure SetupLogger;
begin
  // Build the log writer with 3 appenders:
  // 1. Console - for immediate visual feedback
  // 2. File - for local persistent storage
  // 3. Cloud - for remote centralized logging
  //
  // Note: Using anonymous procedures for callbacks - no memory leaks!
  Log := BuildLogWriter([
    TLoggerProConsoleAppender.Create,
    TLoggerProFileAppender.Create(5, 1024, 'logs'),  // 5 files, 1MB each
    TLoggerProCloudAppender.Create(API_KEY, CUSTOMER_ID, ENDPOINT,
      // OnError callback
      procedure(const ErrorMessage: string)
      begin
        WriteLn('[CLOUD ERROR] ' + ErrorMessage);
      end,
      // OnLogsSent callback
      procedure(AcceptedCount, RejectedCount: Integer)
      begin
        WriteLn(Format('[CLOUD] Sent: %d accepted, %d rejected', [AcceptedCount, RejectedCount]));
      end,
      // OnCustomDeviceInfo callback - called once during setup
      procedure(const CustomInfo: TDictionary<string, string>)
      begin
        CustomInfo.Add('app_mode', 'demo');
        CustomInfo.Add('license_type', 'evaluation');
        WriteLn('[CLOUD] Custom device info will be sent with hardware info');
      end
    )
  ]);

  WriteLn('Logger initialized with 3 appenders:');
  WriteLn('  1. Console Appender');
  WriteLn('  2. File Appender (logs folder)');
  WriteLn('  3. Cloud Appender (LoggerPro Cloud)');
  WriteLn('');
end;

begin
  try
    ReportMemoryLeaksOnShutdown := True;

    WriteLn('===========================================');
    WriteLn('  LoggerPro Cloud Appender Demo');
    WriteLn('===========================================');
    WriteLn('');

    SetupLogger;

    // Send some test logs
    WriteLn('Sending test logs...');
    WriteLn('');

    Log.Debug('Application started', 'STARTUP');
    Log.Info('Logger initialized with Console, File, and Cloud appenders', 'STARTUP');

    // Simulate some application activity
    for I := 1 to 5 do
    begin
      Log.Info(Format('Processing item %d of 5', [I]), 'PROCESS');
      Sleep(100);
    end;

    Log.Warn('This is a warning message', 'DEMO');
    Log.Error('This is an error message (not a real error)', 'DEMO');

    WriteLn('');
    WriteLn('Press ENTER to send more logs, or type "quit" to exit...');
    WriteLn('');

    repeat
      ReadLn(Input);
      if LowerCase(Trim(Input)) <> 'quit' then
      begin
        Log.Info('User pressed ENTER at ' + FormatDateTime('hh:nn:ss', Now), 'USER');
        Log.Debug('Additional debug info: Input was "' + Input + '"', 'USER');
        WriteLn('Logs sent! Press ENTER again or type "quit" to exit...');
      end;
    until LowerCase(Trim(Input)) = 'quit';

    Log.Info('Application shutting down', 'SHUTDOWN');
    WriteLn('');
    WriteLn('Shutting down... waiting for logs to be sent...');

    // Give some time for logs to be sent
    Sleep(2000);

    // Cleanup - just release the log writer, no event handler to free!
    Log := nil;

    WriteLn('Done!');
  except
    on E: Exception do
    begin
      WriteLn('Error: ' + E.Message);
      ReadLn;
    end;
  end;
end.
