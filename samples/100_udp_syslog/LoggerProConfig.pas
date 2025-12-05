unit LoggerProConfig;

interface

uses
  LoggerPro, LoggerPro.UDPSyslogAppender, LoggerPro.Builder;

var
  Log: ILogWriter;
  Appender: TLoggerProUDPSyslogAppender;

implementation

initialization

Appender := TLoggerProUDPSyslogAppender.Create(
    '127.0.0.1'
    , 5114 //UDPClientPort.Value
    , 'COMPUTER'
    , 'USER'
    , 'EXE'
    , '0.0.1'
    , ''
    , True
    , False
  );

// BuildLogWriter is the classic way to create a log writer.
// The modern and recommended approach is to use LoggerProBuilder.
//Log := BuildLogWriter([Appender]);
Log := LoggerProBuilder
  .AddAppender(Appender)
  .Build;

end.
