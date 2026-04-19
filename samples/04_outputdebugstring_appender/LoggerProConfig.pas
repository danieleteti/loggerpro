unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.OutputDebugStringAppender, LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

_Log := LoggerProBuilder
  .WriteToOutputDebugString.Done
  .Build;

end.
