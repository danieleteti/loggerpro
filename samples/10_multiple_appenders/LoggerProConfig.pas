unit LoggerProConfig;

interface

implementation

uses
  LoggerPro,
  LoggerPro.FileAppender,
  LoggerPro.ConsoleAppender,
  LoggerPro.OutputDebugStringAppender;

procedure SetupLogger;
begin
  TLogger.AddAppender(TLoggerProFileAppender.Create);
  TLogger.AddAppender(TLoggerProConsoleAppender.Create);
  TLogger.AddAppender(TLoggerProOutputDebugStringAppender.Create);
  TLogger.Initialize;
end;

initialization

SetupLogger;

end.
