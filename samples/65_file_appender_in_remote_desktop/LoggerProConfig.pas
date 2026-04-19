unit LoggerProConfig;

interface

uses
  LoggerPro;

function Log: ILogWriter;

implementation

uses
  WinAPI.Windows, System.SysUtils,
  LoggerPro.FileAppender, LoggerPro.Builder;

var
  _Log: ILogWriter;

function Log: ILogWriter;
begin
  Result := _Log;
end;

function GetFileNameFormat: string;
var
  lLogFileNameFormat: string;
begin
  lLogFileNameFormat := TLoggerProFileAppender.DEFAULT_FILENAME_FORMAT;
  // '%s.%2.2d.%s.log';

  var lClientName: string := GetEnvironmentVariable('CLIENTNAME');
  var lComputerName: string := GetEnvironmentVariable('COMPUTERNAME');
  if not lClientName.IsEmpty then
  begin
    Exit('LOG_' + lClientName + '_' + lLogFileNameFormat);
  end;
  if not lComputerName.IsEmpty then
  begin
    Exit('LOG_' + lComputerName + '_' + lLogFileNameFormat);
  end;
  Result := 'LOG_' + GetProcessId(HInstance).ToString + '_' + lLogFileNameFormat;
end;

initialization

// Remote-desktop / terminal-services scenario: every session writes
// to its own file so sessions don't clobber each other. The file name
// encodes the client machine (or a PID fallback) via GetFileNameFormat.
_Log := LoggerProBuilder
  .WriteToFile
    .WithMaxBackupFiles(10)
    .WithMaxFileSizeInKB(5)
    .WithLogsFolder('.\logs')
    .WithFileFormat(GetFileNameFormat)
    .Done
  .Build;

end.
