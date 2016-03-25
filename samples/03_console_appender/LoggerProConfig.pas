unit LoggerProConfig;

interface

implementation

uses
  LoggerPro, LoggerPro.ConsoleAppender;

procedure SetupLogger;
begin
  TLogger.AddAppender(TLoggerProConsoleAppender.Create);
  TLogger.Initialize;
end;

initialization

SetupLogger;

end.
