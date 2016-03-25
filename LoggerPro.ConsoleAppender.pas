unit LoggerPro.ConsoleAppender;

interface

uses
  LoggerPro, System.Classes, Vcl.StdCtrls;

type
  TLoggerProConsoleAppender = class(TInterfacedObject, ILogAppender)
  protected
    procedure SetColor(const Color: Integer);
  public
    constructor Create;
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
  end;

implementation

uses
  System.SysUtils, Winapi.Windows, Winapi.Messages;

const
  DEFAULT_LOG_FORMAT = '%0:s [TID %1:-8d][%2:-10s] %3:s [%4:s]';
  { FOREGROUND COLORS - CAN BE COMBINED }
  FOREGROUND_BLUE = 1; { text color blue. }
  FOREGROUND_GREEN = 2; { text color green }
  FOREGROUND_RED = 4; { text color red }
  FOREGROUND_INTENSITY = 8; { text color is intensified }
  { BACKGROUND COLORS - CAN BE COMBINED }
  BACKGROUND_BLUE = $10; { background color blue }
  BACKGROUND_GREEN = $20; { background color green }
  BACKGROUND_RED = $40; { background color red. }
  BACKGROUND_INTENSITY = $80; { background color is intensified }

constructor TLoggerProConsoleAppender.Create;
begin
  inherited Create;
end;

procedure TLoggerProConsoleAppender.SetColor(const Color: Integer);
begin
  SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), Color);
end;

procedure TLoggerProConsoleAppender.Setup;
begin
  TThread.Synchronize(nil,
    procedure
    begin
      if GetStdHandle(STD_OUTPUT_HANDLE) = 0 then
        AllocConsole;
    end);
end;

procedure TLoggerProConsoleAppender.TearDown;
begin
  // do nothing
end;

procedure TLoggerProConsoleAppender.WriteLog(const aLogItem: TLogItem);
var
  lText: string;
  lColor: Integer;
begin
  case aLogItem.LogType of
    TLogType.Debug:
      lColor := FOREGROUND_GREEN;
    TLogType.Info:
      lColor := FOREGROUND_BLUE or FOREGROUND_GREEN or FOREGROUND_RED;
    TLogType.Warning:
      lColor := FOREGROUND_GREEN or FOREGROUND_BLUE;
    TLogType.Error:
      lColor := FOREGROUND_RED or FOREGROUND_INTENSITY;
  end;
  lText := Format(DEFAULT_LOG_FORMAT, [datetimetostr(aLogItem.TimeStamp),
    aLogItem.ThreadID, aLogItem.LogTypeAsString, aLogItem.LogMessage,
    aLogItem.LogTag]);
  TThread.Queue(nil,
    procedure
    begin
      SetColor(lColor);
      Writeln(lText);
    end);
end;

end.
