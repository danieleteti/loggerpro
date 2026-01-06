unit MainFormU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  System.Generics.Collections;

type
  TMainForm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FRunningThreads: TObjectList<TThread>;
    procedure WaitForAllThreads;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

uses
  LoggerPro.GlobalLogger;

{$R *.dfm}

// =============================================================================
// LoggerPro 2.0 - Global Logger Sample
// =============================================================================
// The GlobalLogger provides a ready-to-use logger instance with zero config.
// Just use Log.Info(), Log.Debug(), etc. from anywhere in your application.
//
// For custom configuration, create your own logger using LoggerProBuilder
// (see other samples like 160_console or 210_context_logging).
// =============================================================================

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FRunningThreads := TObjectList<TThread>.Create(True);
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FRunningThreads.Free;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  WaitForAllThreads;
end;

procedure TMainForm.WaitForAllThreads;
var
  I: Integer;
begin
  for I := 0 to FRunningThreads.Count - 1 do
  begin
    FRunningThreads[I].WaitFor;
  end;
  FRunningThreads.Clear;
end;

procedure TMainForm.Button1Click(Sender: TObject);
begin
  // Basic debug logging with tags
  Log.Debug('This is a debug message with TAG1', 'TAG1');
  Log.Debug('This is a debug message with TAG2', 'TAG2');
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
  // Basic info logging with tags
  Log.Info('This is a info message with TAG1', 'TAG1');
  Log.Info('This is a info message with TAG2', 'TAG2');

  // ---------------------------------------------------------------------------
  // LoggerPro 2.0: WithProperty for structured context
  // ---------------------------------------------------------------------------
  // Create a sub-logger with bound context properties
  var UserLog := Log
    .WithProperty('user_id', 42)
    .WithProperty('action', 'button_click');
  UserLog.Info('User performed action', 'USER');
end;

procedure TMainForm.Button3Click(Sender: TObject);
begin
  Log.Warn('This is a warning message with TAG1', 'TAG1');
  Log.Warn('This is a warning message with TAG2', 'TAG2');
end;

procedure TMainForm.Button4Click(Sender: TObject);
begin
  Log.Error('This is an error message with TAG1', 'TAG1');
  Log.Error('This is an error message with TAG2', 'TAG2');

  // ---------------------------------------------------------------------------
  // LoggerPro 2.0: LogException for exception logging
  // ---------------------------------------------------------------------------
  try
    raise Exception.Create('Simulated error for demonstration');
  except
    on E: Exception do
    begin
      // Log exception with context
      Log.LogException(E, 'Error occurred in Button4Click', 'ERROR_DEMO');
    end;
  end;
end;

procedure TMainForm.Button5Click(Sender: TObject);
var
  lThread: TThread;
  lThreadProc: TProc;
  I: Integer;
begin
  // ---------------------------------------------------------------------------
  // Multithreaded logging demonstration
  // ---------------------------------------------------------------------------
  // LoggerPro is fully thread-safe. Multiple threads can log simultaneously
  // without any locking from the caller's side.
  lThreadProc := procedure
    var
      J: Integer;
      lThreadID: String;
    begin
      lThreadID := IntToStr(TThread.CurrentThread.ThreadID);
      for J := 1 to 200 do
      begin
        Log.Debug('log message ' + TimeToStr(now) + ' ThreadID: ' + lThreadID,
          'MULTITHREADING');
        Log.Info('log message ' + TimeToStr(now) + ' ThreadID: ' + lThreadID,
          'MULTITHREADING');
        Log.Warn('log message ' + TimeToStr(now) + ' ThreadID: ' + lThreadID,
          'MULTITHREADING');
        Log.Error('log message ' + TimeToStr(now) + ' ThreadID: ' + lThreadID,
          'MULTITHREADING');
      end;
    end;

  for I := 1 to 5 do
  begin
    lThread := TThread.CreateAnonymousThread(lThreadProc);
    lThread.FreeOnTerminate := False;
    FRunningThreads.Add(lThread);
    lThread.Start;
  end;
end;

end.
