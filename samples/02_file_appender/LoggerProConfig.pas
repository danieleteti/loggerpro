unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.FileAppender,
  LoggerPro.Builder,
  LoggerPro.Renderers;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

// The TLoggerProFileAppender has its defaults defined as follows:
//   DEFAULT_MAX_BACKUP_FILE_COUNT = 5;
//   DEFAULT_MAX_FILE_SIZE_KB = 1000;
//
// You can override these defaults using the Builder pattern.
// Here are some configuration examples:
//
// Creates log with default settings:
//   _Log := LoggerProBuilder
//     .WriteToFile.Done
//     .Build;
//
// Create logs in the exe's same folder. Backupset = 10, max size for single file 5k:
//   _Log := LoggerProBuilder
//     .WriteToFile
//       .WithMaxBackupFiles(10)
//       .WithMaxFileSizeInKB(5)
//       .Done
//     .Build;
//
// Creates logs in the ..\ folder using the NoTag renderer (context is always included).
// The FilteringFileAppender selects the 'TAG1' and 'TAG2' log messages into a separate file.

_Log := LoggerProBuilder
  .WriteToFile
    .WithMaxBackupFiles(10)
    .WithMaxFileSizeInKB(5)
    .WithLogsFolder('..')
    .WithRenderer(TLogItemRendererNoTag.Create)
    .Done
  .WriteToFilteredAppender(TLoggerProSimpleFileAppender.Create(10, 5, '..\..'))
    .WithFilter(
      function(ALogItem: TLogItem): Boolean
      begin
        Result := (ALogItem.LogTag = 'TAG1') or (ALogItem.LogTag = 'TAG2');
      end)
    .Done
  .Build;

end.
