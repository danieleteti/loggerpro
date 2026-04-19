unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

procedure SetupLogger;
begin
  // Two file appenders writing to different folders, each with its own
  // minimum log level, plus an OutputDebugString appender.
  _Log := LoggerProBuilder
    .WriteToFile
      .WithLogsFolder('logs')
      .WithLogLevel(TLogType.Info)
      .Done
    .WriteToFile
      .WithLogsFolder('logs_errors')
      .WithLogLevel(TLogType.Error)
      .Done
    .WriteToOutputDebugString.Done
    .Build;
end;

initialization

SetupLogger;

end.
