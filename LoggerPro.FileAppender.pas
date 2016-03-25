unit LoggerPro.FileAppender;

interface

uses LoggerPro, System.Classes, System.SysUtils, System.Generics.Collections;

const
  {
    aLogItem.TimeStamp,
    aLogItem.ThreadID,
    aLogItem.LogTypeAsString,
    aLogItem.LogMessage,
    aLogItem.LogTag
  }
  DEFAULT_LOG_FORMAT = '%0:s [TID %1:-8d][%2:-10s] %3:s [%4:s]';
  DEFAULT_MAX_BACKUP_FILE_COUNT = 5;
  DEFAULT_MAX_FILE_SIZE_KB = 1000;

type
  TLoggerProFileAppender = class(TInterfacedObject, ILogAppender)
  private
    FFormatSettings: TFormatSettings;
    FWritersDictionary: TObjectDictionary<String, TStreamWriter>;
    FMaxBackupFileCount: Integer;
    FMaxFileSizeInKiloByte: Integer;
    FLogFormat: string;
    function CreateWriter(const aFileName: String): TStreamWriter;
    procedure AddWriter(const aLogItem: TLogItem; var lWriter: TStreamWriter;
      var lLogFileName: string);
    procedure RotateLog(const aLogItem: TLogItem; lWriter: TStreamWriter);
    procedure RetryMove(const aFileSrc, aFileDest: String);
  protected
    function GetLogFileName(const aTag: String;
      const aFileNumber: Integer): String;
    procedure WriteLog(const aStreamWriter: TStreamWriter;
      const aValue: String); overload;
  public
    constructor Create(aMaxBackupFileCount
      : Integer = DEFAULT_MAX_BACKUP_FILE_COUNT;
      aMaxFileSizeInKiloByte: Integer = DEFAULT_MAX_FILE_SIZE_KB;
      aLogFormat: String = DEFAULT_LOG_FORMAT);
    // ILogAppender
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem); overload;
  end;

implementation

uses
  System.IOUtils;

{ TLoggerProFileAppender }

function TLoggerProFileAppender.GetLogFileName(const aTag: String;
  const aFileNumber: Integer): String;
var
  lExt: string;
begin
  lExt := Format('.%2.2d.%s.log', [aFileNumber, aTag]);
  Result := ChangeFileExt(GetModuleName(HInstance), lExt);
end;

procedure TLoggerProFileAppender.Setup;
begin
  FFormatSettings.DateSeparator := '-';
  FFormatSettings.TimeSeparator := ':';
  FFormatSettings.ShortDateFormat := 'YYY-MM-DD HH:NN:SS:ZZZ';
  FFormatSettings.ShortTimeFormat := 'HH:NN:SS';
  FWritersDictionary := TObjectDictionary<String, TStreamWriter>.Create
    ([doOwnsValues]);
end;

procedure TLoggerProFileAppender.TearDown;
begin
  FWritersDictionary.Free;
end;

procedure TLoggerProFileAppender.WriteLog(const aStreamWriter: TStreamWriter;
  const aValue: String);
begin
  aStreamWriter.WriteLine(aValue);
  aStreamWriter.Flush;
end;

procedure TLoggerProFileAppender.WriteLog(const aLogItem: TLogItem);
var
  lWriter: TStreamWriter;
  lLogFileName: string;
begin
  if not FWritersDictionary.TryGetValue(aLogItem.LogTag, lWriter) then
  begin
    AddWriter(aLogItem, lWriter, lLogFileName);
  end;
  WriteLog(lWriter, Format(FLogFormat, [datetimetostr(aLogItem.TimeStamp,
    FFormatSettings), aLogItem.ThreadID, aLogItem.LogTypeAsString,
    aLogItem.LogMessage, aLogItem.LogTag]));

  if lWriter.BaseStream.Size > FMaxFileSizeInKiloByte * 1024 then
  begin
    RotateLog(aLogItem, lWriter);
  end;
end;

procedure TLoggerProFileAppender.RetryMove(const aFileSrc, aFileDest: String);
var
  lRetries: Integer;
const
  MAX_RETRIES = 5;
begin
  lRetries := 0;
  repeat
    try
      Sleep(50); // the incidence of "Locked file goes to nearly zero..."
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

procedure TLoggerProFileAppender.RotateLog(const aLogItem: TLogItem;
  lWriter: TStreamWriter);
var
  lLogFileName: string;
  lRenamedFile: string;
  I: Integer;
  lCurrentFileName: string;
begin
  WriteLog(lWriter, '#[ROTATE LOG ' + datetimetostr(Now,
    FFormatSettings) + ']');
  FWritersDictionary.Remove(aLogItem.LogTag);
  lLogFileName := GetLogFileName(aLogItem.LogTag, 0);
  // remove the last file of backup set
  lRenamedFile := GetLogFileName(aLogItem.LogTag, FMaxBackupFileCount);
  if TFile.Exists(lRenamedFile) then
    TFile.Delete(lRenamedFile);
  // shift the files names
  for I := FMaxBackupFileCount - 1 downto 1 do
  begin
    lCurrentFileName := GetLogFileName(aLogItem.LogTag, I);
    lRenamedFile := GetLogFileName(aLogItem.LogTag, I + 1);
    if TFile.Exists(lCurrentFileName) then
      RetryMove(lCurrentFileName, lRenamedFile);

  end;
  lRenamedFile := GetLogFileName(aLogItem.LogTag, 1);
  RetryMove(lLogFileName, lRenamedFile);
  // read the writer
  AddWriter(aLogItem, lWriter, lLogFileName);
  WriteLog(lWriter, '#[START LOG ' + datetimetostr(Now, FFormatSettings) + ']');
end;

procedure TLoggerProFileAppender.AddWriter(const aLogItem: TLogItem;
  var lWriter: TStreamWriter; var lLogFileName: string);
begin
  lLogFileName := GetLogFileName(aLogItem.LogTag, 0);
  lWriter := CreateWriter(lLogFileName);
  FWritersDictionary.Add(aLogItem.LogTag, lWriter);
end;

constructor TLoggerProFileAppender.Create(aMaxBackupFileCount: Integer;
  aMaxFileSizeInKiloByte: Integer; aLogFormat: String);
begin
  inherited Create;
  FMaxBackupFileCount := aMaxBackupFileCount;
  FMaxFileSizeInKiloByte := aMaxFileSizeInKiloByte;
  FLogFormat := aLogFormat;
end;

function TLoggerProFileAppender.CreateWriter(const aFileName: String): TStreamWriter;
var
  lFileStream: TFileStream;
  lFileAccessMode: Word;
begin
  lFileAccessMode := 0;

  if not TFile.Exists(aFileName) then
    lFileStream := TFileStream.Create(aFileName, fmCreate or fmOpenWrite or
      fmShareDenyWrite)
  else
    lFileStream := TFileStream.Create(aFileName, fmOpenWrite or
      fmShareDenyWrite);
  try
    lFileStream.Seek(0, TSeekOrigin.soEnd);
    Result := TStreamWriter.Create(lFileStream, TEncoding.ANSI, 512);
    Result.AutoFlush := False;
    Result.OwnStream;
  except
    lFileStream.Free;
    raise;
  end;
end;

end.
