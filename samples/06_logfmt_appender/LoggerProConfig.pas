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

// BuildLogWriter is the classic way to create a log writer.
// The modern and recommended approach is to use LoggerProBuilder.
//_Log := BuildLogWriter([
//  TLoggerProConsoleLogFmtAppender.Create,
//  TLoggerProLogFmtFileAppender.Create]);
_Log := LoggerProBuilder
  .AddAppender(TLoggerProConsoleLogFmtAppender.Create)
  .AddAppender(TLoggerProLogFmtFileAppender.Create)
  .Build;
if not IsConsole then
  AllocConsole;

end.
