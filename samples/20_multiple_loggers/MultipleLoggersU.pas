unit MultipleLoggersU;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, LoggerPro, Vcl.StdCtrls;

type
  TMultipleLoggersForm = class(TForm)
    Memo1: TMemo;
    btnFormLocalLog: TButton;
    btnApplicationLevelLog: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnFormLocalLogClick(Sender: TObject);
    procedure btnApplicationLevelLogClick(Sender: TObject);
  private
    FLogWriter: ILogWriter;
    function LocalLog: ILogWriter;
  public
    { Public declarations }
  end;

var
  MultipleLoggersForm: TMultipleLoggersForm;

implementation

uses
  LoggerPro.VCLMemoAppender, LoggerPro.Builder, LoggerProConfig;

{$R *.dfm}

procedure TMultipleLoggersForm.btnApplicationLevelLogClick(Sender: TObject);
begin
  Log.Log(TLogType(Random(Ord(TLogType.Fatal) + 1)),
    'Message sent to the application level LoggerPro instance (random type)',
    'APP');
end;

procedure TMultipleLoggersForm.btnFormLocalLogClick(Sender: TObject);
begin
  LocalLog.Log(TLogType(Random(Ord(TLogType.Fatal) + 1)),
    'Message sent to the form local LoggerPro instance (random type)', 'tag');
end;

procedure TMultipleLoggersForm.FormCreate(Sender: TObject);
begin
  // BuildLogWriter is the classic way to create a log writer.
  // The modern and recommended approach is to use LoggerProBuilder.
  //FLogWriter := BuildLogWriter([TVCLMemoLogAppender.Create(Memo1)], nil,
  //  TLogType.Info);
  FLogWriter := LoggerProBuilder
    .WithDefaultLogLevel(TLogType.Info)
    .ConfigureVCLMemoAppender(Memo1)
      .Done
    .Build;
  FLogWriter.Info('Local log correctly initialized', 'tag');
end;

function TMultipleLoggersForm.LocalLog: ILogWriter;
begin
  Result := FLogWriter;
end;

end.
