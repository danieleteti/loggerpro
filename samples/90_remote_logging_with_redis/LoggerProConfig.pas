unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.RedisAppender, LoggerPro.Builder, Redis.Client, WinApi.Windows;

var
  _Log: ILogWriter;
  _Events: TLoggerProEventsHandler;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

_Events := TLoggerProEventsHandler.Create;
_Events.OnAppenderError := procedure(
    const AppenderClassName: string;
    const aFailedLogItem: TLogItem;
    const Reason: TLogErrorReason;
    var Action: TLogErrorAction)
  begin
    Action := TLogErrorAction.SkipNewest;
    WinApi.Windows.Beep(800, 500);
  end;

DefaultLoggerProAppenderQueueSize := 10;
// BuildLogWriter is the classic way to create a log writer.
// The modern and recommended approach is to use LoggerProBuilder.
//_Log := BuildLogWriter([
//  TLoggerProRedisAppender.Create(TRedisClient.Create('127.0.0.1', 6379))
//  ], _Events);
_Log := LoggerProBuilder
  .WriteToAppender(TLoggerProRedisAppender.Create(TRedisClient.Create('127.0.0.1', 6379)))
  .Build;

finalization

_Log := nil;
_Events.Free;

end.
