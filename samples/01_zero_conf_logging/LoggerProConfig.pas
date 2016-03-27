unit LoggerProConfig;

interface

implementation

uses
  LoggerPro;

procedure SetupLogger;
begin
  { Without any configuration LoggerPro uses the
    TLoggerProFileAppender with the default configuration.

    So the following two blocks of code are equivalent:

    ...
    TLogger.Initialize; //=> uses the TLoggerProFileAppender
    ...

    ...
    TLogger.AddAppender(TLoggerProFileAppender.Create);
    TLogger.Initialize
    ...
  }

  TLogger.Initialize;
end;

initialization

SetupLogger;

end.
