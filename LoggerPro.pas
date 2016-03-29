unit LoggerPro;
{ <@abstract(The main unit you should always include)
  @author(Daniele Teti) }

interface

uses
  System.Generics.Collections, System.SysUtils, System.Classes;

type
{$SCOPEDENUMS ON}
  TLogType = (Debug = 0, Info, Warning, Error);
  TLogErrorReason = (QueueFull);
  TLogErrorAction = (Retry, Skip, DisableAppender);

  { @abstract(Represent the single log item)
    Each call to some kind of log method is wrapped in a @link(TLogItem)
    instance and passed down the layour of LoggerPro. }
  TLogItem = class sealed
    constructor Create(aType: TLogType; aMessage: String; aTag: String;
      aRetryCount: Cardinal); overload;
    constructor Create(aType: TLogType; aMessage: String; aTag: String;
      aTimeStamp: TDateTime; aThreadID: Cardinal;
      aRetryCount: Cardinal); overload;
  private
    FType: TLogType;
    FMessage: string;
    FTag: string;
    FTimeStamp: TDateTime;
    FThreadID: Cardinal;
    FRetryCount: Cardinal;
    function GetLogTypeAsString: String;
  protected
    procedure IncRetriesCount;
  public
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
    property LogMessage: String read FMessage;
    { @abstract(The tag of the log message) }
    property LogTag: String read FTag;
    { @abstract(The timestamp when the @link(TLogItem) is generated) }
    property TimeStamp: TDateTime read FTimeStamp;
    { @abstract(The IDof the thread which generated the log item) }
    property ThreadID: Cardinal read FThreadID;
    { @abstract(The type of the log converted in string) }
    property LogTypeAsString: String read GetLogTypeAsString;
    { @abstract(How many times this message failed to be processed by its appender) }
    property RetriesCount: Cardinal read FRetryCount;
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
    function BuildAppendersDecorator: TObjectList<TAppenderDecorator>;
    procedure DoOnLogError(const aFailAppenderDecorator: TAppenderDecorator;
      const aFailedLogItem: TLogItem; const aReason: TLogErrorReason;
      var aAction: TLogErrorAction);
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
    procedure Initialize;
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
  lLogItem: TLogItem;
begin
  if aType >= FLogLevel then
  begin
    lLogItem := TLogItem.Create(aType, aMessage, aTag, 0);
    if FQueue.PushItem(lLogItem) = TWaitResult.wrTimeout then
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
  FLoggerThread := TLoggerThread.Create(FQueue, FLogAppenders);
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
  Result := TLogItem.Create(FType, FMessage, FTag, FRetryCount);
end;

constructor TLogItem.Create(aType: TLogType; aMessage, aTag: String;
  aRetryCount: Cardinal);
begin
  Create(aType, aMessage, aTag, now, TThread.Current.ThreadID, aRetryCount);
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

procedure TLoggerThread.DoOnLogError(const aFailAppenderDecorator
  : TAppenderDecorator; const aFailedLogItem: TLogItem;
  const aReason: TLogErrorReason; var aAction: TLogErrorAction);
begin

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
                  lAction := TLogErrorAction.Skip;
                  DoOnLogError(lAppendersDecorators[I], lLogItem,
                    TLogErrorReason.QueueFull, lAction);
                  case lAction of
                    TLogErrorAction.Retry:
                      begin
                        lLogItem.IncRetriesCount;
                        FQueue.PushItem(lLogItem.Clone);
                      end;
                    TLogErrorAction.Skip:
                      begin
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
  aTimeStamp: TDateTime; aThreadID: Cardinal; aRetryCount: Cardinal);
begin
  inherited Create;
  FRetryCount := aRetryCount;
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

procedure TLogItem.IncRetriesCount;
begin
  FRetryCount := FRetryCount + 1;
end;

{ TLoggerThread.TAppenderDecorator }

constructor TLoggerThread.TAppenderDecorator.Create(aAppender: ILogAppender);
begin
  inherited Create;
  FFailsCount := 0;
  FLogAppender := aAppender;
  FAppenderQueue := TThreadedQueue<TLogItem>.Create(10, 1, 500);
  FTerminated := False;
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
                  { TODO -oDaniele -cGeneral : Something smarter to do here? }
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
end;

function TLoggerThread.TAppenderDecorator.WriteLog(const aLogItem
  : TLogItem): Boolean;
begin
  Result := FAppenderQueue.PushItem(aLogItem.Clone) = TWaitResult.wrSignaled;
  if not Result then
    FFailsCount := FFailsCount + 1
  else
    FFailsCount := 0;
end;

end.
