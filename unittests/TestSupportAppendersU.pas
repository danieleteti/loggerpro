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
  public
    constructor Create(aSetupCallback, aTearDownCallback: TProc;
      aWriteLogCallback: TProc<TLogItem>);
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
  end;

  TMyVerySlowAppender = class(TInterfacedObject, ILogAppender)
  private
    FDelay: Cardinal;
  public
    constructor Create(const aDelay: Cardinal);
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
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

procedure TMyVerySlowAppender.Setup;
begin

end;

procedure TMyVerySlowAppender.TearDown;
begin

end;

procedure TMyVerySlowAppender.WriteLog(const aLogItem: TLogItem);
begin
  Sleep(FDelay);
end;

end.
