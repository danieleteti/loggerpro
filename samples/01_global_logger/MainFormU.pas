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
  Log.Debug('This is a debug message with TAG1', 'TAG1');
  Log.Debug('This is a debug message with TAG2', 'TAG2');
end;

procedure TMainForm.Button2Click(Sender: TObject);
begin
  Log.Info('This is a info message with TAG1', 'TAG1');
  Log.Info('This is a info message with TAG2', 'TAG2');
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
end;

procedure TMainForm.Button5Click(Sender: TObject);
var
  lThread: TThread;
  lThreadProc: TProc;
  I: Integer;
begin
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
