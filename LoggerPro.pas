unit LoggerPro;

interface

uses
  System.Generics.Collections, System.SysUtils, System.Classes;

type
{$SCOPEDENUMS ON}
  TLogType = (Debug, Info, Warning, Error);

  TLogItem = class sealed
    constructor Create(aType: TLogType; aMessage: String; aTag: String);
  private
    FType: TLogType;
    FMessage: string;
    FTag: string;
    FTimeStamp: TDateTime;
    FThreadID: Cardinal;
    function GetLogTypeAsString: String;
  public
    property LogType: TLogType read FType;
    property LogMessage: String read FMessage;
    property LogTag: String read FTag;
    property TimeStamp: TDateTime read FTimeStamp;
    property ThreadID: Cardinal read FThreadID;
    property LogTypeAsString: String read GetLogTypeAsString;
  end;

  ILogAppender = interface
    ['{58AFB557-C594-4A4B-8DC9-0F13B37F60CB}']
    procedure Setup;
    procedure WriteLog(const aLogItem: TLogItem);
    procedure TearDown;
  end;

  ELoggerPro = class(Exception)

  end;

  TLogger = class sealed
  public
    class constructor Create;
    class destructor Destroy;
    class procedure AddAppender(aILogAppender: ILogAppender);
    class procedure Initialize;
    class procedure ResetAppenders;
  private type
    TLogAppenderList = TList<ILogAppender>;

    TLoggerThread = class(TThread)
    private
      FQueue: TThreadedQueue<TLogItem>;
      FAppenders: TLogAppenderList;
    public
      constructor Create(aQueue: TThreadedQueue<TLogItem>;
        aAppenders: TLogAppenderList);
      procedure Execute; override;
    end;

    TLogWriter = class
    private
      FQueue: TThreadedQueue<TLogItem>;
      FLoggerThread: TLoggerThread;
      FLogAppenders: TLogAppenderList;
      procedure SetupAppenders;
      procedure Start;
      procedure TearDownAppenders;
    public
      constructor Create(aLogAppenders: TLogAppenderList);
      destructor Destroy; override;
      procedure Debug(aMessage: String; aTag: String);
      procedure Info(aMessage: String; aTag: String);
      procedure Warn(aMessage: String; aTag: String);
      procedure Error(aMessage: String; aTag: String);
      procedure Log(aType: TLogType; aMessage: String; aTag: String);
    end;
  private
    class var ConfiguredAppenders: TLogger.TLogAppenderList;
    class var Instance: TLogWriter;

  end;

function Log: TLogger.TLogWriter;

implementation

uses
  System.Types, LoggerPro.FileAppender;

function Log: TLogger.TLogWriter;
begin
  Result := TLogger.Instance;
end;

{ TLoggerConfig }

class procedure TLogger.AddAppender(aILogAppender: ILogAppender);
begin
  ConfiguredAppenders.Add(aILogAppender);
end;

class constructor TLogger.Create;
begin
  ConfiguredAppenders := TLogAppenderList.Create;
end;

class destructor TLogger.Destroy;
begin
  Instance.Free;
end;

class procedure TLogger.Initialize;
begin
  if ConfiguredAppenders.Count = 0 then
  begin
    ConfiguredAppenders.Add(TLoggerProFileAppender.Create);
  end;

  Instance := TLogWriter.Create(ConfiguredAppenders);
  Instance.SetupAppenders;
  Instance.Start;
end;

class procedure TLogger.ResetAppenders;
begin
  ConfiguredAppenders.Clear;
end;

{ TLogger.TLogWriter }

procedure TLogger.TLogWriter.SetupAppenders;
var
  I: Integer;
begin
  for I := 0 to FLogAppenders.Count - 1 do
  begin
    FLogAppenders[I].Setup;
  end;
end;

constructor TLogger.TLogWriter.Create(aLogAppenders: TLogAppenderList);
begin
  inherited Create;
  FQueue := TThreadedQueue<TLogItem>.Create(1000, INFINITE, 200);
  FLogAppenders := aLogAppenders;
end;

procedure TLogger.TLogWriter.Debug(aMessage, aTag: String);
begin
  Log(TLogType.Debug, aMessage, aTag);
end;

destructor TLogger.TLogWriter.Destroy;
begin
  FLoggerThread.Free;
  TearDownAppenders;
  FQueue.Free;
  FLogAppenders.Free;
  inherited;
end;

procedure TLogger.TLogWriter.Error(aMessage, aTag: String);
begin
  Log(TLogType.Error, aMessage, aTag);
end;

procedure TLogger.TLogWriter.Info(aMessage, aTag: String);
begin
  Log(TLogType.Info, aMessage, aTag);
end;

procedure TLogger.TLogWriter.Log(aType: TLogType; aMessage, aTag: String);
var
  LLogItem: TLogItem;
begin
  LLogItem := TLogItem.Create(aType, aMessage, aTag);
  if FQueue.PushItem(LLogItem) = TWaitResult.wrTimeout then
    raise ELoggerPro.Create('Log queue is full');
end;

procedure TLogger.TLogWriter.Start;
begin
  FLoggerThread := TLoggerThread.Create(FQueue, FLogAppenders);
  FLoggerThread.Start;
end;

procedure TLogger.TLogWriter.TearDownAppenders;
var
  I: Integer;
begin
  for I := FLogAppenders.Count - 1 downto 0 do
  begin
    FLogAppenders[I].TearDown;
  end;
end;

procedure TLogger.TLogWriter.Warn(aMessage, aTag: String);
begin
  Log(TLogType.Warning, aMessage, aTag);
end;

{ TLogger.TLogItem }

constructor TLogItem.Create(aType: TLogType; aMessage, aTag: String);
begin
  inherited Create;
  FType := aType;
  FMessage := aMessage;
  FTag := aTag;
  FTimeStamp := Now;
  FThreadID := TThread.Current.ThreadID;
end;

{ TLogger.TLoggerThread }

constructor TLogger.TLoggerThread.Create(aQueue: TThreadedQueue<TLogItem>;
  aAppenders: TLogAppenderList);
begin
  FQueue := aQueue;
  FAppenders := aAppenders;
  inherited Create(true);
  FreeOnTerminate := False;
end;

procedure TLogger.TLoggerThread.Execute;
var
  lQSize: Integer;
  LLogItem: TLogItem;
  I: Integer;
begin
  while not Terminated do
  begin
    if FQueue.PopItem(lQSize, LLogItem) = TWaitResult.wrSignaled then
      try
        for I := 0 to FAppenders.Count - 1 do
        begin
          FAppenders[I].WriteLog(LLogItem);
        end;
      finally
        LLogItem.Free;
      end
  end;
end;

function TLogItem.GetLogTypeAsString: String;
begin
  case FType of
    TLogType.Debug:
      Exit('DEBUG');
    TLogType.Info:
      Exit('INFO');
    TLogType.Warning:
      Exit('WARNING');
    TLogType.Error:
      Exit('ERROR');
  else
    raise ELoggerPro.Create('Invalid LogType');
  end;
end;

end.
