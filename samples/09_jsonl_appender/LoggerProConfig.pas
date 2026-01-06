unit LoggerProConfig;

interface

uses
  LoggerPro,
  LoggerPro.Proxy;

function Log: ILogWriter;

implementation

uses
  LoggerPro.FileAppender,
  LoggerPro.JSONLFileAppender,
  LoggerPro.Builder,
  System.SysUtils;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

  DefaultLoggerProMainQueueSize := 5;
  DefaultLoggerProAppenderQueueSize := 5;

  // ============================================================================
  // LoggerPro 2.0 - Builder API (Recommended)
  // ============================================================================
  // The JSONL (JSON Lines) appender writes logs in a structured JSON format,
  // one JSON object per line. This format is ideal for:
  //   - Log aggregation tools (ELK stack, Splunk, Loki, etc.)
  //   - Machine parsing and analysis
  //   - Preserving structured context (WithProperty key-value pairs)
  //
  // The TLoggerProJSONLFileAppender has its defaults defined as follows:
  //   DEFAULT_FILENAME_FORMAT = '{module}.{number}.{tag}.jsonl.log';
  //   DEFAULT_MAX_BACKUP_FILE_COUNT = 5;
  //   DEFAULT_MAX_FILE_SIZE_KB = 1000;

  _Log := LoggerProBuilder
    .WriteToJSONLFile
      .WithMaxBackupFiles(10)
      .WithMaxFileSizeInKB(5)
      .WithLogsFolder('..\logs')
      .Done
    .Build;

  // ============================================================================
  // LoggerPro 1.x - Legacy API (Still supported but deprecated)
  // ============================================================================
  // _Log := BuildLogWriter([
  //   TLoggerProJSONLFileAppender.Create(
  //     10,  // max backup files
  //     5,   // max file size KB
  //     '..\logs',
  //     TLoggerProJSONLFileAppender.DEFAULT_FILENAME_FORMAT,
  //     TEncoding.UTF8
  //   )
  // ]);

end.
