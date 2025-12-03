unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.FileAppender,
  LoggerPro.SimpleConsoleAppender;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

_Log := BuildLogWriter([
  TLoggerProFileAppender.Create,
  TLoggerProSimpleConsoleAppender.Create
]);

finalization

_Log := nil;

end.
