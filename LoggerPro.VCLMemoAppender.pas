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
	FLogFormat: string;
  public const
      { @abstract(Defines the default format string used by the @link(TLoggerProFileAppender).)
      The positional parameters are the followings:
      @orderedList(
      @itemSetNumber 0
      @item TimeStamp
      @item ThreadID
      @item LogType
      @item LogMessage
      @item LogTag
      )
    }
    DEFAULT_LOG_FORMAT = '%0:s [TID %1:-8d][%2:-10s] %3:s [%4:s]';
    constructor Create(aMemo: TMemo; aMaxLogLines: Word = 500; aLogFormat: string = DEFAULT_LOG_FORMAT); reintroduce;
    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); override;
  end;

implementation

uses
  System.SysUtils, Winapi.Windows, Winapi.Messages;

  { TVCLMemoLogAppender }

constructor TVCLMemoLogAppender.Create(aMemo: TMemo; aMaxLogLines: Word; aLogFormat: string);
begin
  inherited Create;
  FLogFormat := aLogFormat;
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
  lText := Format(FLogFormat, [datetimetostr(aLogItem.TimeStamp),
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
