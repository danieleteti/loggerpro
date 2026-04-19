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
  LoggerPro.Renderers,
  LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

_Log := LoggerProBuilder
  // JSONL appender - context is included as a nested JSON object
  // Great for log aggregation tools (ELK, Splunk, etc.)
  .WriteToJSONLFile
    .WithFileBaseName('context_logging')
    .WithMaxBackupFiles(5)
    .WithMaxFileSizeInKB(1000)
    .Done
  // Console appender with LogFmt renderer
  // Context is appended as key=value pairs (human-readable structured format)
  .WriteToConsole
    .WithRenderer(TLogItemRendererLogFmt.Create)
    .Done
  .Build;

end.
