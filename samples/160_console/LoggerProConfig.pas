unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  LoggerPro.FileAppender,
  LoggerPro.ConsoleAppender,
  LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

// BuildLogWriter is the classic way to create a log writer.
// The modern and recommended approach is to use LoggerProBuilder.
//_Log := BuildLogWriter([
//  TLoggerProFileAppender.Create,
//  TLoggerProSimpleConsoleAppender.Create
//]);
_Log := LoggerProBuilder
  .WriteToFile
    .WithLogsFolder(TPath.Combine(ExtractFilePath(ParamStr(0)), 'logs'))
    .Done
  .WriteToSimpleConsole.Done
  .Build;

finalization

_Log := nil;

end.
