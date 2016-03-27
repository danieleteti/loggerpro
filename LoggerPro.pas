unit LoggerPro;
{<@abstract(The main unit you should always include)
@author(Daniele Teti)}

interface

uses
  System.Generics.Collections, System.SysUtils, System.Classes;

type
{$SCOPEDENUMS ON}
  TLogType = (Debug, Info, Warning, Error);

  { @abstract(Represent the single log item)
    Each call to some kind of log method is wrapped in a @link(TLogItem)
    instance and passed down the layour of LoggerPro. }
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
    {@abstract(The type of the log)
    Log can be one of the following types:
    @unorderedlist(
    @item(DEBUG)
    @item(INFO)
    @item(WARNING)
    @item(ERROR)
    )}
    property LogType: TLogType read FType;
    {@abstract(The text of the log message)}
    property LogMessage: String read FMessage;
    {@abstract(The tag of the log message)}
    property LogTag: String read FTag;
    {@abstract(The timestamp when the @link(TLogItem) is generated)}
    property TimeStamp: TDateTime read FTimeStamp;
    {@abstract(The IDof the thread which generated the log item)}
    property ThreadID: Cardinal read FThreadID;
    {@abstract(The type of the log converted in string)}
    property LogTypeAsString: String read GetLogTypeAsString;
  end;

  { @abstract(Interface implemented by all the classes used as appenders) }
  ILogAppender = interface
    ['{58AFB557-C594-4A4B-8DC9-0F13B37F60CB}']
    { @abstract(This method is internally called by LoggerPro to initialize the appender) }
    procedure Setup;
    { @abstract(This method is called at each log item represented by @link(TLogItem))
      The appender should be as-fast-as-it-can to handle the message because this method call is synchronous between all the appenders.
      For instance, if you are implementing an email appender, you cannot send email directly in this method because the call will slow down the
      log main queue dequeuing. You should implement an internal queue so that the main loop is free to go though the other appenders. }
    procedure WriteLog(const aLogItem: TLogItem);
    { @abstract(This method is internally called by LoggerPro to deinitialize the appender) }
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

    ILogWriter = interface
      ['{A717A040-4493-458F-91B2-6F6E2AFB496F}']
      procedure Debug(aMessage: String; aTag: String);
      procedure Info(aMessage: String; aTag: String);
      procedure Warn(aMessage: String; aTag: String);
      procedure Error(aMessage: String; aTag: String);
      procedure Log(aType: TLogType; aMessage: String; aTag: String);
    end;

    TLogWriter = class(TInterfacedObject, ILogWriter)
    private
      FQueue: TThreadedQueue<TLogItem>;
      FLoggerThread: TLoggerThread;
      FLogAppenders: TLogAppenderList;
      FFreeAllowed: Boolean;
      procedure SetupAppenders;
      procedure Start;
      procedure TearDownAppenders;
      constructor Create(aLogAppenders: TLogAppenderList);
    public
      destructor Destroy; override;
      procedure Debug(aMessage: String; aTag: String);
      procedure Info(aMessage: String; aTag: String);
      procedure Warn(aMessage: String; aTag: String);
      procedure Error(aMessage: String; aTag: String);
      procedure Log(aType: TLogType; aMessage: String; aTag: String);
    end;
  private
    class var ConfiguredAppenders: TLogger.TLogAppenderList;
    class var Instance: ILogWriter;

  end;

function Log: TLogger.ILogWriter;

implementation

uses
  System.Types, LoggerPro.FileAppender;

function Log: TLogger.ILogWriter;
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
  Instance := nil;
end;

class procedure TLogger.Initialize;
begin
  if ConfiguredAppenders.Count = 0 then
  begin
    ConfiguredAppenders.Add(TLoggerProFileAppender.Create);
  end;

  Instance := TLogWriter.Create(ConfiguredAppenders);
  TLogWriter(Instance).SetupAppenders;
  TLogWriter(Instance).Start;
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
  FFreeAllowed := False;
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
