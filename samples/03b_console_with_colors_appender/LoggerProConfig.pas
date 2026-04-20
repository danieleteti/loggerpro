unit LoggerProConfig;

interface

uses
  LoggerPro, LoggerPro.Renderers;

function Log: ILogWriter;

implementation

uses
  LoggerPro.ConsoleAppender, LoggerPro.Builder, LoggerPro.AnsiColors;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

// Default rich scheme: dim timestamp + thread ID, colored level word,
// cyan tag, green keys + yellow values. Use .WithColorScheme(MyScheme)
// to customize.
_Log := LoggerProBuilder
  .WriteToConsole
    .WithMinimumLevel(TLogType.Debug)
    .WithColors
    .Done
  .Build;

end.
