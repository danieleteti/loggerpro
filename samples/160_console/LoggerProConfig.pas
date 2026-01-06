unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  LoggerPro.FileAppender,
  LoggerPro.ConsoleAppender,
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
// Key features demonstrated:
//   - WriteToFile / WriteToSimpleConsole - appender configuration
//   - WithLogsFolder - customize log file location
//   - WithDefaultTag - set default tag for all log calls
//   - WithMinimumLevel - filter out lower-priority messages globally
//
_Log := LoggerProBuilder
  // Set default tag for all log messages (can be overridden per-call)
  .WithDefaultTag('main')

  // Optional: Set minimum log level (e.g., skip Debug in production)
  // .WithMinimumLevel(TLogType.Info)

  // File appender with custom logs folder
  .WriteToFile
    .WithLogsFolder(TPath.Combine(ExtractFilePath(ParamStr(0)), 'logs'))
    .Done

  // Simple console appender (colored output)
  .WriteToSimpleConsole.Done

  .Build;

// ============================================================================
// LoggerPro 1.x - Legacy API (Still supported but deprecated)
// ============================================================================
// The old BuildLogWriter function still works for backward compatibility.
// Migration to Builder API is recommended for new projects.
//
// _Log := BuildLogWriter([
//   TLoggerProFileAppender.Create,
//   TLoggerProSimpleConsoleAppender.Create
// ]);

finalization

_Log := nil;

end.
