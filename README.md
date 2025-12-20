# LoggerPro for Delphi

![LoggerPro Logo](loggerpro_logo.png)

**The modern, async, pluggable logging framework for Delphi.**

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Delphi](https://img.shields.io/badge/Delphi-XE2%20to%2013-orange.svg)](https://www.embarcadero.com/products/delphi)

---

## Why LoggerPro?

- **Async by design** - Zero impact on your application performance
- **20+ built-in appenders** - File, Console, HTTP, Syslog, ElasticSearch, Redis, Database, and more
- **Cross-platform** - Windows, Linux, macOS, Android, iOS
- **Thread-safe** - Built for multi-threaded applications
- **Fluent Builder API** - Clean, readable configuration

---

## Quick Start

```delphi
uses
  LoggerPro.GlobalLogger;

begin
  Log.Info('Application started', 'MAIN');
  Log.Debug('Processing item %d', [42], 'WORKER');
  Log.Error('Connection failed', 'DATABASE');
end.
```

That's it. One line of uses, and you're logging to rotating files.

---

## Builder Pattern (v2.0)

Configure your logger with a fluent, Serilog-style API:

```delphi
uses
  LoggerPro, LoggerPro.Builder;

var
  Log: ILogWriter;
begin
  Log := LoggerProBuilder
    .WriteToConsole.Done
    .WriteToFile.Done
    .WriteToHTTP
      .WithURL('https://logs.example.com/api')
      .WithHeader('Authorization', 'Bearer token123')
      .Done
    .Build;
end.
```

---

## Appenders at a Glance

| Category | Appenders |
|----------|-----------|
| **File** | Rotating, Simple, JSONL, Time-based rotation |
| **Console** | Colored (Win/Linux/macOS), Simple |
| **Network** | HTTP/REST, Syslog (UDP), Redis, ElasticSearch, NSQ |
| **Database** | FireDAC, ADO |
| **Visual** | TMemo, TListView, TListBox |
| **Utility** | OutputDebugString, Email, Memory buffer, Callback |

---

## Platforms

| OS | Status |
|----|--------|
| Windows (32/64-bit) | Full support |
| Linux | Full support |
| macOS | Full support |
| Android | Full support |
| iOS | Full support |

**Delphi versions:** 13 Florence down to XE2

---

## Documentation

**Full documentation, tutorials, and examples:**

### https://www.danieleteti.it/loggerpro/

---

## Installation

### Boss (recommended)

```bash
boss install loggerpro
```

### Manual

Add the LoggerPro folder to your Library Path.

### Delphinus

Search for "LoggerPro" in the package manager.

---

## Sample Projects

The `samples/` folder contains 25+ working examples covering every appender and use case.

---

## License

Apache License 2.0

## Author

**Daniele Teti** - [danieleteti.it](https://www.danieleteti.it)

---

*Keywords: Delphi logging, Pascal logger, async logging, thread-safe logging, cross-platform Delphi logging, Delphi syslog, Delphi HTTP logging, Delphi JSON logging, FireMonkey logging, VCL logging.*
