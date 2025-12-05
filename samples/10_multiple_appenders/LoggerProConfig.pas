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
const
{$IFDEF DEBUG}
  LOG_LEVEL = TLogType.Debug;
{$ELSE}
  LOG_LEVEL = TLogType.Warning;
{$ENDIF}
begin
  // BuildLogWriter is the classic way to create a log writer.
  // The modern and recommended approach is to use LoggerProBuilder.
  //_Log := BuildLogWriter([TLoggerProFileAppender.Create,
  //  TLoggerProConsoleAppender.Create,
  //  TLoggerProOutputDebugStringAppender.Create], nil, LOG_LEVEL);
  _Log := LoggerProBuilder
    .WithDefaultLogLevel(LOG_LEVEL)
    .AddFileAppender
    .AddConsoleAppender
    .AddOutputDebugStringAppender
    .Build;
end;

initialization

SetupLogger;

end.
