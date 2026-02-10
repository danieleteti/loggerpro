// *************************************************************************** }
//
// LoggerPro
//
// Copyright (c) 2010-2026 Daniele Teti
//
// https://github.com/danieleteti/loggerpro
//
// ***************************************************************************
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ***************************************************************************

unit LoggerPro.MaskingAppender;

interface

uses
  System.SysUtils,
  System.RegularExpressions,
  LoggerPro;

type
  TLoggerProMaskingAppender = class(TInterfacedObject, ILogAppender, ILogAppenderProxy)
  private
    FAppender: ILogAppender;
    FPhoneRegex: TRegex;
    FPasswordRegex: TRegex;
    function GetInternalAppender: ILogAppender;
  public
    constructor Create(Appender: ILogAppender); reintroduce;
    destructor Destroy; override;
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem);
    procedure SetEnabled(const Value: Boolean);
    function IsEnabled: Boolean;
    procedure SetLogLevel(const Value: TLogType);
    function GetLogLevel: TLogType;
    procedure TryToRestart(var Restarted: Boolean);
    procedure SetLastErrorTimeStamp(const LastErrorTimeStamp: TDateTime);
    function GetLastErrorTimeStamp: TDateTime;
    property InternalAppender: ILogAppender read GetInternalAppender;
  end;

implementation

const
  PHONE_PATTERN = '(\d{3})\d{4}(\d{4})';
  PASSWORD_PATTERN = '(password\s*[:=]\s*)([^&\s]+)';

{ TLoggerProMaskingAppender }

constructor TLoggerProMaskingAppender.Create(Appender: ILogAppender);
begin
  inherited Create;
  FAppender := Appender;
  FPhoneRegex := TRegex.Create(PHONE_PATTERN, [roIgnoreCase]);
  FPasswordRegex := TRegex.Create(PASSWORD_PATTERN, [roIgnoreCase]);
end;

destructor TLoggerProMaskingAppender.Destroy;
begin
  FAppender := nil;
  inherited;
end;

function TLoggerProMaskingAppender.GetInternalAppender: ILogAppender;
begin
  Result := FAppender;
end;

function TLoggerProMaskingAppender.GetLastErrorTimeStamp: TDateTime;
begin
  if Assigned(FAppender) then
    Result := FAppender.LastErrorTimeStamp
  else
    Result := 0;
end;

function TLoggerProMaskingAppender.GetLogLevel: TLogType;
begin
  if Assigned(FAppender) then
    Result := FAppender.GetLogLevel
  else
    Result := TLogType.Debug;
end;

function TLoggerProMaskingAppender.IsEnabled: Boolean;
begin
  if Assigned(FAppender) then
    Result := FAppender.IsEnabled
  else
    Result := False;
end;

procedure TLoggerProMaskingAppender.SetEnabled(const Value: Boolean);
begin
  if Assigned(FAppender) then
    FAppender.SetEnabled(Value);
end;

procedure TLoggerProMaskingAppender.SetLastErrorTimeStamp(
  const LastErrorTimeStamp: TDateTime);
begin
  if Assigned(FAppender) then
    FAppender.SetLastErrorTimeStamp(LastErrorTimeStamp);
end;

procedure TLoggerProMaskingAppender.SetLogLevel(const Value: TLogType);
begin
  if Assigned(FAppender) then
    FAppender.SetLogLevel(Value);
end;

procedure TLoggerProMaskingAppender.Setup;
begin
  if Assigned(FAppender) then
    FAppender.Setup;
end;

procedure TLoggerProMaskingAppender.TearDown;
begin
  if Assigned(FAppender) then
    FAppender.TearDown;
end;

procedure TLoggerProMaskingAppender.TryToRestart(var Restarted: Boolean);
begin
  if Assigned(FAppender) then
    FAppender.TryToRestart(Restarted)
  else
    Restarted := False;
end;

procedure TLoggerProMaskingAppender.WriteLog(const aLogItem: TLogItem);
var
  MaskedMessage: string;
  MaskedLogItem: TLogItem;
begin
  if not Assigned(FAppender) then
    Exit;

  MaskedMessage := aLogItem.LogMessage;
  MaskedMessage := FPhoneRegex.Replace(MaskedMessage, '$1****$2');
  MaskedMessage := FPasswordRegex.Replace(MaskedMessage, '$1****');

  MaskedLogItem := TLogItem.Create(
    aLogItem.LogType,
    MaskedMessage,
    aLogItem.LogTag,
    aLogItem.TimeStamp,
    aLogItem.ThreadID,
    aLogItem.Context
  );
  try
    FAppender.WriteLog(MaskedLogItem);
  finally
    MaskedLogItem.Free;
  end;
end;

end.
