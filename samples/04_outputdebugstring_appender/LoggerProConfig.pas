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

// BuildLogWriter is the classic way to create a log writer.
// The modern and recommended approach is to use LoggerProBuilder.
//_Log := BuildLogWriter([TLoggerProOutputDebugStringAppender.Create])
_Log := LoggerProBuilder
  .WriteToOutputDebugString.Done
  .Build;

end.
