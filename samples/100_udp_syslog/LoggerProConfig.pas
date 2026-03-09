unit LoggerProConfig;

interface

uses
  LoggerPro, LoggerPro.Builder;

var
  Log: ILogWriter;

implementation

initialization

Log := LoggerProBuilder
  .WriteToUDPSyslog
    .WithHost('127.0.0.1')
    .WithPort(5114)
    .WithHostName('COMPUTER')
    .WithUserName('USER')
    .WithApplication('EXE')
    .WithVersion('0.0.1')
    .WithProcID('-')           // RFC 5424: '-' means "not applicable"
    .WithUseLocalTime(False)   // False = UTC (recommended per RFC 5424)
    .Done
  .Build;

end.
