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
var
  lFileAppender, lConsoleAppender, lOutputDebugStringAppender: ILogAppender;
begin
  lFileAppender := TLoggerProFileAppender.Create;
  lFileAppender.SetLogLevel(TLogType.Info);

  lConsoleAppender := TLoggerProConsoleAppender.Create;
  lConsoleAppender.SetLogLevel(TLogType.Warning);

  lOutputDebugStringAppender := TLoggerProOutputDebugStringAppender.Create;
  // default TLogType.Debug

  _Log := BuildLogWriter([lFileAppender, lConsoleAppender, lOutputDebugStringAppender]);
end;

initialization

SetupLogger;

end.
