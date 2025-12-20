unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.JSONLFileAppender,
  LoggerPro.FileAppender,
  LoggerPro.ConsoleAppender,
  LoggerPro.Renderers;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

// This sample demonstrates structured logging with context
// using both JSONL and LogFmt appenders
_Log := BuildLogWriter([
  // JSONL appender - context is included as a nested JSON object
  TLoggerProJSONLFileAppender.Create(5, 1000, '', 'context_logging'),

  // Console appender with LogFmt renderer - context is appended as key=value pairs
  TLoggerProConsoleAppender.Create(TLogItemRendererLogFmt.Create)
]);

end.
