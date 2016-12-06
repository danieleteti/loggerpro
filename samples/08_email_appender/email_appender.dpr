program email_appender;

uses
  Vcl.Forms,
  MemoAppendersFormU in 'MemoAppendersFormU.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
