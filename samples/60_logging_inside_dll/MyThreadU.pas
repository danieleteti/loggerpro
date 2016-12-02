unit MyThreadU;

interface

uses
  System.Classes;

type
  TMyThread = class(TThread)
    procedure Execute; override;
  end;

  IMyInterface = interface
    ['{603F3B5A-116C-4286-B70B-85CD7747BCF0}']
  end;

  TMyObject = class(TinterfacedObject, IMyInterface)
  protected
    FMyThread: TMyThread;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  LoggerPro.GlobalLogger;

{ TMyThread }

procedure TMyThread.Execute;
begin
  while not Terminated do
  begin
    Log.Debug('Into the thread...', 'dll');
    Sleep(1000);
  end;
end;

{ TMyObject }

constructor TMyObject.Create;
begin
  inherited;
  Log.Debug('Creating the thread', 'dll');
  FMyThread := TMyThread.Create(true);
  FMyThread.Start;
end;

destructor TMyObject.Destroy;
begin
  Log.Debug('Destroing the thread', 'dll');
  FMyThread.Terminate;
  FMyThread.WaitFor;
  FMyThread.Free;
  inherited;
end;

end.
