unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.FileAppender,
  LoggerPro.ConsoleAppender,
  LoggerPro.OutputDebugStringAppender,
  LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

procedure SetupLogger;
begin
  // BuildLogWriter is the classic way to create a log writer.
  // The modern and recommended approach is to use LoggerProBuilder.
  //_Log := BuildLogWriter([
  //  TLoggerProFileAppender.Create,
  //  TLoggerProConsoleAppender.Create,
  //  TLoggerProOutputDebugStringAppender.Create], nil, [TLogType.Debug, TLogType.Error, TLogType.Warning]);
  _Log := LoggerProBuilder
    .WriteToFile.Done
    .WriteToConsole.Done
    .WriteToOutputDebugString.Done
    .Build;
end;

initialization

SetupLogger;

end.
