unit LoggerProConfig;

interface

uses
  LoggerPro, LoggerPro.Builder, LoggerPro.UDPSyslogAppender;

var
  Log: ILogWriter;
  // Exposed so the form can mutate Port / ProcID / UserName / HostName /
  // Application from the UI at runtime (the fluent .WriteToUDPSyslog
  // chain bakes those in at build time, which would not let the demo
  // reflect spin-edit changes). Created explicitly here and handed to
  // the builder via WriteToAppender.
  Appender: TLoggerProUDPSyslogAppender;

implementation

initialization

// Constructor params: IP, Port, HostName, UserName, Application, Version,
// ProcID, UnixLineBreaks, UTF8BOM, UseLocalTime.
// ProcID '-' is the RFC 5424 nil value; UseLocalTime defaults to False
// (UTC, recommended by RFC 5424).
Appender := TLoggerProUDPSyslogAppender.Create(
  '127.0.0.1', 5114, 'COMPUTER', 'USER', 'EXE', '0.0.1', '-', True, False);

Log := LoggerProBuilder
  .WriteToAppender(Appender)
  .Build;

end.
