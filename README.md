# LoggerPro for Delphi

<p align="center">
  <img src="loggerpro_logo.png" alt="LoggerPro Logo" width="300"/>
</p>

<h3 align="center">The Modern, Async, Pluggable Logging Framework for Delphi</h3>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"></a>
  <a href="https://www.embarcadero.com/products/delphi"><img src="https://img.shields.io/badge/Delphi-10%20to%2013-orange.svg" alt="Delphi"></a>
  <a href="https://www.danieleteti.it/loggerpro/"><img src="https://img.shields.io/badge/docs-danieleteti.it-green.svg" alt="Documentation"></a>
</p>

---

## Why Developers Love LoggerPro

**LoggerPro** is the most complete and battle-tested logging framework for Delphi. Used in thousands of production applications worldwide, it provides everything you need for professional-grade logging.

### Key Features

- **Async by Design** - Non-blocking logging with zero impact on application performance
- **20+ Built-in Appenders** - File, Console, HTTP, Syslog, ElasticSearch, Database, Email, and many more
- **Cross-Platform** - Windows, Linux, macOS, Android, iOS - write once, log everywhere
- **Thread-Safe** - Built from the ground up for multi-threaded applications
- **Fluent Builder API** - Clean, readable, Serilog-style configuration
- **Structured Logging** - First-class support for key-value context in log messages
- **Production Ready** - Stable, maintained, and continuously improved since 2010

---

## Quick Taste

```delphi
uses
  LoggerPro.GlobalLogger;

begin
  Log.Info('Application started');
  Log.Debug('Processing item %d', [42], 'WORKER');
  Log.Error('Connection failed', 'DATABASE');
end.
```

One line of `uses`, and you're logging to rotating files. It's that simple.

### Builder API (v2.0)

```delphi
Log := LoggerProBuilder
  .WithDefaultTag('MYAPP')
  .WriteToFile
    .WithLogsFolder('logs')
    .Done
  .WriteToConsole.Done
  .WriteToHTTP
    .WithURL('https://logs.example.com/api')
    .Done
  .Build;
```

### Structured Context Logging

```delphi
Log.Info('Order completed', 'ORDERS', [
  LogParam.I('order_id', 12345),
  LogParam.S('customer', 'John Doe'),
  LogParam.F('total', 299.99)
]);
```

### Disabling Logging at Runtime

**Option 1: Set Minimum Level (Simple)**

```delphi
// Disable Debug and Info, keep Warnings and above
Log := LoggerProBuilder
  .WithMinimumLevel(TLogType.Warning)
  .WriteToFile.Done
  .Build;

// Change at runtime
(Log as TCustomLogWriter).MinimumLevel := TLogType.Fatal; // Disable almost everything
```

**Option 2: Filtering Provider (Advanced)**

```delphi
uses LoggerPro.Proxy;

var
  lAppender: ILogAppender;
  lEnabled: Boolean;

lEnabled := True;

lAppender := TLoggerProFileAppender.Create(5, 1000);

// Wrap with runtime filter
lAppender := TLoggerProFilter.Build(
  lAppender,
  function(const aLogItem: TLogItem): Boolean
  begin
    Result := lEnabled; // Toggle at runtime
  end);

Log := BuildLogWriter([lAppender]);

// Later: disable all logging
lEnabled := False;
```

### UDP Syslog Appender

Send logs to remote syslog servers (RFC 5424):

```delphi
Log := LoggerProBuilder
  .WriteToUDPSyslog
    .WithHost('syslog.example.com')
    .WithPort(514)
    .WithApplication('MyApp')
    .WithUseLocalTime(True)  // Use local time instead of UTC
    .Done
  .Build;
```

### Getting Current Log File Name

Get the active log file name from file appenders (useful for uploading, emailing, etc.):

```delphi
uses LoggerPro.FileAppender;

var
  lAppender: TLoggerProSimpleFileAppender;
  lFileName: string;
begin
  lAppender := TLoggerProSimpleFileAppender.Create;
  Log := BuildLogWriter([lAppender]);

  Log.Info('Message');

  // Get current log file name
  lFileName := lAppender.GetCurrentLogFileName;
  WriteLn('Logging to: ', lFileName);

  // Now you can upload it, email it, etc.
  UploadLogFile(lFileName);
end;
```

For `TLoggerProFileAppender` (separate files per tag):

```delphi
var
  lAppender: TLoggerProFileAppender;
  lFileName: string;
  lAllFiles: TArray<string>;
begin
  lAppender := TLoggerProFileAppender.Create;

  // Get file for specific tag
  lFileName := lAppender.GetCurrentLogFileName('ORDERS');

  // Get all current log files
  lAllFiles := lAppender.GetAllCurrentLogFileNames;
end;
```

---

## Full Documentation

For complete documentation, tutorials, advanced examples, and best practices:

<h2 align="center">
  <a href="https://www.danieleteti.it/loggerpro/">https://www.danieleteti.it/loggerpro/</a>
</h2>

---

## Installation

### Manual

Add the LoggerPro source folder to your Delphi Library Path.

### Delphinus

Search for "LoggerPro" in the Delphinus package manager.

---

## Supported Platforms

| Platform | Status |
|----------|--------|
| Windows (32/64-bit) | Full Support |
| Linux | Full Support |
| macOS | Full Support |
| Android | Full Support |
| iOS | Full Support |

### Delphi Version Requirements

| LoggerPro Version | Minimum Delphi Version | Notes |
|-------------------|------------------------|-------|
| **2.0.x** (current) | **Delphi 10.3 Rio** | Full compatibility from 10.3+ |
| 1.x (legacy) | Delphi 10 Seattle+ | Legacy support |

**Tested on:** Delphi 13 Florence, 12 Athens, 11 Alexandria, 10.4 Sydney, 10.3 Rio

**Note:** LoggerPro 2.0 is fully compatible with Delphi 10.3 Rio and later versions.

---

## Sample Projects

The `samples/` folder contains **25+ working examples** covering every appender and use case. The best way to learn LoggerPro is by exploring these samples.

---

## License

Apache License 2.0 - Use it freely in personal and commercial projects.

---

## Author

**Daniele Teti**

- Blog: [danieleteti.it](https://www.danieleteti.it)
- LoggerPro Docs: [danieleteti.it/loggerpro](https://www.danieleteti.it/loggerpro/)
- Twitter/X: [@danieleteti](https://twitter.com/danieleteti)

---

<p align="center">
  <b>LoggerPro - Professional Logging for Professional Delphi Developers</b>
</p>
