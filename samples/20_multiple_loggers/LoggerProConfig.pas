unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.FileAppender,
  LoggerPro.ConsoleAppender,
  LoggerPro.OutputDebugStringAppender;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

procedure SetupLogger;
begin
  _Log := BuildLogWriter([TLoggerProFileAppender.Create,
    TLoggerProConsoleAppender.Create,
    TLoggerProOutputDebugStringAppender.Create]);
end;

initialization

SetupLogger;

end.
