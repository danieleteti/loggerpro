unit LoggerProConfig;

interface

implementation

uses
  LoggerPro, LoggerPro.FileAppender;

procedure SetupLogger;
begin
  { The TLoggerProFileAppender has its defaults defined as follows:
    DEFAULT_LOG_FORMAT = '%0:s [TID %1:-8d][%2:-10s] %3:s [%4:s]';
    DEFAULT_MAX_BACKUP_FILE_COUNT = 5;
    DEFAULT_MAX_FILE_SIZE_KB = 1000;

    You can override these dafaults passing parameters to the constructor
  }

  TLogger.AddAppender(TLoggerProFileAppender.Create(10, 5));
  TLogger.Initialize;
end;

initialization

SetupLogger;

end.
