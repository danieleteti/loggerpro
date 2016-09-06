unit LoggerPro.VCLMemoAppender;
{ <@abstract(The unit to include if you want to use the @link(TVCLMemoLogAppender))
  @author(Daniele Teti) }

interface

uses
  LoggerPro, System.Classes, Vcl.StdCtrls;

type
  { @abstract(Appends formatted @link(TLogItem) to a TMemo in a VCL application) }
  TVCLMemoLogAppender = class(TLoggerProAppenderBase)
  private
    FMemo: TMemo;
    FMaxLogLines: Word;
  public
    constructor Create(aMemo: TMemo; aMaxLogLines: Word = 500); reintroduce;
    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); override;
  end;

implementation

uses
  System.SysUtils, Winapi.Windows, Winapi.Messages;

const
  DEFAULT_LOG_FORMAT = '%0:s [TID %1:-8d][%2:-10s] %3:s [%4:s]';

  { TVCLMemoLogAppender }

constructor TVCLMemoLogAppender.Create(aMemo: TMemo; aMaxLogLines: Word);
begin
  inherited Create;
  FMemo := aMemo;
  FMaxLogLines := aMaxLogLines;
end;

procedure TVCLMemoLogAppender.Setup;
begin
  TThread.Synchronize(nil,
    procedure
    begin
      FMemo.Clear;
    end);
end;

procedure TVCLMemoLogAppender.TearDown;
begin
  // do nothing
end;

procedure TVCLMemoLogAppender.WriteLog(const aLogItem: TLogItem);
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
        if FMemo.Lines.Count = FMaxLogLines then
          FMemo.Lines.Delete(0);
        FMemo.Lines.Add(lText)
      finally
        FMemo.Lines.EndUpdate;
      end;
      SendMessage(FMemo.Handle, EM_SCROLLCARET, 0, 0);
    end);
end;

end.
