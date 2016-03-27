unit LoggerPro;
{ <@abstract(The main unit you should always include)
  @author(Daniele Teti) }

interface

uses
  System.Generics.Collections, System.SysUtils, System.Classes;

type
{$SCOPEDENUMS ON}
  TLogType = (Debug = 0, Info, Warning, Error);

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
    { @abstract(The type of the log)
      Log can be one of the following types:
      @unorderedlist(
      @item(DEBUG)
      @item(INFO)
      @item(WARNING)
      @item(ERROR)
      ) }
    property LogType: TLogType read FType;
    { @abstract(The text of the log message) }
    property LogMessage: String read FMessage;
    { @abstract(The tag of the log message) }
    property LogTag: String read FTag;
    { @abstract(The timestamp when the @link(TLogItem) is generated) }
    property TimeStamp: TDateTime read FTimeStamp;
    { @abstract(The IDof the thread which generated the log item) }
    property ThreadID: Cardinal read FThreadID;
    { @abstract(The type of the log converted in string) }
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

  ILogWriter = interface
    ['{A717A040-4493-458F-91B2-6F6E2AFB496F}']
    procedure Debug(aMessage: String; aTag: String);
    procedure DebugFmt(aMessage: String; aParams: array of const; aTag: String);
    procedure Info(aMessage: String; aTag: String);
    procedure Warn(aMessage: String; aTag: String);
    procedure Error(aMessage: String; aTag: String);
    procedure Log(aType: TLogType; aMessage: String; aTag: String);
  end;

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

  TLogWriter = class(TInterfacedObject, ILogWriter)
  private
    FQueue: TThreadedQueue<TLogItem>;
    FLoggerThread: TLoggerThread;
    FLogAppenders: TLogAppenderList;
    FFreeAllowed: Boolean;
    FLogLevel: TLogType;
    procedure SetupAppenders;
    procedure Initialize;
    procedure TearDownAppenders;
  public
    constructor Create(aLogLevel: TLogType = TLogType.Debug); overload;
    constructor Create(aLogAppenders: TLogAppenderList;
      aLogLevel: TLogType = TLogType.Debug); overload;
    destructor Destroy; override;
    procedure Debug(aMessage: String; aTag: String);
    procedure DebugFmt(aMessage: string; aParams: array of TVarRec;
      aTag: string);

    procedure Info(aMessage: String; aTag: String);
    procedure InfoFmt(aMessage: string; aParams: array of TVarRec;
      aTag: string);

    procedure Warn(aMessage: String; aTag: String);
    procedure WarnFmt(aMessage: string; aParams: array of TVarRec;
      aTag: string);

    procedure Error(aMessage: String; aTag: String);
    procedure ErrorFmt(aMessage: string; aParams: array of TVarRec;
      aTag: string);

    procedure Log(aType: TLogType; aMessage: String; aTag: String);
    procedure LogFmt(aType: TLogType; aMessage: String; aParams: array of const;
      aTag: String);
  end;

  { @abstract(Entry point for the user code. Call this global function to access the LoggerPro engine.)
    This function can called also before call TLogger.Initialize, however in such cases it implements a NULL object, so
    no log will be handled, but your code will not raise exceptions. }
function BuildLogWriter(aAppenders: array of ILogAppender;
  aLogLevel: TLogType = TLogType.Debug): ILogWriter;

implementation

uses
  System.Types, LoggerPro.FileAppender;

function BuildLogWriter(aAppenders: array of ILogAppender; aLogLevel: TLogType)
  : ILogWriter;
var
  lLogAppenders: TLogAppenderList;
  lLogAppender: ILogAppender;
begin
  lLogAppenders := TLogAppenderList.Create;
  for lLogAppender in aAppenders do
  begin
    lLogAppenders.Add(lLogAppender);
  end;
  Result := TLogWriter.Create(lLogAppenders, aLogLevel);
  TLogWriter(Result).Initialize;
  while not TLogWriter(Result).FLoggerThread.Started do
  begin
    sleep(1); // wait the thread start
  end;
end;

{ TLogger.TLogWriter }

procedure TLogWriter.SetupAppenders;
var
  I: Integer;
begin
  for I := 0 to FLogAppenders.Count - 1 do
  begin
    FLogAppenders[I].Setup;
  end;
end;

constructor TLogWriter.Create(aLogAppenders: TLogAppenderList;
  aLogLevel: TLogType);
begin
  inherited Create;
  FFreeAllowed := False;
  FQueue := TThreadedQueue<TLogItem>.Create(1000, INFINITE, 200);
  FLogAppenders := aLogAppenders;
  FLogLevel := aLogLevel;
end;

constructor TLogWriter.Create(aLogLevel: TLogType);
begin
  Create(TLogAppenderList.Create, aLogLevel);
end;

procedure TLogWriter.Debug(aMessage, aTag: String);
begin
  Log(TLogType.Debug, aMessage, aTag);
end;

procedure TLogWriter.DebugFmt(aMessage: string; aParams: array of TVarRec;
  aTag: string);
begin
  LogFmt(TLogType.Debug, aMessage, aParams, aTag);
end;

destructor TLogWriter.Destroy;
begin
  FQueue.DoShutDown;
  FLoggerThread.Terminate;
  FLoggerThread.WaitFor;
  FLoggerThread.Free;
  TearDownAppenders;
  FQueue.Free;
  FLogAppenders.Free;
  inherited;
end;

procedure TLogWriter.Error(aMessage, aTag: String);
begin
  Log(TLogType.Error, aMessage, aTag);
end;

procedure TLogWriter.ErrorFmt(aMessage: string; aParams: array of TVarRec;
  aTag: string);
begin
  LogFmt(TLogType.Error, aMessage, aParams, aTag);
end;

procedure TLogWriter.Info(aMessage, aTag: String);
begin
  Log(TLogType.Info, aMessage, aTag);
end;

procedure TLogWriter.InfoFmt(aMessage: string; aParams: array of TVarRec;
  aTag: string);
begin
  LogFmt(TLogType.Info, aMessage, aParams, aTag);
end;

procedure TLogWriter.Log(aType: TLogType; aMessage, aTag: String);
var
  LLogItem: TLogItem;
begin
  if aType >= FLogLevel then
  begin
    LLogItem := TLogItem.Create(aType, aMessage, aTag);
    if FQueue.PushItem(LLogItem) = TWaitResult.wrTimeout then
      raise ELoggerPro.Create('Log queue is full');
  end;
end;

procedure TLogWriter.LogFmt(aType: TLogType; aMessage: String;
  aParams: array of const; aTag: String);
begin
  Log(aType, Format(aMessage, aParams), aTag);
end;

procedure TLogWriter.Initialize;
begin
  SetupAppenders;
  FLoggerThread := TLoggerThread.Create(FQueue, FLogAppenders);
  FLoggerThread.Start;
end;

procedure TLogWriter.TearDownAppenders;
var
  I: Integer;
begin
  for I := FLogAppenders.Count - 1 downto 0 do
  begin
    FLogAppenders[I].TearDown;
  end;
end;

procedure TLogWriter.Warn(aMessage, aTag: String);
begin
  Log(TLogType.Warning, aMessage, aTag);
end;

procedure TLogWriter.WarnFmt(aMessage: string; aParams: array of TVarRec;
  aTag: string);
begin
  LogFmt(TLogType.Warning, aMessage, aParams, aTag);
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

constructor TLoggerThread.Create(aQueue: TThreadedQueue<TLogItem>;
  aAppenders: TLogAppenderList);
begin
  FQueue := aQueue;
  FAppenders := aAppenders;
  inherited Create(true);
  FreeOnTerminate := False;
end;

procedure TLoggerThread.Execute;
var
  lQSize: Integer;
  LLogItem: TLogItem;
  I: Integer;
begin
  while (not Terminated) or (FQueue.QueueSize > 0) do
  begin
    if FQueue.PopItem(lQSize, LLogItem) = TWaitResult.wrSignaled then
    begin
      if LLogItem <> nil then
      begin
        try
          for I := 0 to FAppenders.Count - 1 do
          begin
            FAppenders[I].WriteLog(LLogItem);
          end;
        finally
          LLogItem.Free;
        end;
      end;
    end;
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
