unit LoggerProConfig;

interface

uses
  LoggerPro, LoggerPro.Renderers;

function Log: ILogWriter;

implementation

uses
  LoggerPro.ConsoleAppender, LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

_Log := LoggerProBuilder
  .WithDefaultRenderer(TLogItemRendererNoTag.Create)
  .WriteToConsole
    .WithLogLevel(TLogType.Debug)
    .Done
  .Build;

end.
