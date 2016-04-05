program file_appender;

uses
  Vcl.Forms,
  MainFormU in '..\01_global_logger\MainFormU.pas' {MainForm},
  LoggerProConfig in 'LoggerProConfig.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
