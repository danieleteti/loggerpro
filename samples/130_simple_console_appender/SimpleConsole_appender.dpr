program SimpleConsole_appender;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, System.Classes, System.Threading,
  LoggerPro,
  LoggerPro.ConsoleAppender,
  LoggerPro.Builder;

const
  MAX_TASK = 5;
var
  lTasks: array of ITask;
  lLog: ILogWriter;
  lErrLog: ILogWriter;
begin
  lLog := LoggerProBuilder
    .WriteToSimpleConsole.Done
    .Build;

  // Example using WithProperty for structured context
  var lCtxLog := lLog
    .WithProperty('app_version', '1.0.0')
    .WithProperty('environment', 'demo');
  lCtxLog.Info('Application started with context', 'STARTUP');

  Setlength (lTasks, MAX_TASK);
  for var i := 0 to MAX_TASK - 1 do begin
    lTasks[i] := TTask.Create(procedure
    var
      I: Integer;
      lThreadID: string;
      lTaskLog: ILogWriter;
    begin
      lThreadID := TTask.CurrentTask.Id.ToString;
      // Each task gets its own context with task_id
      lTaskLog := lLog.WithProperty('task_id', lThreadID);
      for I := 1 to 200 do
      begin
        lTaskLog.Debug('log message ' + TimeToStr(now), 'MULTITHREADING');
        lTaskLog.Info('log message ' + TimeToStr(now), 'MULTITHREADING');
        lTaskLog.Warn('log message ' + TimeToStr(now), 'MULTITHREADING');
        lTaskLog.Error('log message ' + TimeToStr(now), 'MULTITHREADING');
        lTaskLog.Fatal('log message ' + TimeToStr(now), 'MULTITHREADING');
      end;
    end);
    lTasks[i].Start;
  end;

  TTask.WaitForAll(lTasks);
  lLog.Shutdown;
  lLog := nil;

  // --- UseStdErr demo ---------------------------------------------------
  // Same appender, but log lines go to stderr instead of stdout. Redirect
  // stderr to see only these lines in a file:
  //   SimpleConsole_appender.exe 2> errors.txt
  // Typical use: MCP servers (stdout reserved for JSON-RPC) and Unix
  // daemons where diagnostic output belongs on stderr.
  Writeln('--- next five lines are sent to STDERR ---');
  lErrLog := LoggerProBuilder
    .WriteToSimpleConsole
      .WithStdErr
      .Done
    .Build;
  lErrLog.Debug('to stderr: debug', 'STDERR');
  lErrLog.Info ('to stderr: info',  'STDERR');
  lErrLog.Warn ('to stderr: warn',  'STDERR');
  lErrLog.Error('to stderr: error', 'STDERR');
  lErrLog.Fatal('to stderr: fatal', 'STDERR');
  lErrLog.Shutdown;
  lErrLog := nil;
end.
