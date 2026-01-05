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

### Optional Tag (v2.0)

Tag is now optional! If omitted, defaults to `'main'`:

```delphi
Log.Info('Application started');           // tag = 'main'
Log.Info('Application started', 'CUSTOM'); // tag = 'CUSTOM'
```

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

### Custom Default Tag

Configure a custom default tag in the builder:

```delphi
Log := LoggerProBuilder
  .WithDefaultTag('MYAPP')
  .WriteToConsole.Done
  .Build;

Log.Info('Started');              // tag = 'MYAPP'
Log.Info('Request', 'HTTP');      // tag = 'HTTP' (override)
```

### Sub-Loggers with Default Tag

Create sub-loggers with their own default tag:

```delphi
var
  Log, OrderLog, PaymentLog: ILogWriter;
begin
  Log := LoggerProBuilder.WriteToConsole.Done.Build;

  OrderLog := Log.WithDefaultTag('ORDERS');
  PaymentLog := Log.WithDefaultTag('PAYMENTS');

  OrderLog.Info('New order received');    // tag = 'ORDERS'
  PaymentLog.Info('Payment processed');   // tag = 'PAYMENTS'
  PaymentLog.Error('Failed', 'STRIPE');   // tag = 'STRIPE' (override)
end.
```

---

## Structured Context Logging (v2.0)

Add structured key-value context to your log messages:

### One-shot Context

Pass context directly to log methods (zero overhead when not used):

```delphi
uses
  LoggerPro;

begin
  Log.Info('User logged in', 'AUTH', [
    LogParam.S('username', 'john'),
    LogParam.I('user_id', 42),
    LogParam.B('admin', True)
  ]);

  Log.Error('Query failed', 'DB', [
    LogParam.S('query', 'SELECT * FROM users'),
    LogParam.F('duration_ms', 123.45),
    LogParam.D('timestamp', Now)
  ]);
end.
```

### Bound Context with WithProperty

Create loggers with fixed context (pre-rendered for performance):

```delphi
var
  Log: ILogWriter;
  DbLog: ILogWriter;
begin
  Log := LoggerProBuilder
    .WriteToFile.Done
    .WriteToConsole.Done
    .Build;

  // Create a logger with bound context
  DbLog := Log
    .WithProperty('component', 'database')
    .WithProperty('db_host', 'localhost')
    .WithProperty('db_port', 5432);

  // All messages include the bound context automatically
  DbLog.Info('Connection established', 'DB');
  DbLog.Debug('Query executed', 'DB');
  DbLog.Error('Connection lost', 'DB');
end.
```

### Available LogParam Types

| Method | Type | Example |
|--------|------|---------|
| `LogParam.S` | String | `LogParam.S('name', 'value')` |
| `LogParam.I` | Integer | `LogParam.I('count', 42)` |
| `LogParam.F` | Float/Double | `LogParam.F('price', 19.99)` |
| `LogParam.B` | Boolean | `LogParam.B('active', True)` |
| `LogParam.D` | TDateTime | `LogParam.D('created', Now)` |
| `LogParam.FmtS` | Formatted String | `LogParam.FmtS('msg', 'Item %d', [5])` |
| `LogParam.V` | TValue (generic) | `LogParam.V('data', someValue)` |

Context is automatically rendered by all appenders in `key=value` format.

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
