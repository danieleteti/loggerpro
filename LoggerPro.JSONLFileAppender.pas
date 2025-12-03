// *************************************************************************** }
//
// LoggerPro
//
// Copyright (c) 2010-2025 Daniele Teti
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

unit LoggerPro.JSONLFileAppender;

{.$DEFINE USE_JDO}


interface

uses
  LoggerPro.FileAppender,
  System.Classes,
  LoggerPro, System.SysUtils;

type
  { @abstract(JSONL file appender with multiple tags)
    This file appender writes all TLogItems into a single log file as JSONL
  }
  TLoggerProJSONLFileAppender = class(TLoggerProSimpleFileAppender)
  protected
    function GetLogFileName(const aTag: string; const aFileNumber: Integer): string; override;
    procedure EmitStartRotateLogItem(aWriter: TStreamWriter); override;
    procedure EmitEndRotateLogItem(aWriter: TStreamWriter); override;
  public
    constructor Create(aMaxBackupFileCount: Integer = TLoggerProFileAppender.DEFAULT_MAX_BACKUP_FILE_COUNT;
      aMaxFileSizeInKiloByte: Integer = TLoggerProFileAppender.DEFAULT_MAX_FILE_SIZE_KB; aLogsFolder: string = '';
      aLogFileNameFormat: string = TLoggerProSimpleFileAppender.DEFAULT_FILENAME_FORMAT; aEncoding: TEncoding = nil);
      reintroduce;
  end;

implementation


uses
  System.IOUtils,
  System.DateUtils,
{$IF Defined(MSWINDOWS)}
  Winapi.Windows,
{$ENDIF}
{$IF Defined(USE_JDO)}
  JsonDataObjects
{$ELSE}
  System.JSON
{$ENDIF}
;


type
  TLogItemRendererJSONL = class(TLogItemRenderer)
  private
    fHostName: string;
  protected
    procedure Setup; override;
    procedure TearDown; override;
    function RenderLogItem(const aLogItem: TLogItem): String; override;
  end;


{ TLoggerProJSONLFileAppender }

constructor TLoggerProJSONLFileAppender.Create(
  aMaxBackupFileCount, aMaxFileSizeInKiloByte: Integer;
  aLogsFolder: string;
  aLogFileNameFormat: string;
  aEncoding: TEncoding);
begin
  inherited Create(
    aMaxBackupFileCount,
    aMaxFileSizeInKiloByte,
    aLogsFolder,
    aLogFileNameFormat,
    TLogItemRendererJSONL.Create,
    aEncoding);
end;

procedure TLoggerProJSONLFileAppender.EmitEndRotateLogItem(aWriter: TStreamWriter);
begin
  // do nothing
end;

procedure TLoggerProJSONLFileAppender.EmitStartRotateLogItem(aWriter: TStreamWriter);
begin
  // do nothing
end;

function TLoggerProJSONLFileAppender.GetLogFileName(const aTag: string; const aFileNumber: Integer): string;
var
  lOrigFName, lOrigExt: string;
begin
  lOrigFName := inherited;
  lOrigExt := TPath.GetExtension(lOrigFName);
  if lOrigExt.IsEmpty then
  begin
    lOrigExt := '.log';
  end;
  Result := TPath.ChangeExtension(lOrigFName, '.jsonl' + lOrigExt);
end;


{ TLogItemRendererJSONL }

function TLogItemRendererJSONL.RenderLogItem(const aLogItem: TLogItem): String;
var
  lJSON: TJsonObject;
begin
  lJSON := TJSONObject.Create;
  try
    {$IF Defined(USE_JDO)}
    lJSON.S['timestamp'] := DateToISO8601(ALogItem.TimeStamp);
    lJSON.S['level'] := ALogItem.LogTypeAsString;
    lJSON.S['message'] := ALogItem.LogMessage;
    lJSON.S['tag'] := ALogItem.LogTag;
    lJSON.S['hostname'] := fHostName;
    lJSON.I['tid'] := ALogItem.ThreadID;
    {$ELSE}
    lJSON.AddPair('timestamp', DateToISO8601(ALogItem.TimeStamp));
    lJSON.AddPair('level', ALogItem.LogTypeAsString);
    lJSON.AddPair('message', ALogItem.LogMessage);
    lJSON.AddPair('tag', ALogItem.LogTag);
    lJSON.AddPair('hostname', fHostName);
    lJSON.AddPair('tid', ALogItem.ThreadID);
    {$ENDIF}
    Result := lJSON.ToJSON;
  finally
    lJSON.Free;
  end;
end;

procedure TLogItemRendererJSONL.Setup;
{$IF Defined(MSWINDOWS)}
var
  lBufferSize: Cardinal;
  lBuffer: string;
{$ENDIF}
begin
  inherited;
  {$IF Defined(MSWINDOWS)}
  lBufferSize := 256;
  SetLength(lBuffer, lBufferSize);
  if GetComputerName(PChar(lBuffer), lBufferSize) then
    fHostName := Copy(lBuffer, 1, lBufferSize)
  else
    fHostName := 'unknown';
  {$ELSEIF Defined(POSIX)}
  fHostName := GetEnvironmentVariable('HOSTNAME');
  if fHostName.IsEmpty then
    fHostName := 'unknown';
  {$ELSE}
  fHostName := 'unknown';
  {$ENDIF}
end;

procedure TLogItemRendererJSONL.TearDown;
begin
  inherited;

end;

end.
