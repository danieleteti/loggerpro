// *************************************************************************** }
//
// LoggerPro
//
// Copyright (c) 2010-2024 Daniele Teti
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

unit LoggerPro.FileAppender;

{$IF Defined(Android) or Defined(iOS)}
{$DEFINE MOBILE}
{$ENDIF}

interface

uses
  LoggerPro,
  System.Generics.Collections,
  System.Classes,
  System.SysUtils;

type
  {
    @abstract(Logs to file using one different file for each different TAG used.)
    @author(Daniele Teti - d.teti@bittime.it)
    Implements log rotations.
    This appender is the default appender when no configuration is done on the @link(TLogger) class.

    Without any configuration LoggerPro uses the @link(TLoggerProFileAppender) with the default configuration.

    So the following two blocks of code are equivalent:

    @longcode(#
    ...
    TLogger.Initialize; //=> uses the TLoggerProFileAppender because no other configuration is provided
    ...

    ...
    TLogger.AddAppender(TLoggerProFileAppender.Create);
    TLogger.Initialize //=> uses the TLoggerProFileAppender as configured
    ...
    #)

  }

  { @abstract(The base class for different file appenders)
    Do not use this class directly, but one of TLoggerProFileAppender or TLoggerProSimpleFileAppender.
    Check the sample @code(file_appender.dproj)
  }

  TLoggerProStreamWriter = class(TStreamWriter)
  private
    FFileCreationDate: TDateTime;
  public
    property FileCreationDate: TDateTime read FFileCreationDate write FFileCreationDate;
  end;

  TLoggerProFileAppenderBase = class(TLoggerProAppenderBase)
  private
    fMaxBackupFileCount: Integer;
    fMaxBackupFileCountLength : Integer;
    fMaxFileSizeInKiloByte: Integer;
    fLogFileNameFormat: string;
    fLogsFolder: string;
    fEncoding: TEncoding;
    fDailyRotate : Boolean;
    function RotateLogNeeded(aLogWriter: TStreamWriter): Boolean;
    function CreateWriter(const aFileName: string): TStreamWriter;
    function GetFileDate(const aFileName: string): TDateTime;
    function GetFileDateFormatted(const aFileName: string): string;
    function FindLogFileByNumber(const aTag: string; const aFileNumber: Integer): string;
    procedure RetryMove(const aFileSrc, aFileDest: string);
  protected
    procedure CheckLogFileNameFormat(const LogFileNameFormat: String); virtual;
    procedure EmitStartRotateLogItem(aWriter: TStreamWriter); virtual;
    procedure EmitEndRotateLogItem(aWriter: TStreamWriter); virtual;
    function GetLogFileName(const aTag, aFileDate: string; const aFileNumber: Integer): string; virtual;
    procedure WriteToStream(const aStreamWriter: TStreamWriter; const aValue: string); inline;
    procedure RotateFile(const aLogTag: string; out aNewFileName: string); virtual;
    procedure InternalWriteLog(const aStreamWriter: TStreamWriter; const aLogItem: TLogItem);
  public const
    { @abstract(Defines the default format string used by the @link(TLoggerProFileAppender).)
      The positional parameters are the following:
      @orderedList(
      @item Number
      @item Module
      @item Tag
      )
    }
    DEFAULT_FILENAME_FORMAT = '{module}.{number}.{tag}.log';
    DEFAULT_FILENAME_FORMAT_WITH_PID = '{module}.{number}.{pid}.{tag}.log';
    DEFAULT_FILENAME_DAILY_ROTATE_FORMAT = '{module}.{date}.{number}.{tag}.log';
    { @abstract(Defines number of log file set to maintain during logs rotation) }
    DEFAULT_MAX_BACKUP_FILE_COUNT = 5;
    { @abstract(Defines the max size of each log file)
      The actual meaning is: "If the file size is > than @link(DEFAULT_MAX_FILE_SIZE_KB) then rotate logs. }
    DEFAULT_MAX_FILE_SIZE_KB = 1000;
    { @abstract(Milliseconds to wait between the RETRY_COUNT times. }
    RETRY_DELAY = 200;
    { @abstract(How many times do we have to retry if the file is locked?. }
    RETRY_COUNT = 5;
    DEFAULT_DAILYROTATE_FILEDATE_FORMAT = 'yyyy-mm-dd';
    constructor Create(aMaxBackupFileCount: Integer = TLoggerProFileAppenderBase.DEFAULT_MAX_BACKUP_FILE_COUNT;
        aMaxFileSizeInKiloByte: Integer = TLoggerProFileAppenderBase.DEFAULT_MAX_FILE_SIZE_KB;
        aLogsFolder: string = '';
        aLogFileNameFormat: string = TLoggerProFileAppenderBase.DEFAULT_FILENAME_FORMAT;
        aLogItemRenderer: ILogItemRenderer = nil;
        aEncoding: TEncoding = nil);
        reintroduce; virtual;
    procedure Setup; override;
  end;

  { @abstract(The default file appender)
    This file appender separates TLogItems with different tags into a log file for each tag.
    To learn how to use this appender, check the sample @code(file_appender.dproj)
  }
  TLoggerProFileAppender = class(TLoggerProFileAppenderBase)
  private
    fWritersDictionary: TObjectDictionary<string, TStreamWriter>;
    procedure AddWriter(const aLogTag: string; var aWriter: TStreamWriter; var aLogFileName: string);
    procedure RotateLog(const aLogTag: string; var aWriter: TStreamWriter);
  public
    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); overload; override;
  end;

  { @abstract(File appender with multiple tags)
    This file appender writes all TLogItems into a single log file.
    Combined with a @code(TLoggerProAppenderFilterImpl) you can filter out any log tags you like.
    If you want to run several TLoggerProSimpleFileAppender in parallel you have to provide a different
    LogFileFormat for each of them in the constructor in order to prevent name collisions.
    To learn how to use this appender, check the sample @code(file_appender.dproj)
  }
  TLoggerProSimpleFileAppender = class(TLoggerProFileAppenderBase)
  private
    fFileWriter: TStreamWriter;
    procedure RotateLog;
  protected
    procedure CheckLogFileNameFormat(const LogFileNameFormat: String); override;
  public
  const
    DEFAULT_FILENAME_FORMAT = '{module}.{number}.log';
    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); overload; override;
    constructor Create(
      aMaxBackupFileCount: Integer = TLoggerProFileAppenderBase.DEFAULT_MAX_BACKUP_FILE_COUNT;
      aMaxFileSizeInKiloByte: Integer = TLoggerProFileAppenderBase.DEFAULT_MAX_FILE_SIZE_KB;
      aLogsFolder: string = '';
      aLogFileNameFormat: string = TLoggerProSimpleFileAppender.DEFAULT_FILENAME_FORMAT;
      aLogItemRenderer: ILogItemRenderer = nil;
      aEncoding: TEncoding = nil);
      override;
  end;


implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.Math,
  System.DateUtils,
  idGlobal
{$IF Defined(Android), System.SysUtils}
    ,Androidapi.Helpers
    ,Androidapi.JNI.GraphicsContentViewText
    ,Androidapi.JNI.JavaTypes
{$ENDIF}
    ;


function OccurrencesOfChar(const S: string; const C: char): integer;
var
  i: Integer;
begin
  result := 0;
  for i := 1 to Length(S) do
    if S[i] = C then
      inc(result);
end;

procedure TLoggerProFileAppenderBase.CheckLogFileNameFormat(const LogFileNameFormat: String);
begin
  //DEFAULT_FILENAME_FORMAT = '{module}.{number}.{tag}.log';
  if not (LogFileNameFormat.Contains('{number}') and LogFileNameFormat.Contains('{tag}')) then
  begin
    raise ELoggerPro.CreateFmt('Wrong FileFormat [%s] - [HINT] A correct file format for %s requires {number} and {tag} placeholders ({module} is optional). A valid file format is : %s',
      [
        ClassName,
        LogFileNameFormat,
        TLoggerProFileAppenderBase.DEFAULT_FILENAME_FORMAT
      ]);
  end;
end;


{ TLoggerProFileAppenderBase }

function TLoggerProFileAppenderBase.GetLogFileName(const aTag, aFileDate:
    string; const aFileNumber: Integer): string;
var
//  lExt: string;
  lModuleName: string;
  lPath: string;
  lFormat: string;
  lFileDate: string;
begin
{$IF Defined(Android)}
  lModuleName := TAndroidHelper.ApplicationTitle.Replace(' ', '_', [rfReplaceAll]);
{$ENDIF}
{$IF not Defined(Mobile)}
  lModuleName := TPath.GetFileNameWithoutExtension(GetModuleName(HInstance));
{$ENDIF}
{$IF Defined(IOS)}
  raise Exception.Create('Platform not supported');
{$ENDIF}
  lFormat := fLogFileNameFormat;

  lPath := fLogsFolder;
  if aFileDate = '' then
    lFileDate := '0'
  else
    lFileDate := aFileDate;
  lFormat := lFormat
    .Replace('{module}', lModuleName, [rfReplaceAll])
    .Replace('{date}', lFileDate, [rfReplaceAll])
    .Replace('{number}', aFileNumber.ToString.PadLeft(fMaxBackupFileCountLength,'0') , [rfReplaceAll])
    .Replace('{tag}', aTag, [rfReplaceAll])
    .Replace('{pid}', CurrentProcessId.ToString.PadLeft(8,'0'), [rfReplaceAll]);
  Result := TPath.Combine(lPath, lFormat);
end;

procedure TLoggerProFileAppenderBase.Setup;
begin
  inherited;

  if fLogsFolder = '' then
  begin
{$IF (Defined(MSWINDOWS) or Defined(POSIX)) and (not Defined(MOBILE))}
    fLogsFolder := TPath.GetDirectoryName(GetModuleName(HInstance));
{$ENDIF}
{$IF Defined(Android) or Defined(IOS)}
    fLogsFolder := TPath.GetSharedDocumentsPath();
{$ENDIF}
  end;
  if not TDirectory.Exists(fLogsFolder) then
    TDirectory.CreateDirectory(fLogsFolder);
end;

procedure TLoggerProFileAppenderBase.WriteToStream(const aStreamWriter: TStreamWriter; const aValue: string);
begin
  aStreamWriter.WriteLine(aValue);
  aStreamWriter.Flush;
end;

procedure TLoggerProFileAppenderBase.InternalWriteLog(const aStreamWriter: TStreamWriter; const aLogItem: TLogItem);
begin
  WriteToStream(aStreamWriter, FormatLog(aLogItem));
end;

procedure TLoggerProFileAppenderBase.RetryMove(const aFileSrc, aFileDest: string);
var
  lRetries: Integer;
const
  MAX_RETRIES = 5;
begin
  lRetries := 0;
  repeat
    try
      Sleep(50);
      // the incidence of "Locked file goes to nearly zero..."
      TFile.Move(aFileSrc, aFileDest);
      Break;
    except
      on E: EInOutError do
      begin
        Inc(lRetries);
        Sleep(50);
      end;
      on E: Exception do
      begin
        raise;
      end;
    end;
  until lRetries = MAX_RETRIES;

  if lRetries = MAX_RETRIES then
    raise ELoggerPro.CreateFmt('Cannot rename %s to %s', [aFileSrc, aFileDest]);
end;

procedure TLoggerProFileAppenderBase.RotateFile(const aLogTag: string; out aNewFileName: string);
var
  lRenamedFile: string;
  I: Integer;
  lCurrentFileName: string;
begin
  aNewFileName := GetLogFileName(aLogTag, '', 0);
  // remove the last file of backup set
  lCurrentFileName := FindLogFileByNumber(aLogTag, fMaxBackupFileCount - 1);
  if lCurrentFileName <> '' then
    TFile.Delete(lCurrentFileName);
  // shift the files names
  for I := fMaxBackupFileCount - 1 downto 1 do
  begin
    lCurrentFileName := FindLogFileByNumber(aLogTag, I);
    if lCurrentFileName = '' then
      Continue;
    lRenamedFile := GetLogFileName(aLogTag, GetFileDateFormatted(lCurrentFileName), I + 1);
    RetryMove(lCurrentFileName, lRenamedFile);
  end;
  lRenamedFile := GetLogFileName(aLogTag, GetFileDateFormatted(aNewFileName), 1);
  RetryMove(aNewFileName, lRenamedFile);
end;

constructor TLoggerProFileAppenderBase.Create(aMaxBackupFileCount: Integer = TLoggerProFileAppenderBase.DEFAULT_MAX_BACKUP_FILE_COUNT;
    aMaxFileSizeInKiloByte: Integer = TLoggerProFileAppenderBase.DEFAULT_MAX_FILE_SIZE_KB;
    aLogsFolder: string = '';
    aLogFileNameFormat: string = TLoggerProFileAppenderBase.DEFAULT_FILENAME_FORMAT;
    aLogItemRenderer: ILogItemRenderer = nil;
    aEncoding: TEncoding = nil);
begin
  inherited Create(aLogItemRenderer);
  fLogsFolder := aLogsFolder;
  fMaxBackupFileCount:= Max(1, aMaxBackupFileCount);
  fMaxBackupFileCountLength := Max(2, (fMaxBackupFileCount-1).ToString.Length);
  fMaxFileSizeInKiloByte := aMaxFileSizeInKiloByte;
  CheckLogFileNameFormat(aLogFileNameFormat);
  fLogFileNameFormat := aLogFileNameFormat;
  fDailyRotate := fLogFileNameFormat.IndexOf('{date}') >= 0;
  if Assigned(aEncoding) then
    fEncoding := aEncoding
  else
    fEncoding := TEncoding.DEFAULT;
end;

function TLoggerProFileAppenderBase.CreateWriter(const aFileName: string): TStreamWriter;
var
  lFileStream: TFileStream;
  lFileAccessMode: Word;
  lRetries: Integer;
begin
  lFileAccessMode := fmOpenWrite or fmShareDenyNone;
  if not TFile.Exists(aFileName) then
    lFileAccessMode := lFileAccessMode or fmCreate;

  // If the file si still blocked by a precedent execution or
  // for some other reasons, we try to access the file for 5 times.
  // If after 5 times (with a bit of delay in between) the file is still
  // locked, then the exception is raised.
  lRetries := 0;
  while true do
  begin
    try
      lFileStream := TFileStream.Create(aFileName, lFileAccessMode);
      try
        lFileStream.Seek(0, TSeekOrigin.soEnd);
        Result := TLoggerProStreamWriter.Create(lFileStream, fEncoding, 32);
        Result.AutoFlush := true;
        Result.OwnStream;
        TLoggerProStreamWriter(Result).FileCreationDate := GetFileDate(aFileName);
        Break;
      except
        lFileStream.Free;
        raise;
      end;
    except
      if lRetries = RETRY_COUNT then
      begin
        raise;
      end
      else
      begin
        Inc(lRetries);
        Sleep(RETRY_DELAY); // just wait a little bit
      end;
    end;
  end;
end;

{ TLoggerProFileAppender }

procedure TLoggerProFileAppender.AddWriter(const aLogTag:string; var aWriter: TStreamWriter; var aLogFileName: string);
begin
  aLogFileName := GetLogFileName(aLogTag, '',0);
  aWriter := CreateWriter(aLogFileName);
  fWritersDictionary.Add(aLogTag, aWriter);
end;

function TLoggerProFileAppenderBase.RotateLogNeeded(aLogWriter: TStreamWriter):
    Boolean;
begin
  if ((fMaxFileSizeInKiloByte> 0) and (aLogWriter.BaseStream.Size > fMaxFileSizeInKiloByte * 1024))
    or ((fDailyRotate) and (not TLoggerProStreamWriter(aLogWriter).FileCreationDate.IsSameDay(Now())))
    then
    Result := True
  else
    Result := False;
end;

procedure TLoggerProFileAppenderBase.EmitEndRotateLogItem(aWriter: TStreamWriter);
begin
  WriteToStream(aWriter, '#[ROTATE LOG ' + datetimetostr(Now, FormatSettings) + ']');
end;

procedure TLoggerProFileAppenderBase.EmitStartRotateLogItem(aWriter: TStreamWriter);
begin
  WriteToStream(aWriter, '#[START LOG ' + datetimetostr(Now, FormatSettings) + ']');
end;

function TLoggerProFileAppenderBase.GetFileDate(const aFileName: string): TDateTime;
begin
  Result := 0;
  if not fDailyRotate then
    Exit;
  try
    Result := TFile.GetCreationTime (aFileName);
  except
    Result := 0;
  end;
end;

function TLoggerProFileAppenderBase.GetFileDateFormatted(const aFileName: string): string;
var Date : tDateTime;
begin
  Result := '';
  Date := GetFileDate(aFileName);
  if Date <= 0 then
    Exit;
  Result := FormatDateTime (DEFAULT_DAILYROTATE_FILEDATE_FORMAT, Date);
end;

function TLoggerProFileAppenderBase.FindLogFileByNumber(const aTag: string; const aFileNumber: Integer): string;
var
  SearchRec: TSearchRec;
begin
  Result := GetLogFileName(aTag, '*', aFileNumber);
  if findfirst (Result, faAnyFile, SearchRec) = 0 then
    Result := TPath.GetDirectoryName (Result) + PathDelim + SearchRec.Name
  else
    Result := '';
  FindClose (SearchRec);
  if Result <> '' then
    Exit;
end;

procedure TLoggerProFileAppender.RotateLog(const aLogTag: string; var aWriter:
    TStreamWriter);
var
  lLogFileName: string;
begin
  EmitEndRotateLogItem(aWriter);
  // remove the writer during rename
  fWritersDictionary.Remove(aLogTag);
  RotateFile(aLogTag, lLogFileName);
  // re-create the writer
  AddWriter(aLogTag, aWriter, lLogFileName);
  EmitStartRotateLogItem(aWriter);
end;

procedure TLoggerProFileAppender.Setup;
begin
  inherited;
  fWritersDictionary := TObjectDictionary<string, TStreamWriter>.Create([doOwnsValues]);
end;

procedure TLoggerProFileAppender.TearDown;
begin
  fWritersDictionary.Free;
  inherited;
end;

procedure TLoggerProFileAppender.WriteLog(const aLogItem: TLogItem);
var
  lWriter: TStreamWriter;
  lLogFileName:string;
begin
  if not fWritersDictionary.TryGetValue(aLogItem.LogTag, lWriter) then
  begin
    AddWriter(aLogItem.LogTag, lWriter, lLogFileName);
  end;

  if RotateLogNeeded(lWriter) then
    RotateLog(aLogItem.LogTag, lWriter);

  InternalWriteLog(lWriter, aLogItem);

end;

{ TLoggerProSimpleFileAppender }

procedure TLoggerProSimpleFileAppender.CheckLogFileNameFormat(const LogFileNameFormat: String);
begin
  //DEFAULT_FILENAME_FORMAT = '{module}.{number}.{tag}.log';
  if not LogFileNameFormat.Contains('{number}') then
  begin
    raise ELoggerPro.CreateFmt('Wrong FileFormat [%s] - [HINT] A correct file format for %s requires {number} placeholder ({module} is optional). A valid file format is : %s',
      [
        ClassName,
        LogFileNameFormat,
        TLoggerProSimpleFileAppender.DEFAULT_FILENAME_FORMAT
      ]);
  end;
end;

constructor TLoggerProSimpleFileAppender.Create(aMaxBackupFileCount, aMaxFileSizeInKiloByte: Integer;
  aLogsFolder: string; aLogFileNameFormat: String;
  aLogItemRenderer: ILogItemRenderer;
  aEncoding: TEncoding);
begin
  inherited Create(
    aMaxBackupFileCount,
    aMaxFileSizeInKiloByte,
    aLogsFolder,
    aLogFileNameFormat,
    aLogItemRenderer,
    aEncoding);
end;

procedure TLoggerProSimpleFileAppender.RotateLog;
var
  lLogFileName: string;
begin
  EmitEndRotateLogItem(fFileWriter);
  // remove the writer during rename
  fFileWriter.Free;
  RotateFile('', lLogFileName);
  // re-create the writer
  fFileWriter := CreateWriter(GetLogFileName('', '', 0));
  EmitStartRotateLogItem(fFileWriter);
end;

procedure TLoggerProSimpleFileAppender.Setup;
begin
  inherited;
  fFileWriter := CreateWriter(GetLogFileName('', '', 0));
end;

procedure TLoggerProSimpleFileAppender.TearDown;
begin
  fFileWriter.Free;
  inherited;
end;

procedure TLoggerProSimpleFileAppender.WriteLog(const aLogItem: TLogItem);
begin
  if RotateLogNeeded(fFileWriter) then
    RotateLog;
  InternalWriteLog(fFileWriter, aLogItem);
end;

end.

