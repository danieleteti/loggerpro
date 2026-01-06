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
  // ============================================================================
  // LoggerPro 2.0 - Builder API (Recommended)
  // ============================================================================
  // This sample demonstrates:
  //   - Multiple appenders (File, Console, OutputDebugString)
  //   - Conditional log level based on DEBUG/RELEASE build
  //   - WithDefaultLogLevel to set minimum level for all appenders
  //
  _Log := LoggerProBuilder
    .WithDefaultLogLevel(LOG_LEVEL)
    .WriteToFile.Done
    .WriteToConsole.Done
    .WriteToOutputDebugString.Done
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
