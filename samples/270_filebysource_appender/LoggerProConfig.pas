unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  LoggerPro.FileBySourceAppender,
  LoggerPro.ConsoleAppender,
  LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

// TLoggerProFileBySourceAppender:
//   - One subfolder per "source" (taken from context key 'source')
//   - File pattern: <source>.<tag>.<YYYYMMDD>.<NN>.log
//   - Rotation: daily + by size (WithMaxFileSizeInKB)
//   - Retention: WithRetainDays (deletes files older than N days)
//
// Example output tree:
//   logs/
//     ClientA/
//       ClientA.ORDERS.20260513.00.log
//       ClientA.PAYMENTS.20260513.00.log
//     ClientB/
//       ClientB.API.20260513.00.log
//     default/
//       default.main.20260513.00.log   (logs without 'source' context)
//
_Log := LoggerProBuilder
  .WithDefaultTag('main')

  .WriteToFileBySource
    .WithLogsFolder(TPath.Combine(ExtractFilePath(ParamStr(0)), 'logs'))
    .WithMaxFileSizeInKB(1000)     // rotate at 1 MB
    .WithRetainDays(30)            // keep 30 days of logs
    .WithDefaultSource('default')  // used when no 'source' in context
    .Done

  .WriteToSimpleConsole.Done

  .Build;

finalization

_Log := nil;

end.
