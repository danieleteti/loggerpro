unit LoggerProConfig;

interface

uses
  LoggerPro, LoggerPro.Renderers;

function Log: ILogWriter;

implementation

uses
  LoggerPro.ConsoleAppender,
  LoggerPro.FileAppender,
  LoggerPro.Builder,
  Winapi.Windows;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization



LoggerPro.Renderers.gDefaultLogItemRenderer := TLogItemRendererNoTag; //optional

_Log := LoggerProBuilder
  .WriteToAppender(TLoggerProConsoleLogFmtAppender.Create)
  .WriteToAppender(TLoggerProLogFmtFileAppender.Create)
  .Build;
if not IsConsole then
  AllocConsole;

end.
