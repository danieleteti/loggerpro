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
begin
  // BuildLogWriter is the classic way to create a log writer.
  // The modern and recommended approach is to use LoggerProBuilder.
  //lLog := BuildLogWriter([TLoggerProSimpleConsoleAppender.Create]);
  lLog := LoggerProBuilder
    .WriteToSimpleConsole.Done
    .Build;

  //Use the following line to enable LogFmt log format
  //lLog := BuildLogWriter([TLoggerProSimpleConsoleLogFmtAppender.Create]);

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
end.
