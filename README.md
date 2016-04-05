# LoggerPro for Delphi
An modern and pluggable logging framework for Delphi

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

###Warning!
It is still in beta stage

##Built-in log appenders
The framework contains the following built-in log appenders
- File (`TLoggerProFileAppender`)
- Console (`TLoggerProConsoleAppender`)
- OutputDebugString (`TLoggerProOutputDebugStringAppender`)
- VCL Memo (`TVCLMemoLogAppender`)

The log writer and all the appenders are asycnhronous.

**Check the samples to see how to use each appender or even combine different appenders.**

##Documentation

Documenation is available in the `docs` folder as HTML.
