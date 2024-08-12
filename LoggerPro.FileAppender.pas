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
  System.SysUtils,
  System.JSON;

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


  // valid placeholders for log file parts
  TLogFileNamePart = (lfnModule, lfnNumber, lfnTag, lfnPID, lfnDate);
  TLogFileNameParts = set of TLogFileNamePart;

type
  ///<summary> handles  file rotation and file name formats</summary>
  ILogFileRotator = interface
    ['{4E495CF4-793F-4D7E-8BC1-5257FB11370D}']
    procedure RotateFiles(const aLogTag: string; out aNewFileName: string);
    procedure CheckLogFileNameFormat(const LogFileNameFormat: string);
    function GetLogFileName(const aTag: string; const aFileNumber: Integer): string;
  end;

  { forward declaration }
  TLoggerProFileAppenderBase = class;

  TLogFileRotatorBase = class abstract(TInterfacedObject, ILogFileRotator)
  protected
    FAppender: TLoggerProFileAppenderBase;
    FRequiredFileNameParts: TLogFileNameParts;
    procedure Setup(Config: TJSONObject); virtual; abstract;
    procedure RetryMove(const aFileSrc, aFileDest: string);
    procedure RetryDelete(const aFileSrc: string);
    { ILogFileMaintainer }
    procedure RotateFiles(const aLogTag: string; out aNewFileName: string);  virtual; abstract;
    function GetLogFileName(const aTag: string; const aFileNumber: Integer): string; virtual;
    procedure CheckLogFileNameFormat(const LogFileNameFormat: string); virtual;
  public
    class function GetDefaultLogFileMaintainer(Appender: TLoggerProFileAppenderBase; AMaxFileCount: Integer = 10): ILogFileRotator;
    constructor Create(Appender: TLoggerProFileAppenderBase; AConfiguration: string); virtual;
  end;

  TLogFileMaintainerClass = class of TLogFileRotatorBase;

  ///<summary> Rotate / purge log files by file count </summary>
  TLogFileRotatorByCount = class(TLogFileRotatorBase)
  private
    FMaxBackupFileCount: Integer;
  protected
    procedure Setup(Config: TJSONObject); override;
    procedure RotateFiles(const aLogTag: string; out aNewFileName: string); override;
  public
    const
    { @abstract(Defines number of log file set to maintain during logs rotation) }
      DEFAULT_MAX_BACKUP_FILE_COUNT = 5;
    constructor Create(Appender: TLoggerProFileAppenderBase; AConfiguration: string); override;
  end;

  /// <summary>Rotate / purge log files by number of days</summary>
  TLogFileRotatorByDate = class(TLogFileRotatorBase)
  private
    FMaxFileDays: Integer;
  protected
    procedure Setup(Config: TJSONObject); override;
    procedure RotateFiles(const aLogTag: string; out aNewFileName: string); override;
    function GetLogFileName(const aTag: string; const aFileNumber: Integer): string; override;
  public const
    { @abstract(Defines number of days of log files to maintain during logs rotation) }
    DEFAULT_MAX_BACKUP_FILE_DAYS = 7;
    constructor Create(Appender: TLoggerProFileAppenderBase; AConfiguration: string); override;
  end;


  { @abstract(The base class for different file appenders)
    Do not use this class directly, but one of TLoggerProFileAppender or TLoggerProSimpleFileAppender.
    Check the sample @code(file_appender.dproj)
  }

  TLoggerProFileAppenderBase = class(TLoggerProAppenderBase)
  private
    FLogFileRotator: ILogFileRotator;
    fMaxFileSizeInKiloByte: Integer;
    fLogFileNameFormat: string;
    fLogsFolder: string;
    fEncoding: TEncoding;
    function CreateWriter(const aFileName: string): TStreamWriter;
  protected
    property LogsFolder: string read fLogsFolder;
    property LogFileNameFormat: string read fLogFileNameFormat;
    procedure CheckLogFileNameFormat(const LogFileNameFormat: string);
    procedure EmitStartRotateLogItem(aWriter: TStreamWriter); virtual;
    procedure EmitEndRotateLogItem(aWriter: TStreamWriter); virtual;
    function GetLogFileName(const aTag: string; const aFileNumber: Integer): string;
    procedure WriteToStream(const aStreamWriter: TStreamWriter; const aValue: string); inline;
    procedure RotateFile(const aLogTag: string; out aNewFileName: string);
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

    { @abstract(Defines the max size of each log file)
      The actual meaning is: "If the file size is > than @link(DEFAULT_MAX_FILE_SIZE_KB) then rotate logs. }
    DEFAULT_MAX_FILE_SIZE_KB = 1000;
    { @abstract(Milliseconds to wait between the RETRY_COUNT times. }
    RETRY_DELAY = 200;
    { @abstract(How many times do we have to retry if the file is locked?. }
    RETRY_COUNT = 5;
    constructor Create(
      aMaxBackupFileCount: Integer = TLogFileRotatorByCount.DEFAULT_MAX_BACKUP_FILE_COUNT;
      aMaxFileSizeInKiloByte: Integer = TLoggerProFileAppenderBase.DEFAULT_MAX_FILE_SIZE_KB;
      aLogsFolder: string = '';
      aLogFileNameFormat: string = TLoggerProFileAppenderBase.DEFAULT_FILENAME_FORMAT;
      aLogItemRenderer: ILogItemRenderer = nil;
      aEncoding: TEncoding = nil);
       reintroduce; overload; virtual;

    constructor Create(
      aLogFileMaintainer: TLogFileMaintainerClass;
      aMaintainerConfiguration: string ='{"MaxBackupFileDays":7}';
      aMaxFileSizeInKiloByte: Integer = TLoggerProFileAppenderBase.DEFAULT_MAX_FILE_SIZE_KB;
      aLogsFolder: string = '';
      aLogFileNameFormat: string = TLoggerProFileAppenderBase.DEFAULT_FILENAME_FORMAT;
      aLogItemRenderer: ILogItemRenderer = nil;
      aEncoding: TEncoding = nil);
      reintroduce; overload; virtual;
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
    procedure RotateLog(const aLogTag: string; aWriter: TStreamWriter);
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
  public
  const
    DEFAULT_FILENAME_FORMAT = '{module}.{number}.log';
    procedure Setup; override;
    procedure TearDown; override;
    procedure WriteLog(const aLogItem: TLogItem); overload; override;
    constructor Create(
      aMaxBackupFileCount: Integer = TLogFileRotatorByCount.DEFAULT_MAX_BACKUP_FILE_COUNT;
      aMaxFileSizeInKiloByte: Integer = TLoggerProFileAppenderBase.DEFAULT_MAX_FILE_SIZE_KB;
      aLogsFolder: string = '';
      aLogFileNameFormat: string = TLoggerProSimpleFileAppender.DEFAULT_FILENAME_FORMAT;
      aLogItemRenderer: ILogItemRenderer = nil;
      aEncoding: TEncoding = nil);
      overload; override;
  end;

implementation

uses
  System.IOUtils,
  System.StrUtils,
  System.Math,
  System.DateUtils,
  idGlobal,
  System.Rtti
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
  FLogFileRotator.CheckLogFileNameFormat(LogFileNameFormat);
end;

{ TLoggerProFileAppenderBase }

function TLoggerProFileAppenderBase.GetLogFileName(const aTag: string; const aFileNumber: Integer): string;
begin
  Result := FLogFileRotator.GetLogFileName(aTag, aFileNumber);
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

procedure TLoggerProFileAppenderBase.RotateFile(const aLogTag: string; out aNewFileName: string);
begin
  FLogFileRotator.RotateFiles(aLogTag, aNewFileName);
end;

constructor TLoggerProFileAppenderBase.Create(
  aMaxBackupFileCount: Integer;
  aMaxFileSizeInKiloByte: Integer;
  aLogsFolder: string;
  aLogFileNameFormat: string;
  aLogItemRenderer: ILogItemRenderer;
  aEncoding: TEncoding);
begin
  Create(TLogFileRotatorByCount, Format('{"MaxBackupFileCount":%d}', [aMaxBackupFileCount]),
    aMaxFileSizeInKiloByte, aLogsFolder, aLogFileNameFormat, aLogItemRenderer, aEncoding);
end;

constructor TLoggerProFileAppenderBase.Create(
  aLogFileMaintainer: TLogFileMaintainerClass;
  aMaintainerConfiguration: string;
  aMaxFileSizeInKiloByte: Integer;
  aLogsFolder, aLogFileNameFormat: string;
  aLogItemRenderer: ILogItemRenderer;
  aEncoding: TEncoding);
begin
  inherited Create(aLogItemRenderer);
  fLogsFolder := aLogsFolder;
  fMaxFileSizeInKiloByte := aMaxFileSizeInKiloByte;

  FLogFileRotator := aLogFileMaintainer.Create(Self, aMaintainerConfiguration);

  CheckLogFileNameFormat(aLogFileNameFormat);
  fLogFileNameFormat := aLogFileNameFormat;
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

  // If the file is still blocked by a precedent execution or
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
        Result := TStreamWriter.Create(lFileStream, fEncoding, 32);
        Result.AutoFlush := true;
        Result.OwnStream;
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
  aLogFileName := GetLogFileName(aLogTag, 0);
  aWriter := CreateWriter(aLogFileName);
  fWritersDictionary.Add(aLogTag, aWriter);
end;

procedure TLoggerProFileAppenderBase.EmitEndRotateLogItem(aWriter: TStreamWriter);
begin
  WriteToStream(aWriter, '#[ROTATE LOG ' + datetimetostr(Now, FormatSettings) + ']');
end;

procedure TLoggerProFileAppenderBase.EmitStartRotateLogItem(aWriter: TStreamWriter);
begin
  WriteToStream(aWriter, '#[START LOG ' + datetimetostr(Now, FormatSettings) + ']');
end;

procedure TLoggerProFileAppender.RotateLog(const aLogTag: string; aWriter: TStreamWriter);
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

  InternalWriteLog(lWriter, aLogItem);

  if lWriter.BaseStream.Size > fMaxFileSizeInKiloByte * 1024 then
  begin
    RotateLog(aLogItem.LogTag, lWriter);
  end;
end;

{ TLoggerProSimpleFileAppender }
constructor TLoggerProSimpleFileAppender.Create(aMaxBackupFileCount, aMaxFileSizeInKiloByte: Integer;
  aLogsFolder: string; aLogFileNameFormat: string;
  aLogItemRenderer: ILogItemRenderer;
  aEncoding: TEncoding);
begin
  Create(TLogFileRotatorByCount, Format('{"MaxBackupFileCount":%d}', [aMaxBackupFileCount]),
    aMaxFileSizeInKiloByte, aLogsFolder, aLogFileNameFormat, aLogItemRenderer, aEncoding);
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
  fFileWriter := CreateWriter(lLogFileName);
  EmitStartRotateLogItem(fFileWriter);
end;

procedure TLoggerProSimpleFileAppender.Setup;
begin
  inherited;
  fFileWriter := CreateWriter(GetLogFileName('', 0));
end;

procedure TLoggerProSimpleFileAppender.TearDown;
begin
  fFileWriter.Free;
  inherited;
end;

procedure TLoggerProSimpleFileAppender.WriteLog(const aLogItem: TLogItem);
begin
  InternalWriteLog(fFileWriter, aLogItem);
  if fFileWriter.BaseStream.Size > fMaxFileSizeInKiloByte * 1024 then
  begin
    RotateLog;
  end;
end;


{ TLogFileRotatorBase }
class function TLogFileRotatorBase.GetDefaultLogFileMaintainer(Appender: TLoggerProFileAppenderBase; AMaxFileCount: Integer): ILogFileRotator;
begin
  Result := TLogFileRotatorByCount.Create(Appender, '');
end;

procedure TLogFileRotatorBase.CheckLogFileNameFormat(const LogFileNameFormat: string);

  function GetFilePartEnumValue(Value: TLogFileNamePart): string;
  begin
    Result := Format('{%s}', [Copy(TRttiEnumerationType.GetName<TLogFileNamePart>(Value), 4).ToLower]);
  end;

  function GetMissingFileNameParts: string;
  var
    NamePart: string;
  begin
    for var FileNamePart := Low(TLogFileNamePart) to High(TLogFileNamePart) do
    begin
      NamePart := GetFilePartEnumValue(FileNamePart);
      if (FileNamePart in FRequiredFileNameParts) and
        not LogFileNameFormat.Contains(NamePart) then
          Result := Result +NamePart +',';
    end;
    if not Result.IsEmpty then
      SetLength(Result, Length(Result) -1);
  end;

var
  MissingParts: string;
begin
  MissingParts := GetMissingFileNameParts;
  if not MissingParts.IsEmpty then
  begin
    raise ELoggerPro.CreateFmt(
      'Wrong FileFormat [%s] - [HINT] A correct file format for %s requires %s placeholders. A valid file format is like : %s',
      [
        LogFileNameFormat,
        FAppender.ClassName,
        MissingParts,
        TLoggerProFileAppenderBase.DEFAULT_FILENAME_FORMAT
      ]);
  end;
end;

constructor TLogFileRotatorBase.Create(Appender: TLoggerProFileAppenderBase;
   AConfiguration: string);
var
  Config: TJSONObject;
begin
  inherited Create;
  FAppender := Appender;
  Config:= TJSONObject.ParseJSONValue(AConfiguration) as TJSONObject;
  try
    Setup(Config);
  finally
    Config.Free;
  end;
end;

procedure TLogFileRotatorBase.RetryDelete(const aFileSrc: string);
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
      TFile.Delete(aFileSrc);
      if not TFile.Exists(aFileSrc) then
      begin
        Break;
      end;
    except
      on E: Exception do
      begin
        Inc(lRetries);
        Sleep(100);
      end;
    end;
  until lRetries = MAX_RETRIES;

  if lRetries = MAX_RETRIES then
    raise ELoggerPro.CreateFmt('Cannot delete file %s', [aFileSrc]);
end;

procedure TLogFileRotatorBase.RetryMove(const aFileSrc, aFileDest: string);
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
        Sleep(100);
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

function TLogFileRotatorBase.GetLogFileName(const aTag: string; const aFileNumber: Integer): string;
var
  lModuleName: string;
  lPath: string;
  lFormat: string;
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
  lFormat := FAppender.LogFileNameFormat;

  lPath := FAppender.LogsFolder;
  lFormat := lFormat
    .Replace('{module}', lModuleName, [rfReplaceAll])
// todo: what happens when more than one hundred files
// should this be linked to max file count ?
    .Replace('{number}', aFileNumber.ToString.PadLeft(2,'0') , [rfReplaceAll])
    .Replace('{tag}', aTag, [rfReplaceAll])
    .Replace('{date}', FormatDateTime('yyyy-mm-dd', Now), [rfReplaceAll])
    .Replace('{pid}', CurrentProcessId.ToString.PadLeft(8,'0'), [rfReplaceAll]);
  Result := TPath.Combine(lPath, lFormat);
end;


{ TLogFileRotatorByCount }
constructor TLogFileRotatorByCount.Create(Appender: TLoggerProFileAppenderBase;
  AConfiguration: string);
begin
  inherited Create(Appender, AConfiguration);
  FRequiredFileNameParts:= [lfnModule, lfnNumber];
end;

procedure TLogFileRotatorByCount.RotateFiles(const aLogTag: string; out aNewFileName: string);
var
  lRenamedFile: string;
  I: Integer;
  lCurrentFileName: string;
begin
  aNewFileName := FAppender.GetLogFileName(aLogTag, 0);
  // remove the last file of backup set
  lRenamedFile := FAppender.GetLogFileName(aLogTag, fMaxBackupFileCount - 1);
  if TFile.Exists(lRenamedFile) then
  begin
    TFile.Delete(lRenamedFile);
    if TFile.Exists(lRenamedFile) then // double check for slow file systems
    begin
      RetryDelete(lRenamedFile);
    end;
  end;
  // shift the files names
  for I := fMaxBackupFileCount - 1 downto 1 do
  begin
    lCurrentFileName := FAppender.GetLogFileName(aLogTag, I);
    lRenamedFile := FAppender.GetLogFileName(aLogTag, I + 1);
    if TFile.Exists(lCurrentFileName) then
    begin
      RetryMove(lCurrentFileName, lRenamedFile);
    end;
  end;
  lRenamedFile := FAppender.GetLogFileName(aLogTag, 1);
  RetryMove(aNewFileName, lRenamedFile);
end;

procedure TLogFileRotatorByCount.Setup(Config: TJSONObject);
begin
  if not Config.TryGetValue<Integer>('MaxBackupFileCount', FMaxBackupFileCount) then
    FMaxBackupFileCount := DEFAULT_MAX_BACKUP_FILE_COUNT;
  FMaxBackupFileCount := Max(1, FMaxBackupFileCount);
end;

{ TLogFileRotatorByDate }
constructor TLogFileRotatorByDate.Create(Appender: TLoggerProFileAppenderBase; AConfiguration: string);
begin
  inherited Create(Appender, AConfiguration);
  FRequiredFileNameParts := [lfnModule, lfnNumber, lfnDate];
end;

procedure TLogFileRotatorByDate.RotateFiles(const aLogTag: string; out aNewFileName: string);
type
 TTLogFileNamePartLookup = array[TLogFileNamePart] of Integer;

  function GetCurrentFileDateString(Index: Integer): string;
  var
    FileNameParts: TArray<string>;
  begin
    FileNameParts := FAppender.GetLogFileName(aLogTag, 0).Split(['.']);
    Result := FileNameParts[Index];
  end;

  function CreateLookupArrayForLogFileNameFormat: TTLogFileNamePartLookup;
  { get the relative position of the file name format placeholders in the LogFileNameFormat field}
  var
    Parts: TArray<string>;
    EnumStr: string;
    Enum: TLogFileNamePart;
  begin
    Result := Default(TTLogFileNamePartLookup);
    Parts := FAppender.LogFileNameFormat.Split(['.']);
    for var J := Low(Parts) to High(Parts)  do
    begin
      EnumStr := 'lfn' + Copy(Parts[J], 2, Length(Parts[J]) - 2);
      Enum := TRttiEnumerationType.GetValue<TLogFileNamePart>(EnumStr);
      if (Enum >= Low(TLogFileNamePart)) and (Enum <= High(TLogFileNamePart)) then
        Result[Enum] := J;
    end;
  end;

var
  ModuleName: string;
  FilesToDelete: TArray<string>;
  FileDateThreshold: TDate;
  CurrentFileDateString: string;
  MaxFileVersion: Integer;
  FilePartIndex: TTLogFileNamePartLookup;

begin
  { delete all files older than a certain date }
  FileDateThreshold := Trunc(Now) - FMaxFileDays;
  FilesToDelete := TDirectory.GetFiles(FAppender.LogsFolder,
    function(const Path: string; const SearchRec: TSearchRec): Boolean
    begin
      Result := SearchRec.TimeStamp < FileDateThreshold;
    end);
  for var I := Low(FilesToDelete) to High(FilesToDelete) do
  begin
    if TFile.Exists(FilesToDelete[I]) then
      try
        TFile.Delete(FilesToDelete[I]);
        if TFile.Exists(FilesToDelete[I]) then // double check for slow file systems
        begin
          RetryDelete(FilesToDelete[I]);
        end;
      except
        { no point retrying, file monitoring will alert us when we have too many files }
      end;
  end;

  { files will look like module.date.xx.log, we will just roll the xx part forward }
  FilePartIndex := CreateLookupArrayForLogFileNameFormat;
  ModuleName := TPath.GetFileNameWithoutExtension(GetModuleName(HInstance));
  CurrentFileDateString := GetCurrentFileDateString(FilePartIndex[lfnDate]);

  MaxFileVersion := 0;
  TDirectory.GetFiles(FAppender.LogsFolder,
    function(const Path: string; const SearchRec: TSearchRec): Boolean
    var
      NameParts: TArray<string>;
    begin
      { only want files with module and date in filename root }
      NameParts := string(SearchRec.Name).Split(['.']);
      if Length(NameParts) > 2 then
      begin
        if SameText(NameParts[FilePartIndex[lfnModule]], ModuleName)
          and SameText(NameParts[FilePartIndex[lfnDate]], CurrentFileDateString) then
          MaxFileVersion := Max(MaxFileVersion, StrToIntDef(NameParts[FilePartIndex[lfnNumber]], 0));
      end;
      Result := False; { NB: Predicate does not return any files }
    end);
  Inc(MaxFileVersion);
  aNewFileName := FAppender.GetLogFileName(aLogTag, MaxFileVersion);
end;

procedure TLogFileRotatorByDate.Setup(Config: TJSONObject);
begin
  if not Config.TryGetValue<Integer>('MaxBackupFileDays', FMaxFileDays) then
    FMaxFileDays := DEFAULT_MAX_BACKUP_FILE_DAYS;
  FMaxFileDays := Max(1, FMaxFileDays);
end;

function TLogFileRotatorByDate.GetLogFileName(const aTag: string; const aFileNumber: Integer): string;
begin
  Result := inherited;
  Result := Result.Replace('{date}', FormatDateTime('yyyy-mm-dd', Now), [rfReplaceAll]);
end;

end.

