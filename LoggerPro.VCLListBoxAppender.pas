unit LoggerPro.VCLListBoxAppender;
{ <@abstract(The unit to include if you want to use the @link(TVCLMemoLogAppender))
  @author(Daniele Teti) }

interface

uses
  LoggerPro,
  System.Classes,
  Vcl.StdCtrls;

type
  { @abstract(Appends formatted @link(TLogItem) to a TMemo in a VCL application) }
  TVCLListBoxAppender = class(TLoggerProAppenderBase)
  private
    FLB: TListBox;
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
    constructor Create(aLB: TListBox; aMaxLogLines: Word = 500; aLogFormat: string = DEFAULT_LOG_FORMAT); reintroduce;
    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); override;
  end;

implementation

uses
  System.SysUtils,
  Winapi.Windows,
  Winapi.Messages;

{ TVCLMemoLogAppender }

constructor TVCLListBoxAppender.Create(aLB: TListBox; aMaxLogLines: Word; aLogFormat: string);
begin
  inherited Create;
  FLogFormat := aLogFormat;
  FLB := aLB;
  FMaxLogLines := aMaxLogLines;
end;

procedure TVCLListBoxAppender.Setup;
begin
  TThread.Synchronize(nil,
    procedure
    begin
      FLB.Clear;
    end);
end;

procedure TVCLListBoxAppender.TearDown;
begin
  // do nothing
end;

procedure TVCLListBoxAppender.WriteLog(const aLogItem: TLogItem);
var
  lText: string;
begin
  lText := Format(FLogFormat, [datetimetostr(aLogItem.TimeStamp), aLogItem.ThreadID, aLogItem.LogTypeAsString,
    aLogItem.LogMessage, aLogItem.LogTag]);
  TThread.Queue(nil,
    procedure
    var
      Lines: integer;
    begin
      FLB.Items.BeginUpdate;
      try
        Lines := FLB.Items.Count;
        if Lines > FMaxLogLines then
          FLB.Items.Delete(0);
        FLB.AddItem(lText, nil)
      finally
        FLB.Items.EndUpdate;
      end;
      FLB.ItemIndex := FLB.Items.Count - 1;
    end);
end;

end.
