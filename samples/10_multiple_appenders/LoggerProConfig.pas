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
  // ============================================================================
  // LoggerPro 2.0 - Builder API with MaskingAppender Decorator
  // ============================================================================
  // This sample demonstrates:
  //   - Multiple appenders (File, Console, OutputDebugString)
  //   - MaskingAppender decorator for sensitive data masking
  //   - Phone numbers: 13812345678 -> 138****5678
  //   - Passwords: password=secret -> password=****
  //   - Conditional log level based on DEBUG/RELEASE build
  //
  _Log := LoggerProBuilder
    .WithDefaultLogLevel(LOG_LEVEL)
    .WriteToAppender(TLoggerProMaskingAppender.Create(TLoggerProFileAppender.Create))
    .WriteToConsole.Done
    .WriteToOutputDebugString.Done
    .Build;

  // ============================================================================
  // LoggerPro 1.x - Legacy API with MaskingAppender (Still supported)
  // ============================================================================
  // _Log := BuildLogWriter([
  //   TLoggerProMaskingAppender.Create(TLoggerProFileAppender.Create),
  //   TLoggerProConsoleAppender.Create,
  //   TLoggerProOutputDebugStringAppender.Create
  // ], nil, LOG_LEVEL);
end;

initialization

SetupLogger;

end.
