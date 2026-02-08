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
| **2.0.x** (current) | **Delphi 10.4 Sydney** | Uses modern language features |
| 1.x (legacy) | Delphi 10 Seattle+ | For older Delphi versions, use [LoggerPro 1.x](https://github.com/danieleteti/loggerpro/tree/v1.3) |

**Tested on:** Delphi 13 Florence, 12 Athens, 11 Alexandria, 10.4 Sydney

**Note for Delphi 10.3 Rio users:** LoggerPro 2.0 requires Delphi 10.4+ due to modern RTL features. Please use LoggerPro 1.x for older versions.

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
