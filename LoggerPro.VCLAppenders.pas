unit LoggerPro.VCLAppenders;

interface

uses
  LoggerPro, System.Classes, Vcl.StdCtrls;

type
  TStringsLogAppender = class(TInterfacedObject, ILogAppender)
  private
    FStrings: TStrings;
  public
    constructor Create(aStrings: TStrings);
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
  end;

  TMemoLogAppender = class(TInterfacedObject, ILogAppender)
  private
    FMemo: TMemo;
  public
    constructor Create(aMemo: TMemo);
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
  end;

implementation

uses
  System.SysUtils, Winapi.Windows, Winapi.Messages;

{ TStringsLogAppender }
const
  DEFAULT_LOG_FORMAT = '%0:s [TID %1:-8d][%2:-10s] %3:s [%4:s]';

constructor TStringsLogAppender.Create(aStrings: TStrings);
begin
  inherited Create;
  FStrings := aStrings;
end;

procedure TStringsLogAppender.Setup;
begin
  TThread.Synchronize(nil,
    procedure
    begin
      FStrings.Clear;
    end);
end;

procedure TStringsLogAppender.TearDown;
begin
  // do nothing
end;

procedure TStringsLogAppender.WriteLog(const aLogItem: TLogItem);
var
  lText: string;
begin
  lText := Format(DEFAULT_LOG_FORMAT, [datetimetostr(aLogItem.TimeStamp),
    aLogItem.ThreadID, aLogItem.LogTypeAsString, aLogItem.LogMessage,
    aLogItem.LogTag]);
  TThread.Queue(nil,
    procedure
    begin
      FStrings.BeginUpdate;
      try
        FStrings.Add(lText);
      finally
        FStrings.EndUpdate;
      end;
    end);
end;

{ TMemoLogAppender }

constructor TMemoLogAppender.Create(aMemo: TMemo);
begin
  inherited Create;
  FMemo := aMemo;
end;

procedure TMemoLogAppender.Setup;
begin
  FMemo.Clear;
end;

procedure TMemoLogAppender.TearDown;
begin
  // do nothing
end;

procedure TMemoLogAppender.WriteLog(const aLogItem: TLogItem);
var
  lText: string;
begin
  lText := Format(DEFAULT_LOG_FORMAT, [datetimetostr(aLogItem.TimeStamp),
    aLogItem.ThreadID, aLogItem.LogTypeAsString, aLogItem.LogMessage,
    aLogItem.LogTag]);
  TThread.Queue(nil,
    procedure
    begin
      FMemo.Lines.BeginUpdate;
      try
        FMemo.Lines.Add(lText)
      finally
        FMemo.Lines.EndUpdate;
      end;
      SendMessage(FMemo.Handle, EM_SCROLLCARET, 0, 0);
    end);
end;

end.
