unit TestSupportAppendersU;

interface

uses
  LoggerPro, System.SysUtils;

type
  TMyAppender = class(TInterfacedObject, ILogAppender)
  private
    FSetupCallback: TProc;
    FTearDownCallback: TProc;
    FWriteLogCallback: TProc<TLogItem>;
    FEnabled: Boolean;
  public
    constructor Create(aSetupCallback, aTearDownCallback: TProc;
      aWriteLogCallback: TProc<TLogItem>);
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
    procedure SetEnabled(const Value: Boolean);
    function IsEnabled: Boolean;
  end;

  TMyVerySlowAppender = class(TInterfacedObject, ILogAppender)
  private
    FDelay: Cardinal;
    FEnabled: Boolean;
  public
    constructor Create(const aDelay: Cardinal);
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
    procedure SetEnabled(const Value: Boolean);
    function IsEnabled: Boolean;
  end;

implementation

{ TMyAppender }

constructor TMyAppender.Create(aSetupCallback, aTearDownCallback: TProc;
  aWriteLogCallback: TProc<TLogItem>);
begin
  inherited Create;
  FSetupCallback := aSetupCallback;
  FTearDownCallback := aTearDownCallback;
  FWriteLogCallback := aWriteLogCallback;
end;

function TMyAppender.IsEnabled: Boolean;
begin
  Result := FEnabled;
end;

procedure TMyAppender.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
end;

procedure TMyAppender.Setup;
begin
  FSetupCallback();
end;

procedure TMyAppender.TearDown;
begin
  FTearDownCallback();
end;

procedure TMyAppender.WriteLog(const aLogItem: TLogItem);
begin
  FWriteLogCallback(aLogItem);
end;

{ TMyVerySlowAppender }

constructor TMyVerySlowAppender.Create(const aDelay: Cardinal);
begin
  FDelay := aDelay;
end;

function TMyVerySlowAppender.IsEnabled: Boolean;
begin
  Result := FEnabled;
end;

procedure TMyVerySlowAppender.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
end;

procedure TMyVerySlowAppender.Setup;
begin

end;

procedure TMyVerySlowAppender.TearDown;
begin

end;

procedure TMyVerySlowAppender.WriteLog(const aLogItem: TLogItem);
begin
  if FEnabled then
    Sleep(FDelay);
end;

end.
