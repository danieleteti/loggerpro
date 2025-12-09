unit LoggerProConfig;

interface

uses
  LoggerPro, LoggerPro.Renderers;

function Log: ILogWriter;

implementation

uses
  LoggerPro.ConsoleAppender, LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

// BuildLogWriter is the classic way to create a log writer.
//_Log := BuildLogWriter([TLoggerProConsoleAppender.Create]);

// The modern and recommended approach is to use LoggerProBuilder.
_Log := LoggerProBuilder
  .WithDefaultRenderer(TLogItemRendererNoTag.Create)
  .ConfigureConsoleAppender
    .WithLogLevel(TLogType.Debug)
    .Done
  .Build;

end.
