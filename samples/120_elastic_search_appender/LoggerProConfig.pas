unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.FileAppender,
  LoggerPro.Builder,
  System.Net.HttpClient,
  System.SysUtils,
  LoggerPro.ElasticSearchAppender;

var
  _Log: ILogWriter;
  _Events: TLoggerProEventsHandler;
  _RESTAppender: ILogAppender;

function Log: ILogWriter;
begin
  Result := _Log;
end;

initialization

_Events := TLoggerProEventsHandler.Create;
_Events.OnAppenderError :=
    procedure(const AppenderClassName: string; const aFailedLogItem: TLogItem; const Reason: TLogErrorReason; var Action: TLogErrorAction)
  begin
    Action := TLogErrorAction.SkipNewest;
  end;

DefaultLoggerProAppenderQueueSize := 100;
{$IF Defined(MSWINDOWS)}
_RESTAppender := TLoggerProElasticSearchAppender.Create('http://localhost', 9200, 'loggerpro');
{$ENDIF}
{$IF Defined(Android)}
_RESTAppender := TLoggerProElasticSearchAppender.Create('http://192.168.1.6:8080/api/logs');
{$ENDIF}
TLoggerProElasticSearchAppender(_RESTAppender).OnSendError :=
    procedure(const Sender: TObject; const aLogItem: TLogItem; const aException: Exception; var aRetryCount: Integer)
  begin
    // retries to send log for 5 times, then discard the logitem
    if aRetryCount = 5 then
    begin
      aRetryCount := 0
    end
    else
    begin
      Inc(aRetryCount);
    end;
  end;

// BuildLogWriter is the classic way to create a log writer.
// The modern and recommended approach is to use LoggerProBuilder.
//_Log := BuildLogWriter([_RESTAppender, TLoggerProFileAppender.Create], _Events);
_Log := LoggerProBuilder
  .WriteToAppender(_RESTAppender)
  .WriteToFile.Done
  .Build;

finalization

_Log := nil;
_Events.Free;

end.
