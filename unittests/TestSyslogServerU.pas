unit TestSyslogServerU;

{ Simple UDP Syslog server for testing purposes }

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  IdUDPServer,
  IdSocketHandle,
  IdGlobal;

type
  TSyslogTestServer = class
  private
    FUDPServer: TIdUDPServer;
    FReceivedMessages: TList<string>;
    FLock: TCriticalSection;
    FPort: Integer;
    FActive: Boolean;
    procedure OnUDPRead(AThread: TIdUDPListenerThread; const AData: TIdBytes; ABinding: TIdSocketHandle);
  public
    constructor Create(aPort: Integer = 514);
    destructor Destroy; override;

    procedure Start;
    procedure Stop;
    procedure Clear;
    function GetReceivedMessages: TArray<string>;
    function GetLastMessage: string;
    function MessageCount: Integer;

    property Port: Integer read FPort;
    property Active: Boolean read FActive;
  end;

implementation

{ TSyslogTestServer }

constructor TSyslogTestServer.Create(aPort: Integer);
begin
  inherited Create;
  FPort := aPort;
  FActive := False;
  FReceivedMessages := TList<string>.Create;
  FLock := TCriticalSection.Create;

  FUDPServer := TIdUDPServer.Create(nil);
  FUDPServer.DefaultPort := FPort;
  FUDPServer.OnUDPRead := OnUDPRead;
  FUDPServer.ThreadedEvent := True;
end;

destructor TSyslogTestServer.Destroy;
begin
  Stop;
  FUDPServer.Free;
  FLock.Free;
  FReceivedMessages.Free;
  inherited;
end;

procedure TSyslogTestServer.OnUDPRead(AThread: TIdUDPListenerThread;
  const AData: TIdBytes; ABinding: TIdSocketHandle);
var
  lMessage: string;
begin
  // Convert received bytes to string
  lMessage := IndyTextEncoding_UTF8.GetString(AData);

  // Store in thread-safe list
  FLock.Enter;
  try
    FReceivedMessages.Add(lMessage);
  finally
    FLock.Leave;
  end;
end;

procedure TSyslogTestServer.Start;
begin
  if not FActive then
  begin
    FUDPServer.Active := True;
    FActive := True;
  end;
end;

procedure TSyslogTestServer.Stop;
begin
  if FActive then
  begin
    FUDPServer.Active := False;
    FActive := False;
  end;
end;

procedure TSyslogTestServer.Clear;
begin
  FLock.Enter;
  try
    FReceivedMessages.Clear;
  finally
    FLock.Leave;
  end;
end;

function TSyslogTestServer.GetReceivedMessages: TArray<string>;
begin
  FLock.Enter;
  try
    Result := FReceivedMessages.ToArray;
  finally
    FLock.Leave;
  end;
end;

function TSyslogTestServer.GetLastMessage: string;
begin
  Result := '';
  FLock.Enter;
  try
    if FReceivedMessages.Count > 0 then
      Result := FReceivedMessages.Last;
  finally
    FLock.Leave;
  end;
end;

function TSyslogTestServer.MessageCount: Integer;
begin
  FLock.Enter;
  try
    Result := FReceivedMessages.Count;
  finally
    FLock.Leave;
  end;
end;

end.
