unit LoggerPro.MaskingAppender;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  LoggerPro,
  LoggerPro.Proxy;

type
  TLoggerProMaskingAppender = class(TLoggerProAppenderBase, ILogAppender, ILogAppenderProxy)
  private
    FInnerAppender: ILogAppender;
    FPhoneRegex: TRegEx;
    FPasswordRegex: TRegEx;
    function GetInternalAppender: ILogAppender;
    function MaskMessage(const AMessage: string): string;
  public
    constructor Create(AInnerAppender: ILogAppender); reintroduce;
    destructor Destroy; override;
    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); override;
    property InternalAppender: ILogAppender read GetInternalAppender;
  end;

implementation

{ TLoggerProMaskingAppender }

constructor TLoggerProMaskingAppender.Create(AInnerAppender: ILogAppender);
begin
  inherited Create;
  FInnerAppender := AInnerAppender;
  FPhoneRegex := TRegEx.Create('1([3-9])(\d{4})(\d{4})', [roCompiled]);
  FPasswordRegex := TRegEx.Create('(password\s*=\s*)\S+', [roCompiled, roIgnoreCase]);
end;

destructor TLoggerProMaskingAppender.Destroy;
begin
  FInnerAppender := nil;
  inherited;
end;

function TLoggerProMaskingAppender.GetInternalAppender: ILogAppender;
begin
  Result := FInnerAppender;
end;

function TLoggerProMaskingAppender.MaskMessage(const AMessage: string): string;
begin
  Result := AMessage;
  Result := FPhoneRegex.Replace(Result, '1$1****$3');
  Result := FPasswordRegex.Replace(Result, '$1****');
end;

procedure TLoggerProMaskingAppender.Setup;
begin
  FInnerAppender.Setup;
end;

procedure TLoggerProMaskingAppender.TearDown;
begin
  FInnerAppender.TearDown;
end;

procedure TLoggerProMaskingAppender.WriteLog(const aLogItem: TLogItem);
var
  MaskedLogItem: TLogItem;
  MaskedMessage: string;
begin
  MaskedMessage := MaskMessage(aLogItem.LogMessage);
  if MaskedMessage = aLogItem.LogMessage then
    FInnerAppender.WriteLog(aLogItem)
  else
  begin
    MaskedLogItem := TLogItem.Create(
      aLogItem.LogType,
      MaskedMessage,
      aLogItem.LogTag,
      aLogItem.TimeStamp,
      aLogItem.ThreadID,
      aLogItem.Context
    );
    try
      FInnerAppender.WriteLog(MaskedLogItem);
    finally
      MaskedLogItem.Free;
    end;
  end;
end;

end.
