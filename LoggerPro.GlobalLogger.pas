unit LoggerPro.GlobalLogger;
{<@abstract(Contains the global logger as a thread safe singleton)
  Use the global logger for fast&dirty logging, but consider to use your own
  instance of @link(ILogWriter) (created using @link(BuildLogWriter)) for all your serious logging needs.
 @author(Daniele Teti - d.teti@bittime.it)
}

interface

uses
  LoggerPro;
{@abstract(The global logger. Just uses @link(Logger.GlobalLogger) and you can start to log using @code(Log) function.)
The global logger is configured with a @link(TLoggerProFileAppender) using default settings.
}
function Log: ILogWriter;

implementation

uses
  LoggerPro.FileAppender;

var
  _Logger: ILogWriter;
  _Lock: TObject = nil;

function Log: ILogWriter;
begin
  if _Logger = nil then
  begin
    TMonitor.Enter(_Lock);
    try
      if _Logger = nil then // double check
      begin
        _Logger := BuildLogWriter([TLoggerProFileAppender.Create(5, 1000,
          [TFileAppenderOption.LogsInTheSameFolder])]);
      end;
    finally
      TMonitor.Exit(_Lock);
    end;
  end;
  Result := _Logger;
end;

initialization

_Lock := TObject.Create;

finalization

_Lock.Free;

end.
