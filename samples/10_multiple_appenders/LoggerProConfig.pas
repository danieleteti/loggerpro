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
  // LoggerPro 2.0 - Builder API (Recommended)
  // ============================================================================
  // This sample demonstrates:
  //   - Multiple appenders (File, Console, OutputDebugString)
  //   - Conditional log level based on DEBUG/RELEASE build
  //   - WithDefaultLogLevel to set minimum level for all appenders
  //   - Using TLoggerProMaskingAppender to mask sensitive data
  //
  // TLoggerProMaskingAppender is a decorator that masks sensitive data:
  //   - Masks 11-digit Chinese phone numbers (e.g., 138****5678)
  //   - Masks password values (e.g., password=****)
  //   - Regular expressions are pre-compiled in constructor for performance
  //
  _Log := LoggerProBuilder
    .WithDefaultLogLevel(LOG_LEVEL)
    .AddAppender(TLoggerProMaskingAppender.Create(TLoggerProFileAppender.Create))
    .AddAppender(TLoggerProMaskingAppender.Create(TLoggerProConsoleAppender.Create))
    .AddAppender(TLoggerProMaskingAppender.Create(TLoggerProOutputDebugStringAppender.Create))
    .Build;

  // ============================================================================
  // LoggerPro 1.x - Legacy API (Still supported but deprecated)
  // ============================================================================
  // _Log := BuildLogWriter([
  //   TLoggerProFileAppender.Create,
  //   TLoggerProConsoleAppender.Create,
  //   TLoggerProOutputDebugStringAppender.Create
  // ], nil, LOG_LEVEL);
end;

initialization

SetupLogger;

end.
