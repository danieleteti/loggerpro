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
  LoggerPro.MaskingAppender,
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
  _Log := LoggerProBuilder
    .WithDefaultLogLevel(LOG_LEVEL)
    .AddAppender(TLoggerProMaskingAppender.Create(TLoggerProFileAppender.Create))
    .AddAppender(TLoggerProMaskingAppender.Create(TLoggerProConsoleAppender.Create))
    .AddAppender(TLoggerProMaskingAppender.Create(TLoggerProOutputDebugStringAppender.Create))
    .Build;
end;

initialization

SetupLogger;

end.
