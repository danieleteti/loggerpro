unit LoggerPro;
{<@abstract(Contains the LoggerPro core. INclude this if you want to create your own logger, otherwise you can use the global one using @link(LoggerPro.GlobalLogger.pas))
  @author(Daniele Teti) }

interface

uses
  System.Generics.Collections, System.SysUtils, System.Classes;

var
  DefaultLoggerProMainQueueSize: Cardinal = 100000;
  DefaultLoggerProAppenderQueueSize: Cardinal = 10000;

type
{$SCOPEDENUMS ON}
  TLogType = (Debug = 0, Info, Warning, Error);
  TLogErrorReason = (QueueFull);
  TLogErrorAction = (Skip, DisableAppender);

  { @abstract(Represent the single log item)
    Each call to some kind of log method is wrapped in a @link(TLogItem)
    instance and passed down the layour of LoggerPro. }
  TLogItem = class sealed
  protected
    constructor Create(aType: TLogType; aMessage: String;
                       aTag: String); overload;
    constructor Create(aType: TLogType; aMessage: String; aTag: String;
                       aTimeStamp: TDateTime; aThreadID: Cardinal); overload;
  private
    FType: TLogType;
    FMessage: string;
    FTag: string;
    FTimeStamp: TDateTime;
    FThreadID: Cardinal;
    function GetLogTypeAsString: String;
  public
    function Clone: TLogItem;
    {@abstract(The type of the log)
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

  TLoggerProAppenderErrorEvent = reference to procedure(const AppenderClassName
    : String; const aFailedLogItem: TLogItem; const Reason: TLogErrorReason;
    var Action: TLogErrorAction);

  TLoggerProEventsHandler = class sealed
  public
    OnAppenderError: TLoggerProAppenderErrorEvent;
  end;

  { @abstract(Interface implemented by all the classes used as appenders) }
  ILogAppender = interface
    ['{58AFB557-C594-4A4B-8DC9-0F13B37F60CB}']
    { @abstract(This method is internally called by LoggerPro to initialize the appender) }
    procedure Setup;
    { @abstract(This method is called at each log item represented by @link(TLogItem))
      The appender should be as-fast-as-it-can to handle the message, however
      each appender runs in a separated thread. }
    procedure WriteLog(const aLogItem: TLogItem);
    { @abstract(This method is internally called by LoggerPro to deinitialize the appender) }
    procedure TearDown;
    { @abstract(Enable or disable the log appender. Is used internally by LoggerPro but must be
      implemented by each logappender. A simple @code(if enabled then dolog) is enough }
    procedure SetEnabled(const Value: Boolean);
    { @abstract(Returns if the logappender is currently enabled or not. }
    function IsEnabled: Boolean;
  end;

  ELoggerPro = class(Exception)

  end;

  ILogWriter = interface
    ['{A717A040-4493-458F-91B2-6F6E2AFB496F}']
    procedure Debug(aMessage: String; aTag: String);
    procedure DebugFmt(aMessage: String; aParams: array of const; aTag: String);
    procedure Info(aMessage: String; aTag: String);
    procedure InfoFmt(aMessage: String; aParams: array of const; aTag: String);
    procedure Warn(aMessage: String; aTag: String);
    procedure WarnFmt(aMessage: String; aParams: array of const; aTag: String);
    procedure Error(aMessage: String; aTag: String);
    procedure ErrorFmt(aMessage: String; aParams: array of const; aTag: String);
    procedure Log(aType: TLogType; aMessage: String; aTag: String);
    function GetAppendersClassNames: TArray<String>;
    function GetAppenderStatus(const AppenderName: String): String;
  end;

  TLogAppenderList = TList<ILogAppender>;

  TLoggerThread = class(TThread)
  private type
    TAppenderDecorator = class
    private
      FAppenderQueue: TThreadedQueue<TLogItem>;
      FAppenderThread: TThread;
      FLogAppender: ILogAppender;
      FTerminated: Boolean;
      FFailsCount: Cardinal;
      FEnabled: Boolean;
      procedure SetEnabled(const Value: Boolean);
    public
      constructor Create(aAppender: ILogAppender); virtual;
      destructor Destroy; override;
      function WriteLog(const aLogItem: TLogItem): Boolean;
      property Queue: TThreadedQueue<TLogItem> read FAppenderQueue;
      property FailsCount: Cardinal read FFailsCount;
      property Enabled: Boolean read FEnabled write SetEnabled;
    end;
  private
    FQueue: TThreadedQueue<TLogItem>;
    FAppenders: TLogAppenderList;
    FEventsHandlers: TLoggerProEventsHandler;
    function BuildAppendersDecorator: TObjectList<TAppenderDecorator>;
    procedure DoOnAppenderError(const FailAppenderClassName: String;
      const aFailedLogItem: TLogItem; const aReason: TLogErrorReason;
      var aAction: TLogErrorAction);
    procedure SetEventsHandlers(const Value: TLoggerProEventsHandler);
  protected
    procedure Execute; override;
  public
    constructor Create(aQueue: TThreadedQueue<TLogItem>;
      aAppenders: TLogAppenderList);
    property EventsHandlers: TLoggerProEventsHandler read FEventsHandlers
      write SetEventsHandlers;
  end;

  TLogWriter = class(TInterfacedObject, ILogWriter)
  private
    FQueue: TThreadedQueue<TLogItem>;
    FLoggerThread: TLoggerThread;
    FLogAppenders: TLogAppenderList;
    FFreeAllowed: Boolean;
    FLogLevel: TLogType;
    procedure Initialize(aEventsHandler: TLoggerProEventsHandler);
    function GetAppendersClassNames: TArray<String>;
    function GetAppenderStatus(const AppenderName: String): String;
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

  { @abstract(Builds a new ILogWriter instance. Call this global function to start logging like a pro.)
    Here's a sample unit that you can use in your code
    @longcode(#
    unit LoggerProConfig;

    interface

    uses
    LoggerPro;

    function Log: ILogWriter;

    implementation

    uses
    LoggerPro.FileAppender;

    var
    _Log: ILogWriter;

    function Log: ILogWriter;
    begin
    Result := _Log;
    end;

    initialization

    //If you need other appenders, feel free to add them here in the array
    _Log := BuildLogWriter([TLoggerProFileAppender.Create(10, 5)]);

    end.
    #)

    Add this unit to your project, then when you need to use the logger, include
    the unit and call one of the followings:
    @unorderedlist(
    @item(Log.Debug('This is a debug message', 'tag1'))
    @item(Log.Info('This is an information message', 'tag1'))
    @item(Log.Warn('This is a warning message', 'tag1'))
    @item(Log.Error('This is an error message', 'tag1'))
    )
  }
function BuildLogWriter(aAppenders: array of ILogAppender;
  aEventsHandlers: TLoggerProEventsHandler = nil;
  aLogLevel: TLogType = TLogType.Debug): ILogWriter;

implementation

uses
  System.Types, LoggerPro.FileAppender;

function BuildLogWriter(aAppenders: array of ILogAppender;
  aEventsHandlers: TLoggerProEventsHandler; aLogLevel: TLogType): ILogWriter;
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
  TLogWriter(Result).Initialize(aEventsHandlers);
  while not TLogWriter(Result).FLoggerThread.Started do
  begin
    sleep(1); // wait the thread start
  end;
end;

{ TLogger.TLogWriter }

constructor TLogWriter.Create(aLogAppenders: TLogAppenderList;
  aLogLevel: TLogType);
begin
  inherited Create;
  FFreeAllowed := False;
  FQueue := TThreadedQueue<TLogItem>.Create(DefaultLoggerProMainQueueSize,
    1000, 200);
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

function TLogWriter.GetAppendersClassNames: TArray<String>;
var
  I: Cardinal;
begin
  TMonitor.Enter(FLogAppenders);
  try
    SetLength(Result, FLogAppenders.Count);
    for I := 0 to FLogAppenders.Count - 1 do
    begin
      Result[I] := TObject(FLogAppenders[0]).ClassName;
    end;
  finally
    TMonitor.Exit(FLogAppenders);
  end;
end;

function TLogWriter.GetAppenderStatus(const AppenderName: String): String;
var
  I: Integer;
begin
  TMonitor.Enter(FLogAppenders);
  try
    Result := '';
    for I := 0 to FLogAppenders.Count - 1 do
    begin
      if TObject(FLogAppenders[I]).ClassName.Equals(AppenderName) then
      begin
        if FLogAppenders[I].IsEnabled then
          Result := 'enabled'
        else
          Result := 'disabled';
        Exit;
      end;
    end;
  finally
    TMonitor.Exit(FLogAppenders);
  end;
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
  lLogItem: TLogItem;
begin
  if aType >= FLogLevel then
  begin
    lLogItem := TLogItem.Create(aType, aMessage, aTag);
    if FQueue.PushItem(lLogItem) = TWaitResult.wrTimeout then
    begin
      FreeAndNil(lLogItem);
      raise ELoggerPro.Create
        ('Main logs queue is full. Hints: Are there appenders? Are these appenders fast enough considering the log item production?');
    end;
  end;
end;

procedure TLogWriter.LogFmt(aType: TLogType; aMessage: String;
  aParams: array of const; aTag: String);
begin
  Log(aType, Format(aMessage, aParams), aTag);
end;

procedure TLogWriter.Initialize(aEventsHandler: TLoggerProEventsHandler);
begin
  FLoggerThread := TLoggerThread.Create(FQueue, FLogAppenders);
  FLoggerThread.EventsHandlers := aEventsHandler;
  FLoggerThread.Start;
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

function TLogItem.Clone: TLogItem;
begin
  Result := TLogItem.Create(FType, FMessage, FTag);
end;

constructor TLogItem.Create(aType: TLogType; aMessage, aTag: String);
begin
  Create(aType, aMessage, aTag, now, TThread.Current.ThreadID);
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

procedure TLoggerThread.DoOnAppenderError(const FailAppenderClassName: String;
  const aFailedLogItem: TLogItem; const aReason: TLogErrorReason;
  var aAction: TLogErrorAction);
begin
  if Assigned(FEventsHandlers) and (Assigned(FEventsHandlers.OnAppenderError))
  then
  begin
    FEventsHandlers.OnAppenderError(FailAppenderClassName, aFailedLogItem,
      aReason, aAction);
  end;
end;

procedure TLoggerThread.Execute;
var
  lQSize: Integer;
  lLogItem: TLogItem;
  I: Integer;
  lAppendersDecorators: TObjectList<TAppenderDecorator>;
  lAction: TLogErrorAction;
begin
  lAppendersDecorators := BuildAppendersDecorator;
  try
    while (not Terminated) or (FQueue.QueueSize > 0) do
    begin
      if FQueue.PopItem(lQSize, lLogItem) = TWaitResult.wrSignaled then
      begin
        if lLogItem <> nil then
        begin
          try
            for I := 0 to lAppendersDecorators.Count - 1 do
            begin
              if lAppendersDecorators[I].Enabled then
              begin
                if not lAppendersDecorators[I].WriteLog(lLogItem) then
                begin
                  lAction := TLogErrorAction.Skip; // default
                  DoOnAppenderError
                    (TObject(lAppendersDecorators[I].FLogAppender).ClassName,
                    lLogItem, TLogErrorReason.QueueFull, lAction);
                  case lAction of
                    TLogErrorAction.Skip:
                      begin
                        // just skip the message
                      end;
                    TLogErrorAction.DisableAppender:
                      begin
                        lAppendersDecorators[I].Enabled := False;
                      end;
                  end;
                end;
              end;
            end;
          finally
            lLogItem.Free;
          end;
        end;
      end;
    end;
  finally
    lAppendersDecorators.Free;
  end;
end;

procedure TLoggerThread.SetEventsHandlers(const Value: TLoggerProEventsHandler);
begin
  FEventsHandlers := Value;
end;

function TLoggerThread.BuildAppendersDecorator: TObjectList<TAppenderDecorator>;
var
  I: Integer;
begin
  Result := TObjectList<TAppenderDecorator>.Create(true);
  try
    for I := 0 to FAppenders.Count - 1 do
    begin
      Result.Add(TAppenderDecorator.Create(FAppenders[I]));
    end;
  except
    Result.Free;
    raise;
  end;
end;

constructor TLogItem.Create(aType: TLogType; aMessage, aTag: String;
  aTimeStamp: TDateTime; aThreadID: Cardinal);
begin
  inherited Create;
  FType := aType;
  FMessage := aMessage;
  FTag := aTag;
  FTimeStamp := aTimeStamp;
  FThreadID := aThreadID;
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

{ TLoggerThread.TAppenderDecorator }

constructor TLoggerThread.TAppenderDecorator.Create(aAppender: ILogAppender);
begin
  inherited Create;
  FFailsCount := 0;
  FLogAppender := aAppender;
  FAppenderQueue := TThreadedQueue<TLogItem>.Create
    (DefaultLoggerProAppenderQueueSize, 0, 500);
  FTerminated := False;
  Enabled := true; // use the property here, do not set FEnabled!
  FAppenderThread := TThread.CreateAnonymousThread(
    procedure
    var
      lLogItem: TLogItem;
    begin
      FLogAppender.Setup;
      try
        while (not FTerminated) or (FAppenderQueue.QueueSize > 0) do
        begin
          if FAppenderQueue.PopItem(lLogItem) = TWaitResult.wrSignaled then
          begin
            if lLogItem <> nil then
              try
                try
                  FLogAppender.WriteLog(lLogItem);
                except
                  Enabled := False;
                end;
              finally
                lLogItem.Free;
              end;
          end;
        end;
      finally
        FLogAppender.TearDown;
      end;
    end);
  FAppenderThread.FreeOnTerminate := False;
  FAppenderThread.Start;
end;

destructor TLoggerThread.TAppenderDecorator.Destroy;
begin
  FAppenderQueue.DoShutDown;
  FTerminated := true;
  FAppenderThread.WaitFor;
  FAppenderThread.Free;
  FAppenderQueue.Free;
  inherited;
end;

procedure TLoggerThread.TAppenderDecorator.SetEnabled(const Value: Boolean);
begin
  FEnabled := Value;
  FLogAppender.SetEnabled(FEnabled);
end;

function TLoggerThread.TAppenderDecorator.WriteLog(const aLogItem
  : TLogItem): Boolean;
var
  lLogItem: TLogItem;
begin
  lLogItem := aLogItem.Clone;
  Result := FAppenderQueue.PushItem(lLogItem) = TWaitResult.wrSignaled;
  if not Result then
  begin
    lLogItem.Free;
    FFailsCount := FFailsCount + 1
  end
  else
    FFailsCount := 0;
end;

end.
