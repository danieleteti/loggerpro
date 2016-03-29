program console_appender;

uses
  Vcl.Forms,
  MainFormU in '..\common\MainFormU.pas' {MainForm},
  LoggerProConfig in 'LoggerProConfig.pas';

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
