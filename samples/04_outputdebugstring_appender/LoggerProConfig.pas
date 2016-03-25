unit LoggerProConfig;

interface

implementation

uses
  LoggerPro, LoggerPro.OutputDebugStringAppender;

procedure SetupLogger;
begin
  TLogger.AddAppender(TLoggerProOutputDebugStringAppender.Create);
  TLogger.Initialize;
end;

initialization

SetupLogger;

end.
