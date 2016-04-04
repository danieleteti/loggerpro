unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.ConsoleAppender, System.SysUtils;

type
  TMyCustomAppender = class(TInterfacedObject, ILogAppender)
  private
    FEnabled: Boolean;
  public
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
    procedure SetEnabled(const Value: Boolean);
    function IsEnabled: Boolean;

  end;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

{ TMyCustomAppender }

function TMyCustomAppender.IsEnabled: Boolean;
begin
  Result := FEnabled;
end;

procedure TMyCustomAppender.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
end;

procedure TMyCustomAppender.Setup;
begin
  //
end;

procedure TMyCustomAppender.TearDown;
begin
  //
end;

procedure TMyCustomAppender.WriteLog(const aLogItem: TLogItem);
begin
  // uncomment this to see what happend if an appender raise an exception
  // raise Exception.Create('Kill LoggerPro');

  // uncomment this to see what happend if an appender is slow
  Sleep(2000);
  WriteLn('[THE BAD APPENDER] ' + aLogItem.LogMessage);
end;

initialization

_Log := BuildLogWriter([TLoggerProConsoleAppender.Create,
  TMyCustomAppender.Create])

end.
