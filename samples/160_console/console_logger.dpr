program console_logger;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  LoggerPro,
  LoggerProConfig in 'LoggerProConfig.pas';

begin
  try
    WriteLn('LoggerPro Console Sample');
    WriteLn('========================');
    WriteLn;
    Log.Debug('Application started', 'main');
    Log.Info('This is an info message', 'main');
    Log.Warn('This is a warning message', 'main');
    Log.Error('This is an error message', 'main');
    Log.Fatal('This is a fatal message', 'main');

    Log.Info('Processing item %d of %d', [1, 10], 'processing');
    Log.Info('Processing item %d of %d', [5, 10], 'processing');
    Log.Info('Processing item %d of %d', [10, 10], 'processing');

    Log.Debug('Application finished', 'main');

    WriteLn;
    WriteLn('All log messages sent. Exiting...');
  except
    on E: Exception do
    begin
      Log.Fatal('Unhandled exception: %s', [E.Message], 'main');
      Writeln(E.ClassName, ': ', E.Message);
    end;
  end;
end.
