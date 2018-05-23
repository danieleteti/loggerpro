# LoggerPro for Delphi
An modern and pluggable logging framework for Delphi

## Compatibility
LoggerPro is compatibile with
- Delphi XE2
- Delphi XE3
- Delphi XE4
- Delphi XE5
- Delphi XE6
- Delphi XE7
- Delphi XE8
- Delphi 10 Seattle
- Delphi 10.1 Berlin
- Delphi 10.2 Tokyo (Linux compatibility)


## Getting started
```delphi
program getting_started_console;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  LoggerPro.GlobalLogger; //this is the global logger, it is perfect to understand the basic operation of LoggerPro.

begin
  try
    //the global logger uses a TLoggerProFileAppender, so your logs will be written on a 
    //set of files with automatic rolling/rotating
    
    Log.Debug('Debug message', 'main'); //TLoggerProFileAppender uses the "tag" to select a different log file
    Log.Info('Info message', 'main');
    Log.Warn('Warning message', 'main');
    Log.Error('Error message', 'errors');
    WriteLn('Check "getting_started_console.00.main.log" and "getting_started_console.00.errors.log" to see your logs');
    ReadLn;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
```

The most flexible/correct approach is not much complicated than the global logger one. Check how is simple to create a custom instance of logwriter

```delphi
program getting_started_console_appenders;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  LoggerPro, //LoggerPro core
  LoggerPro.FileAppender, //File appender
  LoggerPro.OutputDebugStringAppender; //OutputDebugString appender

var
  Log: ILogWriter;

begin
  Log := BuildLogWriter([TLoggerProFileAppender.Create,
    TLoggerProOutputDebugStringAppender.Create]);

  try
    Log.Debug('Debug message', 'main');
    Log.Info('Info message', 'main');
    Log.Warn('Warning message', 'main');
    Log.Error('Error message', 'errors');
    WriteLn('Check ');
    WriteLn('  "getting_started_console.00.main.log"');
    WriteLn('  "getting_started_console.00.errors.log"');

    if DebugHook <> 0 then //inform the user where his/her logs are
    begin
      WriteLn('also, you logs have been sent to the current debugger, check the Delphi''s EventLog window to see them.');
    end
    else
    begin
      WriteLn('..seems that no debugger is present. The logs can be seen using DebugView.');
      WriteLn('Download it from here https://technet.microsoft.com/en-us/sysinternals/debugview.aspx');
      WriteLn('Learn how to use http://tedgustaf.com/blog/2011/5/use-debugview-to-view-debug-output-from-asp-net-web-application/');
    end;
    ReadLn;
  except
    on E: Exception do
      WriteLn(E.ClassName, ': ', E.Message);
  end;

end.
```

## Built-in log appenders
The framework contains the following built-in log appenders
- File (`TLoggerProFileAppender`)
- Console (`TLoggerProConsoleAppender`)
- OutputDebugString (`TLoggerProOutputDebugStringAppender`)
- VCL Memo (`TVCLMemoLogAppender`)
- Redis Appender with LogsViewer(to aggregate logs from different instances on a single Redis instance)
- Email Logger (to send email as log, very useful for fatal errors)

Next appenders in the development pipeline
- RESTful Appender (to send logs to a rest endpoint using a specific request format, so that you can implement log server in DelphiMVCFramework, PHP, Java, Python, Node etc)
- Twitter Appender (to send logs to a Twitter Account)
- Database appender (to send logs to a database table using FireDAC components -- Thank You Omar Bossoni)

The log writers and all the appenders are asycnhronous.

**Check the samples to see how to use each appender or even combine different appenders.**

## Documentation

Documenation is available in the `docs` folder as HTML.

## Other
You can install [Delphinus package manager](https://github.com/Memnarch/Delphinus/wiki/Installing-Delphinus) and install LoggerPro as a package there. (Delphinus-Support)