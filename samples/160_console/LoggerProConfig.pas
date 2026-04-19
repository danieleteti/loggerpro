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

finalization

_Log := nil;

end.
