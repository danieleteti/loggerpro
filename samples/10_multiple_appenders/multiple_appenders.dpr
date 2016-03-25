program multiple_appenders;

uses
  Vcl.Forms,
  MainFormU in '..\common\MainFormU.pas' {MainForm},
  LoggerProConfig in 'LoggerProConfig.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
