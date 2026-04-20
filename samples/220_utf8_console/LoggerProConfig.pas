unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.ConsoleAppender,
  LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

_Log := LoggerProBuilder
  .WriteToConsole
    .WithUTF8Output
    .WithMinimumLevel(TLogType.Debug)
    .Done
  .Build;

end.
