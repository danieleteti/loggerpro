unit LoggerProConfig;

interface

implementation

uses
  LoggerPro;

procedure SetupLogger;
begin
  TLogger.Initialize;
end;

initialization

SetupLogger;

end.
