unit LoggerProConfig;

interface

implementation

uses
  LoggerPro, LoggerPro.FileAppender;

procedure SetupLogger;
begin
  TLogger.AddAppender(TLoggerProFileAppender.Create(10, 5));
  TLogger.Initialize;
end;

initialization

SetupLogger;

end.
