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

// ============================================================================
// LoggerPro 2.0 - Builder API (Recommended)
// ============================================================================
// The Builder API provides a fluent, Serilog-style configuration.
// Each appender is configured with .WriteTo* followed by options and .Done
//
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

// ============================================================================
// LoggerPro 1.x - Legacy API (Still supported but deprecated)
// ============================================================================
// The old BuildLogWriter function still works for backward compatibility.
// Migration to Builder API is recommended for new projects.
//
// _Log := BuildLogWriter([
//   // JSONL appender - context is included as a nested JSON object
//   TLoggerProJSONLFileAppender.Create(5, 1000, '', 'context_logging'),
//   // Console appender with LogFmt renderer - context is appended as key=value pairs
//   TLoggerProConsoleAppender.Create(TLogItemRendererLogFmt.Create)
// ]);

end.
