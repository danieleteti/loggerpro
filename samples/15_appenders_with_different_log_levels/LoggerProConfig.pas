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
var
  lFileAppender, lErrorsFileAppender, lOutputDebugStringAppender: ILogAppender;
begin
  lFileAppender := TLoggerProFileAppender.Create(5, 1000, 'logs');
  lFileAppender.SetLogLevel(TLogType.Info);

  lErrorsFileAppender := TLoggerProFileAppender.Create(5, 1000, 'logs_errors');
  lErrorsFileAppender.SetLogLevel(TLogType.Error);

  lOutputDebugStringAppender := TLoggerProOutputDebugStringAppender.Create;
  // default TLogType.Debug

  // BuildLogWriter is the classic way to create a log writer.
  // The modern and recommended approach is to use LoggerProBuilder.
  //_Log := BuildLogWriter([lFileAppender, lErrorsFileAppender, lOutputDebugStringAppender]);
  _Log := LoggerProBuilder
    .ConfigureFileAppender
      .WithLogsFolder('logs')
      .WithLogLevel(TLogType.Info)
      .Done
    .ConfigureFileAppender
      .WithLogsFolder('logs_errors')
      .WithLogLevel(TLogType.Error)
      .Done
    .AddOutputDebugStringAppender
    .Build;
end;

initialization

SetupLogger;

end.
