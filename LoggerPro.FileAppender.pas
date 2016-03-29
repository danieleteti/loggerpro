unit LoggerPro.FileAppender;
{ <@abstract(The unit to include if you want to use @link(TLoggerProFileAppender))
  @author(Daniele Teti) }

interface

uses LoggerPro, System.Classes, System.SysUtils, System.Generics.Collections;

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

  TFileAppenderOption = (IncludePID, LogsInTheSameFolder);
  TFileAppenderOptions = set of TFileAppenderOption;

  TLoggerProFileAppender = class(TInterfacedObject, ILogAppender)
  private
    FFormatSettings: TFormatSettings;
    FWritersDictionary: TObjectDictionary<String, TStreamWriter>;
    FMaxBackupFileCount: Integer;
    FMaxFileSizeInKiloByte: Integer;
    FLogFormat: string;
    FFileAppenderOptions: TFileAppenderOptions;
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
  public const
    { @abstract(Defines the default format string used by the @link(TLoggerProFileAppender).)
      The positional parameters are the followings:
      @orderedList(
      @itemSetNumber 0
      @item TimeStamp
      @item ThreadID
      @item LogType
      @item LogMessage
      @item LogTag
      )
    }
    DEFAULT_LOG_FORMAT = '%0:s [TID %1:-8d][%2:-10s] %3:s [%4:s]';
    { @abstract(Defines number of log file set to mantain during logs rotation) }
    DEFAULT_MAX_BACKUP_FILE_COUNT = 5;
    { @abstract(Defines the max size of each log file)
      The actual meaning is: "If the file size is > than @link(DEFAULT_MAX_FILE_SIZE_KB) then rotate logs. }
    DEFAULT_MAX_FILE_SIZE_KB = 1000;
    constructor Create(aMaxBackupFileCount
      : Integer = DEFAULT_MAX_BACKUP_FILE_COUNT;
      aMaxFileSizeInKiloByte: Integer = DEFAULT_MAX_FILE_SIZE_KB;
      aFileAppenderOptions: TFileAppenderOptions =
      [TFileAppenderOption.LogsInTheSameFolder];
      aLogFormat: String = DEFAULT_LOG_FORMAT);
    procedure Setup;
    procedure TearDown;
    procedure WriteLog(const aLogItem: TLogItem); overload;
  end;

implementation

uses
  System.IOUtils, Winapi.Windows;

{ TLoggerProFileAppender }

function TLoggerProFileAppender.GetLogFileName(const aTag: String;
  const aFileNumber: Integer): String;
var
  lFormat, lExt: string;
  lModuleName: string;
  lPath: string;
begin
  lFormat := '.%2.2d.%s.log';
  lModuleName := TPath.GetFileNameWithoutExtension(GetModuleName(HInstance));

  if TFileAppenderOption.IncludePID in FFileAppenderOptions then
    lFormat := '.PID-' + IntToStr(GetCurrentProcessID) + lFormat;

  if not(TFileAppenderOption.LogsInTheSameFolder in FFileAppenderOptions) then
  begin
    lPath := TPath.Combine(TPath.GetHomePath, lModuleName + '_log');
    TDirectory.CreateDirectory(lPath);
  end
  else
  begin
    lPath := TPath.GetDirectoryName(GetModuleName(HInstance));
  end;

  lExt := Format(lFormat, [aFileNumber, aTag]);
  Result := TPath.Combine(lPath, ChangeFileExt(lModuleName, lExt));
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
  aMaxFileSizeInKiloByte: Integer; aFileAppenderOptions: TFileAppenderOptions;
  aLogFormat: String);
begin
  inherited Create;
  FMaxBackupFileCount := aMaxBackupFileCount;
  FMaxFileSizeInKiloByte := aMaxFileSizeInKiloByte;
  FLogFormat := aLogFormat;
  FFileAppenderOptions := aFileAppenderOptions;
end;

function TLoggerProFileAppender.CreateWriter(const aFileName: String)
  : TStreamWriter;
var
  lFileStream: TFileStream;
  lFileAccessMode: Word;
begin
  lFileAccessMode := fmOpenWrite or fmShareDenyWrite;
  if not TFile.Exists(aFileName) then
    lFileAccessMode := lFileAccessMode or fmCreate;

  lFileStream := TFileStream.Create(aFileName, lFileAccessMode);
  try
    lFileStream.Seek(0, TSeekOrigin.soEnd);
    Result := TStreamWriter.Create(lFileStream, TEncoding.ANSI, 1024);
    Result.AutoFlush := False;
    Result.OwnStream;
  except
    lFileStream.Free;
    raise;
  end;
end;

end.
