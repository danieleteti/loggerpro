library mydll;

uses
  LoggerPro.GlobalLogger,
  MyThreadU in 'MyThreadU.pas';

var
  lObj: IMyInterface = nil;

procedure Init;
begin
  lObj := TMyObject.Create;
end;

procedure DeInit;
begin
  lObj := nil;
  ReleaseGlobalLogger; // This is required inside dll and ISAPI!!
end;

exports
  Init, DeInit;

begin

end.
