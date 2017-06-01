unit LoggerPro;
{ <@abstract(Contains the LoggerPro core. Include this if you want to create your own logger, otherwise you can use the global one using @link(LoggerPro.GlobalLogger.pas))
  @author(Daniele Teti) }

{$SCOPEDENUMS ON}

interface

uses
  System.Generics.Collections, System.SysUtils, System.Classes;

var
  DefaultLoggerProMainQueueSize: Cardinal = 1000;
  DefaultLoggerProAppenderQueueSize: Cardinal = 1000;

type
  TLogType = (Debug = 0, Info, Warning, Error);
  TLogErrorReason = (QueueFull);
  TLogErrorAction = (SkipNewest, DiscardOlder);

  { @abstract(Represent the single log item)
    Each call to some kind of log method is wrapped in a @link(TLogItem)
    instance and passed down the layour of LoggerPro. }
  TLogItem = class sealed
  private
    FType: TLogType;
    FMessage: string;
    FTag: string;
    FTimeStamp: TDateTime;
    FThreadID: Cardinal;
    function GetLogTypeAsString: string;
  public
    constructor Create(aType: TLogType; aMessage: string;
      aTag: string); overload;
    constructor Create(aType: TLogType; aMessage: string; aTag: string;
      aTimeStamp: TDateTime; aThreadID: Cardinal); overload;

    function Clone: TLogItem;
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
    property LogMessage: string read FMessage;
    { @abstract(The tag of the log message) }
    property LogTag: string read FTag;
    { @abstract(The timestamp when the @link(TLogItem) is generated) }
    property TimeStamp: TDateTime read FTimeStamp;
    { @abstract(The IDof the thread which generated the log item) }
    property ThreadID: Cardinal read FThreadID;
    { @abstract(The type of the log converted in string) }
    property LogTypeAsString: string read GetLogTypeAsString;
  end;

  TLoggerProAppenderErrorEvent = reference to procedure(const AppenderClassName
    : string; const aFailedLogItem: TLogItem; const Reason: TLogErrorReason;
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
    // { @abstract(Enable or disable the log appender. Is used internally by LoggerPro but must be
    // implemented by each logappender. A simple @code(if enabled then dolog) is enough }
    // procedure SetEnabled(const Value: Boolean);
    // { @abstract(Returns if the logappender is currently enabled or not. }
    // function IsEnabled: Boolean;
    { @abstract(Set a custom log level for this appender. This value must be lower than the global LogWriter log level. }
    procedure SetLogLevel(const Value: TLogType);
    { @abstract(Get the loglevel for the appender. }
    function GetLogLevel: TLogType;
    { @abstract(If the appender is disabled, this method is called at each new
      logitem. This method should not raise exceptions and should try to restart the appender
      at specified time and only if some appropriate seconds/miutes are elapsed between the
      LastErrorTimestamp. }
    procedure TryToRestart(var Restarted: Boolean);

    procedure SetLastErrorTimeStamp(const LastErrorTimeStamp: TDateTime);
    function GetLastErrorTimeStamp: TDateTime;
    property LastErrorTimeStamp: TDateTime read GetLastErrorTimeStamp write SetLastErrorTimeStamp;
  end;

  ELoggerPro = class(Exception)

  end;

  TAppenderQueue = class(TThreadedQueue<TLogItem>)
  end;

  ILogWriter = interface
    ['{A717A040-4493-458F-91B2-6F6E2AFB496F}']
    procedure Debug(aMessage: string; aTag: string);
    procedure DebugFmt(aMessage: string; aParams: array of const; aTag: string);
    procedure Info(aMessage: string; aTag: string);
    procedure InfoFmt(aMessage: string; aParams: array of const; aTag: string);
    procedure Warn(aMessage: string; aTag: string);
    procedure WarnFmt(aMessage: string; aParams: array of const; aTag: string);
    procedure Error(aMessage: string; aTag: string);
    procedure ErrorFmt(aMessage: string; aParams: array of const; aTag: string);
    procedure Log(aType: TLogType; aMessage: string; aTag: string);
    function GetAppendersClassNames: TArray<string>;
    function GetAppenderStatus(const AppenderName: string): string;
    function GetAppenders(const Index: Integer): ILogAppender;
    property Appenders[const index: Integer]: ILogAppender read GetAppenders;
    function AppendersCount(): Integer;
  end;

  TLogAppenderList = TList<ILogAppender>;

  TAppenderThread = class(TThread)
  private
    FLogAppender: ILogAppender;
    FAppenderQueue: TAppenderQueue;
    FFailing: Boolean;
    procedure SetFailing(const Value: Boolean);
  protected
    procedure Execute; override;

  type
    TAppenderStatus = (BeforeSetup, Running, WaitAfterFail, ToRestart, BeforeTearDown);
  public
    constructor Create(aLogAppender: ILogAppender; aAppenderQueue: TAppenderQueue);
    property Failing: Boolean read FFailing write SetFailing;
  end;

  TLoggerThread = class(TThread)
  private type
    TAppenderAdapter = class
    private
      FAppenderQueue: TAppenderQueue;
      FAppenderThread: TAppenderThread;
      FLogAppender: ILogAppender;
      FTerminated: Boolean;
      FFailsCount: Cardinal;
    public
      constructor Create(aAppender: ILogAppender); virtual;
      destructor Destroy; override;
      function EnqueueLog(const aLogItem: TLogItem): Boolean;
      property Queue: TAppenderQueue read FAppenderQueue;
      property FailsCount: Cardinal read FFailsCount;
      function GetLogLevel: TLogType;
    end;
  private
    FQueue: TThreadedQueue<TLogItem>;
    FAppenders: TLogAppenderList;
    FEventsHandlers: TLoggerProEventsHandler;
    function BuildAppendersDecorator: TObjectList<TAppenderAdapter>;
    procedure DoOnAppenderError(const FailAppenderClassName: string;
      const aFailedLogItem: TLogItem; const aReason: TLogErrorReason;
      var aAction: TLogErrorAction);
    procedure SetEventsHandlers(const Value: TLoggerProEventsHandler);
  protected
    procedure Execute; override;
  public
    constructor Create(aAppenders: TLogAppenderList);
    destructor Destroy; override;

    property EventsHandlers: TLoggerProEventsHandler read FEventsHandlers
      write SetEventsHandlers;
    property LogWriterQueue: TThreadedQueue<TLogItem> read FQueue;
  end;

  TLogWriter = class(TInterfacedObject, ILogWriter)
  private
    FLoggerThread: TLoggerThread;
    FLogAppenders: TLogAppenderList;
    FFreeAllowed: Boolean;
    FLogLevel: TLogType;
    procedure Initialize(aEventsHandler: TLoggerProEventsHandler);
    function GetAppendersClassNames: TArray<string>;
    function GetAppenderStatus(const AppenderName: string): string;
  public
    function GetAppenders(const Index: Integer): ILogAppender;
    function AppendersCount(): Integer;
    constructor Create(aLogLevel: TLogType = TLogType.Debug); overload;
    constructor Create(aLogAppenders: TLogAppenderList;
      aLogLevel: TLogType = TLogType.Debug); overload;
    destructor Destroy; override;
    procedure Debug(aMessage: string; aTag: string);
    procedure DebugFmt(aMessage: string; aParams: array of TVarRec;
      aTag: string);

    procedure Info(aMessage: string; aTag: string);
    procedure InfoFmt(aMessage: string; aParams: array of TVarRec;
      aTag: string);

    procedure Warn(aMessage: string; aTag: string);
    procedure WarnFmt(aMessage: string; aParams: array of TVarRec;
      aTag: string);

    procedure Error(aMessage: string; aTag: string);
    procedure ErrorFmt(aMessage: string; aParams: array of TVarRec;
      aTag: string);

    procedure Log(aType: TLogType; aMessage: string; aTag: string);
    procedure LogFmt(aType: TLogType; aMessage: string; aParams: array of const;
      aTag: string);
  end;

  TLoggerProAppenderBase = class abstract(TInterfacedObject, ILogAppender)
  private
    FLogLevel: TLogType;
    FEnabled: Boolean;
    FLastErrorTimeStamp: TDateTime;
  public
    constructor Create; virtual;
    procedure Setup; virtual; abstract;
    procedure WriteLog(const aLogItem: TLogItem); virtual; abstract;
    procedure TearDown; virtual; abstract;
    procedure TryToRestart(var Restarted: Boolean); virtual;
    procedure SetLogLevel(const Value: TLogType);
    function GetLogLevel: TLogType; inline;
    procedure SetLastErrorTimeStamp(const Value: TDateTime);
    function GetLastErrorTimeStamp: TDateTime;
    property LogLevel: TLogType read GetLogLevel write SetLogLevel;
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
  System.Types, LoggerPro.FileAppender, System.SyncObjs, System.DateUtils;

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

  // while not TLogWriter(Result).FLoggerThread.Started do
  // begin
  // sleep(1); // wait the thread start
  // end;
end;

{ TLogger.TLogWriter }

function TLogWriter.AppendersCount: Integer;
begin
  Result := Self.FLogAppenders.Count;
end;

constructor TLogWriter.Create(aLogAppenders: TLogAppenderList;
  aLogLevel: TLogType);
begin
  inherited Create;
  FFreeAllowed := False;
  FLogAppenders := aLogAppenders;
  FLogLevel := aLogLevel;
end;

constructor TLogWriter.Create(aLogLevel: TLogType);
begin
  Create(TLogAppenderList.Create, aLogLevel);
end;

procedure TLogWriter.Debug(aMessage, aTag: string);
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
  FLoggerThread.Terminate;
  FLoggerThread.WaitFor;
  FLoggerThread.Free;
  FLogAppenders.Free;
  inherited;
end;

procedure TLogWriter.Error(aMessage, aTag: string);
begin
  Log(TLogType.Error, aMessage, aTag);
end;

procedure TLogWriter.ErrorFmt(aMessage: string; aParams: array of TVarRec;
  aTag: string);
begin
  LogFmt(TLogType.Error, aMessage, aParams, aTag);
end;

function TLogWriter.GetAppenders(const Index: Integer): ILogAppender;
begin
  Result := Self.FLogAppenders[index];
end;

function TLogWriter.GetAppendersClassNames: TArray<string>;
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

function TLogWriter.GetAppenderStatus(const AppenderName: string): string;
var
  I: Integer;
begin
  TMonitor.Enter(FLogAppenders);
  try
    Result := '';
    for I := 0 to FLogAppenders.Count - 1 do
    begin
      // if TObject(FLogAppenders[I]).ClassName.Equals(AppenderName) then
      if SameText(TObject(FLogAppenders[I]).ClassName, AppenderName) then
      // XE2+ Compatibility
      begin
        // if FLogAppenders[I].IsEnabled then
        // Result := 'enabled'
        // else
        // Result := 'disabled';
        Exit;
      end;
    end;
  finally
    TMonitor.Exit(FLogAppenders);
  end;
end;

procedure TLogWriter.Info(aMessage, aTag: string);
begin
  Log(TLogType.Info, aMessage, aTag);
end;

procedure TLogWriter.InfoFmt(aMessage: string; aParams: array of TVarRec;
  aTag: string);
begin
  LogFmt(TLogType.Info, aMessage, aParams, aTag);
end;

procedure TLogWriter.Log(aType: TLogType; aMessage, aTag: string);
var
  lLogItem: TLogItem;
begin
  if aType >= FLogLevel then
  begin
    lLogItem := TLogItem.Create(aType, aMessage, aTag);
    if FLoggerThread.LogWriterQueue.PushItem(lLogItem) = TWaitResult.wrTimeout
    then
    begin
      FreeAndNil(lLogItem);
      raise ELoggerPro.Create
        ('Main logs queue is full. Hints: Are there appenders? Are these appenders fast enough considering the log item production?');
    end;
  end;
end;

procedure TLogWriter.LogFmt(aType: TLogType; aMessage: string;
  aParams: array of const; aTag: string);
begin
  Log(aType, Format(aMessage, aParams), aTag);
end;

procedure TLogWriter.Initialize(aEventsHandler: TLoggerProEventsHandler);
begin
  FLoggerThread := TLoggerThread.Create(FLogAppenders);
  FLoggerThread.EventsHandlers := aEventsHandler;
  FLoggerThread.Start;
end;

procedure TLogWriter.Warn(aMessage, aTag: string);
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
  Result := TLogItem.Create(FType, FMessage, FTag, FTimeStamp, FThreadID);
end;

constructor TLogItem.Create(aType: TLogType; aMessage, aTag: string);
begin
  Create(aType, aMessage, aTag, now, TThread.CurrentThread.ThreadID);
end;

{ TLogger.TLoggerThread }

constructor TLoggerThread.Create(aAppenders: TLogAppenderList);
begin
  FQueue := TThreadedQueue<TLogItem>.Create(DefaultLoggerProMainQueueSize,
    1000, 200);
  FAppenders := aAppenders;
  inherited Create(true);
  FreeOnTerminate := False;
end;

destructor TLoggerThread.Destroy;
begin
  FQueue.Free;
  inherited;
end;

procedure TLoggerThread.DoOnAppenderError(const FailAppenderClassName: string;
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
  lAppendersDecorators: TObjectList<TAppenderAdapter>;
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
              if lLogItem.LogType >= lAppendersDecorators[I].GetLogLevel then
              begin
                if not lAppendersDecorators[I].EnqueueLog(lLogItem) then
                begin
                  lAction := TLogErrorAction.SkipNewest; // default
                  DoOnAppenderError
                    (TObject(lAppendersDecorators[I].FLogAppender).ClassName,
                    lLogItem, TLogErrorReason.QueueFull, lAction);
                  case lAction of
                    TLogErrorAction.SkipNewest:
                      begin
                        // just skip the new message
                      end;
                    TLogErrorAction.DiscardOlder:
                      begin
                        // just remove the oldest log message
                        lAppendersDecorators[I].Queue.PopItem.Free;
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

function TLoggerThread.BuildAppendersDecorator: TObjectList<TAppenderAdapter>;
var
  I: Integer;
begin
  Result := TObjectList<TAppenderAdapter>.Create(true);
  try
    for I := 0 to FAppenders.Count - 1 do
    begin
      Result.Add(TAppenderAdapter.Create(FAppenders[I]));
    end;
  except
    Result.Free;
    raise;
  end;
end;

constructor TLogItem.Create(aType: TLogType; aMessage, aTag: string;
  aTimeStamp: TDateTime; aThreadID: Cardinal);
begin
  inherited Create;
  FType := aType;
  FMessage := aMessage;
  FTag := aTag;
  FTimeStamp := aTimeStamp;
  FThreadID := aThreadID;
end;

function TLogItem.GetLogTypeAsString: string;
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

constructor TLoggerThread.TAppenderAdapter.Create(aAppender: ILogAppender);
begin
  inherited Create;
  FFailsCount := 0;
  FLogAppender := aAppender;
  FAppenderQueue := TAppenderQueue.Create
    (DefaultLoggerProAppenderQueueSize, 0, 500);
  FTerminated := False;
  FAppenderThread := TAppenderThread.Create(FLogAppender, FAppenderQueue);

  // FAppenderThread := TThread.CreateAnonymousThread(
  // procedure
  // var
  // lLogItem: TLogItem;
  // begin
  // FLogAppender.Setup;
  // try
  // while (not FTerminated) or (FAppenderQueue.QueueSize > 0) do
  // begin
  // if FAppenderQueue.PopItem(lLogItem) = TWaitResult.wrSignaled then
  // begin
  // if lLogItem <> nil then
  // try
  // try
  // FLogAppender.WriteLog(lLogItem);
  // except
  // Enabled := False;
  // end;
  // finally
  // lLogItem.Free;
  // end;
  // end;
  // end;
  // finally
  // FLogAppender.TearDown;
  // end;
  // end);
  // FAppenderThread.FreeOnTerminate := False;
  // FAppenderThread.Start;
end;

destructor TLoggerThread.TAppenderAdapter.Destroy;
begin
  FAppenderQueue.DoShutDown;
  FTerminated := true;
  FAppenderThread.Terminate;
  FAppenderThread.WaitFor;
  FAppenderThread.Free;
  FAppenderQueue.Free;
  inherited;
end;

function TLoggerThread.TAppenderAdapter.GetLogLevel: TLogType;
begin
  Result := FLogAppender.GetLogLevel;
end;

function TLoggerThread.TAppenderAdapter.EnqueueLog(const aLogItem
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

{ TLoggerProAppenderBase }

constructor TLoggerProAppenderBase.Create;
begin
  inherited;
  Self.FEnabled := true;
  Self.FLogLevel := TLogType.Debug;
end;

function TLoggerProAppenderBase.GetLastErrorTimeStamp: TDateTime;
begin
  Result := FLastErrorTimeStamp;
end;

function TLoggerProAppenderBase.GetLogLevel: TLogType;
begin
  Result := FLogLevel;
end;

procedure TLoggerProAppenderBase.SetLastErrorTimeStamp(const Value: TDateTime);
begin
  FLastErrorTimeStamp := Value;
end;

procedure TLoggerProAppenderBase.SetLogLevel(const Value: TLogType);
begin
  FLogLevel := Value;
end;

procedure TLoggerProAppenderBase.TryToRestart(var Restarted: Boolean);
begin
  Restarted := False;
  // do nothing "smart" here... descendant must implement specific "restart" strategies
end;

{ TAppenderThread }

constructor TAppenderThread.Create(aLogAppender: ILogAppender;
  aAppenderQueue: TAppenderQueue);
begin
  FLogAppender := aLogAppender;
  FAppenderQueue := aAppenderQueue;
  inherited Create(False);
end;

procedure TAppenderThread.Execute;
var
  lLogItem: TLogItem;
  lRestarted: Boolean;
  lStatus: TAppenderStatus;
  lSetupFailCount: Integer;
begin
  lSetupFailCount := 0;
  lStatus := TAppenderStatus.BeforeSetup;
  try
    { the appender tries to log all the messages before terminate... }
    while (not Terminated) or (FAppenderQueue.QueueSize > 0) do
    begin
      { ...but if the thread should be terminated, and the appender is failing,
        its messages will be lost }
      if Terminated and (lStatus = TAppenderStatus.WaitAfterFail) then
        Break;

      try
        { this state machine handles the status of the appender }
        case lStatus of
          TAppenderStatus.BeforeTearDown:
            begin
              Break;
            end;

          TAppenderStatus.BeforeSetup:
            begin
              try
                FLogAppender.Setup;
                lStatus := TAppenderStatus.Running;
              except
                if lSetupFailCount = 10 then
                begin
                  lStatus := TAppenderStatus.WaitAfterFail;
                end
                else
                begin
                  Inc(lSetupFailCount);
                  Sleep(1000); // wait before next setup call
                end;
              end;
            end;

          TAppenderStatus.ToRestart:
            begin
              try
                lRestarted := False;
                FLogAppender.TryToRestart(lRestarted);
                if lRestarted then
                begin
                  lStatus := TAppenderStatus.Running;
                  FLogAppender.LastErrorTimeStamp := 0;
                end
                else
                begin
                  lRestarted := False;
                  FLogAppender.LastErrorTimeStamp := now;
                  lStatus := TAppenderStatus.WaitAfterFail;
                end;
              except
                lRestarted := False;
              end;
              Failing := not lRestarted;
            end;

          TAppenderStatus.WaitAfterFail:
            begin
              Sleep(500);
              if SecondsBetween(now, FLogAppender.LastErrorTimeStamp) >= 5 then
                lStatus := TAppenderStatus.ToRestart;
            end;

          TAppenderStatus.Running:
            begin
              if FAppenderQueue.PopItem(lLogItem) = TWaitResult.wrSignaled then
              begin
                if lLogItem <> nil then
                begin
                  try
                    try
                      FLogAppender.WriteLog(lLogItem);
                    except
                      Failing := true;
                      FLogAppender.LastErrorTimeStamp := now;
                      lStatus := TAppenderStatus.WaitAfterFail;
                      Continue;
                    end;
                  finally
                    lLogItem.Free;
                  end;
                end;
              end;
            end;
        end;
      except
        // something wrong... but we cannot stop the thread. Let's retry.
      end;
    end;
  finally
    FLogAppender.TearDown;
  end;
end;

procedure TAppenderThread.SetFailing(const Value: Boolean);
begin
  FFailing := Value;
end;

end.
