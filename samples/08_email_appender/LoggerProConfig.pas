unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  LoggerPro.FileAppender,
  LoggerPro.EMailAppender,
  LoggerPro.OutputDebugStringAppender,
  LoggerPro.Builder,
  System.SysUtils,
  idSMTP, System.IOUtils,
  IdIOHandlerStack, IdSSL,
  IdSSLOpenSSL, IdExplicitTLSClientServerBase;

var
  _Log: ILogWriter;

const
  USE_SSL = true;

function Log: ILogWriter;
begin
  Result := _Log;
end;

function GetSMTP: TidSMTP;
begin
  Result := TidSMTP.Create(nil);
  try
    if USE_SSL then
    begin
      Result.IOHandler := TIdSSLIOHandlerSocketOpenSSL.Create(Result);
    end;
    Result.Host := 'smtp.example.com';
    Result.Port := 25;
    Result.UseTLS := TIdUseTLS.utUseImplicitTLS;
    Result.AuthType := satDefault;
    Result.Username := 'user@example.com';
    if not TFile.Exists('config.txt') then
      raise Exception.Create('Create a "config.txt" file containing the SMTP password');
    Result.Password := TFile.ReadAllText('config.txt');
  except
    Result.Free;
    raise;
  end;
end;

procedure SetupLogger;
const

  {$IFDEF DEBUG}

  LOG_LEVEL = TLogType.Debug;

  {$ELSE}

  LOG_LEVEL = TLogType.Warning;

  {$ENDIF}

var
  lEmailAppender: ILogAppender;
begin
  lEmailAppender := TLoggerProEMailAppender.Create(GetSMTP, 'MyApp Logs<noreply@example.com>', 'admin@example.com');
  lEmailAppender.SetMinimumLevel(TLogType.Error);
  _Log := LoggerProBuilder
    .WithDefaultMinimumLevel(LOG_LEVEL)
    .WriteToFile.Done
    .WriteToAppender(lEmailAppender)
    .WriteToOutputDebugString.Done
    .Build;
end;

initialization

SetupLogger;

end.
