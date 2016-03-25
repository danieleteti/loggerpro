unit LoggerPro.OutputDebugStringAppender;

interface

uses
  LoggerPro, System.Classes;

type
  TLoggerProOutputDebugStringAppender = class(TInterfacedObject, ILogAppender)
  private
    FStrings: TStrings;
    FModuleName: string;
  public
    constructor Create;
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
  end;

implementation

uses
  System.SysUtils, Winapi.Windows, Winapi.Messages, System.IOUtils;

{ TStringsLogAppender }
const
  DEFAULT_LOG_FORMAT = '%0:s [TID %1:-8d][%2:-10s] %3:s [%4:s]';

constructor TLoggerProOutputDebugStringAppender.Create;
begin
  inherited Create;
end;

procedure TLoggerProOutputDebugStringAppender.Setup;
begin
  FModuleName := TPath.GetFileName(GetModuleName(HInstance));
end;

procedure TLoggerProOutputDebugStringAppender.TearDown;
begin
  // do nothing
end;

procedure TLoggerProOutputDebugStringAppender.WriteLog(const aLogItem: TLogItem);
var
  lLog: string;
begin
  lLog := Format('(' + FModuleName + ') => ' + DEFAULT_LOG_FORMAT, [datetimetostr(aLogItem.TimeStamp),
    aLogItem.ThreadID, aLogItem.LogTypeAsString, aLogItem.LogMessage,
    aLogItem.LogTag]);
  OutputDebugString(PChar(lLog));
end;

end.
