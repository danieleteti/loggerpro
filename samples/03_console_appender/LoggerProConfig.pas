unit LoggerProConfig;

interface

implementation

uses
  LoggerPro, LoggerPro.ConsoleAppender;

procedure SetupLogger;
begin
  { The TLoggerProConsoleAppender logs to the console using 4 different colors for the different log level. }
  TLogger.AddAppender(TLoggerProConsoleAppender.Create);
  TLogger.Initialize;
end;

initialization

SetupLogger;

end.
