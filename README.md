# 📝 LoggerPro for Delphi

![LoggerPro Logo](loggerpro_logo.png)

A modern, asynchronous, and pluggable logging framework for Delphi applications.

## Keywords

Delphi logging, Pascal logger, Object Pascal logging framework, Delphi log file, async logging Delphi, thread-safe logging, cross-platform Delphi logging, Delphi syslog, Delphi HTTP logging, Delphi JSON logging, FireMonkey logging, VCL logging, Delphi database logging, Delphi Redis logging, Delphi Elastic Search logging.

## 🎯 Overview

LoggerPro is a professional-grade logging framework for Delphi that provides:

- **Asynchronous logging** - All log operations are non-blocking, ensuring your application performance is not affected by logging overhead
- **Multiple simultaneous appenders** - Send logs to files, console, databases, HTTP endpoints, syslog servers, and more at the same time
- **Tag-based organization** - Categorize logs with tags for easy filtering and routing
- **Five log levels** - Debug, Info, Warning, Error, and Fatal for precise log classification
- **Thread-safe design** - Built from the ground up for multi-threaded applications
- **Cross-platform support** - Windows, Linux, macOS, Android, and iOS
- **Extensible architecture** - Create custom appenders and renderers to meet specific needs
- **Zero configuration option** - Use the global logger to start logging with a single line of code

## 🖥️ Platform Compatibility

LoggerPro works with:

- **Delphi versions:** 13 Florence, 12 Athens, 11 Alexandria, 10.4 Sydney, 10.3 Rio, 10.2 Tokyo, 10.1 Berlin, 10 Seattle, XE8, XE7, XE6, XE5, XE4, XE3, XE2
- **Platforms:** Windows (32/64-bit), Linux, macOS, Android, iOS
- **Frameworks:** VCL, FireMonkey (FMX), Console applications, Web services, ISAPI

## 🚀 Quick Start Guide

### Method 1: Global Logger (Simplest)

Use the built-in global logger for immediate logging without any setup:

```delphi
program QuickStart;

{$APPTYPE CONSOLE}

uses
  LoggerPro.GlobalLogger;

begin
  Log.Debug('Debug message', 'mytag');
  Log.Info('Info message', 'mytag');
  Log.Warn('Warning message', 'mytag');
  Log.Error('Error message', 'mytag');
  Log.Fatal('Fatal error occurred', 'mytag');
  ReadLn;
end.
```

The global logger automatically writes to rotating log files in the application folder.

### Method 2: Custom Logger Instance (Recommended for Production)

Create a custom logger with specific appenders:

```delphi
program CustomLogger;

{$APPTYPE CONSOLE}

uses
  LoggerPro,
  LoggerPro.FileAppender,
  LoggerPro.ConsoleAppender;

var
  Log: ILogWriter;

begin
  Log := BuildLogWriter([
    TLoggerProFileAppender.Create,
    TLoggerProConsoleAppender.Create
  ]);

  Log.Debug('This message goes to both file and console', 'demo');
  Log.Info('Easy to configure multiple destinations!', 'demo');

  ReadLn;
end.
```

## 📊 Log Levels Explained

LoggerPro supports five log levels in order of increasing severity:

| Level | Method | Use Case |
|-------|--------|----------|
| **Debug** | `Log.Debug()` | Detailed diagnostic information for development and troubleshooting |
| **Info** | `Log.Info()` | General information about application flow and state changes |
| **Warning** | `Log.Warn()` | Potentially harmful situations that don't prevent operation |
| **Error** | `Log.Error()` | Error conditions that allow the application to continue |
| **Fatal** | `Log.Fatal()` | Critical errors that may cause application termination |

## 🔌 Complete Appender Reference

### 📁 File Appenders

#### TLoggerProFileAppender
Writes logs to rotating files with automatic size management. Creates separate files per tag.

```delphi
TLoggerProFileAppender.Create(
  aMaxBackupFileCount,  // Number of backup files to keep (default: 5)
  aMaxFileSizeInKB,     // Max size before rotation (default: 1000 KB)
  aLogsFolder,          // Output folder (default: app folder)
  aFileAppenderOptions, // Options set
  aLogFormat,           // Custom format string
  aLogItemRenderer      // Custom renderer
);
```

#### TLoggerProSimpleFileAppender
Writes all logs to a single file regardless of tag.

```delphi
TLoggerProSimpleFileAppender.Create(
  aMaxBackupFileCount,
  aMaxFileSizeInKB,
  aLogsFolder,
  aFileName             // Single output file name
);
```

#### TLoggerProFileByFolderAppender
Writes to a single log file in a specified folder.

#### TLoggerProTimeRotatingFileAppender
Rotates log files based on time intervals instead of size.

```delphi
TLoggerProTimeRotatingFileAppender.Create(
  aInterval,           // Hourly, Daily, Weekly, or Monthly
  aMaxBackupFiles,     // Files to retain (default: 30)
  aLogsFolder,
  aFileBaseName
);
```

**File naming examples:**
- Hourly: `app.2025120312.log`
- Daily: `app.20251203.log`
- Weekly: `app.2025W49.log`
- Monthly: `app.202512.log`

#### TLoggerProJSONLFileAppender
Writes logs in JSON Lines format for easy parsing by log aggregation tools.

```json
{"timestamp":"2025-12-03T14:30:00.000Z","level":"INFO","message":"User logged in","tag":"auth","hostname":"server01","tid":1234}
```

### 💻 Console Appenders

#### TLoggerProConsoleAppender
Colored console output for Windows applications. Different colors for each log level.

#### TLoggerProSimpleConsoleAppender
Basic cross-platform console output without colors. Works on Windows, Linux, and macOS.

### 🌐 Network Appenders

#### TLoggerProHTTPAppender
Sends logs via HTTP POST to REST endpoints, webhooks, or log aggregation services.

```delphi
lAppender := TLoggerProHTTPAppender.Create(
  'https://logs.example.com/api/logs',
  THTTPContentType.JSON,  // or PlainText
  5                       // Timeout in seconds
);
lAppender.AddHeader('Authorization', 'Bearer token123');
lAppender.AddHeader('X-Application', 'MyApp');
lAppender.MaxRetryCount := 3;
lAppender.OnSendError := procedure(const Sender; const aLogItem; const E; var RetryCount)
  begin
    // Custom error handling
  end;
```

Features:
- JSON or plain text content types
- Custom HTTP headers (API keys, authentication)
- Configurable retry logic with callbacks
- Extended info (hostname, username, process name, PID)
- Optional REST-style URLs (`/api/logs/tag/level`)

#### TLoggerProUDPSyslogAppender
Sends logs to syslog servers via UDP following RFC 5424 standard.

```delphi
TLoggerProUDPSyslogAppender.Create('syslog.example.com', 514, 'MyApp');
```

#### TLoggerProRedisAppender
Publishes logs to Redis pub/sub channels for distributed logging.

#### TLoggerProElasticSearchAppender
Sends logs directly to Elastic Search for indexing and searching.

#### TLoggerProNSQAppender
Publishes logs to NSQ distributed message queue.

### 🗄️ Database Appenders

#### TLoggerProDBAppenderFireDAC
Writes logs to any database supported by FireDAC (Oracle, SQL Server, MySQL, PostgreSQL, SQLite, etc.).

#### TLoggerProDBAppenderADO
Writes logs to databases using ADO (useful for legacy systems).

### 🖼️ Visual Appenders (VCL)

#### TVCLMemoLogAppender
Displays logs in a TMemo component with optional auto-scroll.

```delphi
TVCLMemoLogAppender.Create(Memo1, 1000, True); // Max 1000 lines, clear on startup
```

#### TVCLListViewAppender
Shows logs in a TListView with columns for timestamp, level, message, and tag.

#### TVCLListBoxAppender
Displays logs in a TListBox component.

### 🛠️ Utility Appenders

#### TLoggerProOutputDebugStringAppender
Sends logs to the Windows debugger via OutputDebugString. View in Delphi IDE or DebugView.

#### TLoggerProWindowsEventLogAppender
Writes logs to Windows Event Log for system integration.

#### TLoggerProEMailAppender
Sends log entries via email. Useful for critical error notifications.

#### TLoggerProMemoryRingBufferAppender
Stores logs in a circular memory buffer. Useful for accessing recent logs programmatically.

```delphi
lMemAppender := TLoggerProMemoryRingBufferAppender.Create(100); // Keep last 100 entries
// Later...
lLogs := lMemAppender.GetLogs; // Get all stored logs
lMemAppender.Clear;             // Clear the buffer
```

#### TLoggerProCallbackAppender
Calls a custom callback procedure for each log entry.

```delphi
TLoggerProCallbackAppender.Create(
  procedure(const aLogItem: TLogItem)
  begin
    // Process log item
    SendToCustomDestination(aLogItem.LogMessage);
  end
);
```

#### TLoggerProDMSEventStreamsAppender
Integrates with DMSContainer EventStreams for enterprise messaging.

### Utility Classes

#### TLoggerProFilter
Decorator that filters logs before passing to another appender.

#### TLoggerProProxy
Lazy initialization proxy for deferred logger creation.

## 🎨 Custom Log Renderers

Customize how log entries are formatted using the `ILogItemRenderer` interface:

```delphi
uses
  LoggerPro,
  LoggerPro.Renderers;

var
  Log: ILogWriter;
begin
  // Use LogFmt format: level=INFO msg="Hello" tag=mytag ts=2025-12-03T14:30:00
  Log := BuildLogWriter([
    TLoggerProFileAppender.Create(10, 5, 'logs', [], nil,
      TLogItemLogFmtRenderer.Create)
  ]);
end.
```

## 📚 Sample Projects Guide

The `samples` folder contains working examples for every feature:

| Folder | Name | Description |
|--------|------|-------------|
| `01_global_logger` | Global Logger | Demonstrates the simplest way to start logging using the global logger singleton. Shows multi-threaded logging with proper thread cleanup on application close. |
| `02_file_appender` | File Appender | Shows rotating file appender with automatic backup management. Demonstrates tag-based file separation. |
| `02a_simple_file_appender` | Simple File Appender | Single file logging without tag separation. All logs go to one file. |
| `02b_file_appender_by_folder` | File by Folder | Demonstrates logging to a specific folder with custom file naming. |
| `03_console_appender` | Console Appender | Colored console output with different colors per log level (Windows). |
| `04_outputdebugstring_appender` | OutputDebugString | Sends logs to Windows debugger. View in Delphi IDE Event Log or SysInternals DebugView. |
| `05_vcl_appenders` | VCL Visual Appenders | Shows TMemo, TListView, and TListBox appenders for VCL applications with live log display. |
| `06_logfmt_appender` | LogFmt Renderer | Demonstrates custom log formatting using LogFmt key=value format for structured logging. |
| `08_email_appender` | Email Appender | Sends log entries via email using Indy components. Configure SMTP settings for notifications. |
| `09_jsonl_appender` | JSON Lines Appender | Writes logs in JSON Lines format with ISO 8601 timestamps. Compatible with log aggregation tools. |
| `10_multiple_appenders` | Multiple Appenders | Combines file, console, and other appenders. Shows how logs can go to multiple destinations simultaneously. |
| `15_appenders_with_different_log_levels` | Per-Appender Log Levels | Configure different minimum log levels for each appender (e.g., Debug to file, Error to email). |
| `20_multiple_loggers` | Multiple Loggers | Create separate logger instances for different subsystems with independent configurations. |
| `50_custom_appender` | Custom Appender | Template for creating your own appender by implementing ILogAppender interface. |
| `60_logging_inside_dll` | DLL Logging | Proper logging setup inside DLLs with ReleaseGlobalLogger for clean shutdown. |
| `65_file_appender_in_remote_desktop` | Remote Desktop Sessions | Handle multiple users in Remote Desktop environments with session-aware file naming. |
| `70_isapi_sample` | ISAPI Web Module | Logging in IIS ISAPI web applications with proper finalization. |
| `90_remote_logging_with_redis` | Redis Logging | Publish logs to Redis pub/sub for distributed log aggregation across multiple servers. |
| `95_dmscontainer_eventstream_logging` | DMSContainer Integration | Integration with DMSContainer EventStreams for enterprise message-based logging. |
| `100_udp_syslog` | Syslog via UDP | Send logs to syslog servers (rsyslog, syslog-ng) following RFC 5424 standard. |
| `120_elastic_search_appender` | Elastic Search | Index logs directly in Elastic Search for powerful search and visualization. |
| `130_simple_console_appender` | Simple Console | Cross-platform console output without Windows-specific colored output. |
| `140_DB_appender` | Database (ADO) | Write logs to database using ADO components. Works with any OLEDB-compatible database. |
| `150_DB_appender_firedac` | Database (FireDAC) | Write logs to database using FireDAC. Supports all FireDAC-compatible databases. |
| `160_console` | Console Demo | Basic console application demonstrating core logging functionality. |
| `170_memory_appender` | Memory Ring Buffer | In-memory circular buffer appender. Access recent logs programmatically without file I/O. |
| `180_callback_appender` | Callback Appender | Custom callback for each log entry. Integrate with any custom logging destination. |
| `190_time_rotating_appender` | Time-Based Rotation | Rotate log files by time (hourly, daily, weekly, monthly) instead of size. |
| `200_http_appender` | HTTP POST Appender | Send logs via HTTP to REST APIs, webhooks, Logstash, or cloud logging services. |
| `rest_logs_collector` | REST Log Collector Server | Sample server application that receives logs from HTTP appender. |

## ⚡ What's New in Version 2.0

### New Features

- **Fatal log level** - New severity level for critical errors: `Log.Fatal('message', 'tag')`

- **New appenders:**
  - `TLoggerProHTTPAppender` - Full-featured HTTP appender replacing the old REST appender
  - `TLoggerProMemoryRingBufferAppender` - In-memory circular buffer for recent log access
  - `TLoggerProCallbackAppender` - Custom callback for flexible log processing
  - `TLoggerProTimeRotatingFileAppender` - Time-based file rotation (hourly/daily/weekly/monthly)

- **Custom log renderers** - `ILogItemRenderer` interface for complete control over log format
  - Built-in `TLogItemLogFmtRenderer` for structured key=value logging

- **Enhanced JSON Lines appender:**
  - ISO 8601 timestamp format for international compatibility
  - Hostname field for multi-server environments

- **Improved syslog appender:**
  - Full RFC 5424 compliance
  - Support for all log levels including Fatal

### Behavioral Changes from 1.x

- **Global Logger lifecycle:** The global logger now ensures all pending logs are written before application termination. Applications with background logging threads should wait for thread completion before closing. See sample `01_global_logger` for the recommended pattern.

- **Queue performance:** Internal thread-safe queue implementation improved for better throughput under high load.

- **File locking:** File appenders use enhanced locking for reliability in multi-process scenarios.

### Migration from 1.x

**`TLoggerProRESTAppender` replaced by `TLoggerProHTTPAppender`:**

```delphi
// Version 1.x (old):
lAppender := TLoggerProRESTAppender.Create('http://server/api/logs');

// Version 2.0 (new):
lAppender := TLoggerProHTTPAppender.Create('http://server/api/logs');
lAppender.AppendTagAndLevelToURL := True; // For /api/logs/tag/level URL style
```

Callback changes:
- `OnNetSendError` renamed to `OnSendError`
- `OnCreateData` now includes `aContentType` output parameter
- Extended info configured via constructor instead of separate properties

## 📦 Installation

### Option 1: Manual Installation

1. Clone or download this repository
2. Add the LoggerPro root folder to your Delphi Library Path (Tools > Options > Language > Delphi > Library)
3. Add required units to your uses clause

### Option 2: Delphinus Package Manager

1. Install [Delphinus](https://github.com/Memnarch/Delphinus/wiki/Installing-Delphinus)
2. Search for "LoggerPro" in the package list
3. Click Install

## ⚙️ Advanced Configuration

### Queue Size Configuration

LoggerPro uses internal queues to handle asynchronous logging. You can tune these queues for your specific workload:

```delphi
var
  DefaultLoggerProMainQueueSize: Cardinal = 50000;
  DefaultLoggerProAppenderQueueSize: Cardinal = 50000;
```

**DefaultLoggerProMainQueueSize**
- Controls the size of the main logging queue that receives all log messages
- All log calls (`Log.Debug`, `Log.Info`, etc.) push messages to this queue
- The logger thread pulls messages from this queue and distributes them to appenders
- Default: 50,000 items

**DefaultLoggerProAppenderQueueSize**
- Controls the size of each individual appender's queue
- Each appender has its own queue, allowing slow appenders (like HTTP or database) not to block faster ones (like file)
- Default: 50,000 items per appender

**When to modify these values:**

| Scenario | Recommendation |
|----------|----------------|
| High-frequency logging (>10,000 logs/sec) | Increase both values to 100,000+ |
| Memory-constrained environment | Decrease to 10,000-20,000 |
| Slow appenders (HTTP, DB) with bursts | Increase `DefaultLoggerProAppenderQueueSize` |
| Many simultaneous threads logging | Increase `DefaultLoggerProMainQueueSize` |

**Example: Configuring for high-throughput logging**

```delphi
program HighThroughputApp;

uses
  LoggerPro,
  LoggerPro.FileAppender;

begin
  // Set before creating any logger
  DefaultLoggerProMainQueueSize := 100000;
  DefaultLoggerProAppenderQueueSize := 100000;

  // Now create the logger
  Log := BuildLogWriter([TLoggerProFileAppender.Create]);
end.
```

> ⚠️ **Important:** These values must be set **before** creating any logger instance. Once a logger is created, the queue sizes cannot be changed.

## 🔒 Thread Safety Guidelines

LoggerPro is fully thread-safe. Follow these guidelines for optimal usage:

1. **Create logger once** - Create your ILogWriter instance at application startup
2. **Share freely** - The same ILogWriter can be used from any thread
3. **Don't recreate** - Avoid creating new loggers in loops or frequently-called methods
4. **Clean shutdown** - Wait for background threads to complete before application exit

```delphi
// Recommended: Create once, use everywhere
var
  GLog: ILogWriter;

initialization
  GLog := BuildLogWriter([TLoggerProFileAppender.Create]);

finalization
  GLog := nil; // Logger will flush pending logs
```

## 🧪 Unit Tests

LoggerPro includes a comprehensive test suite using DUnitX framework. Tests are located in the `unittests` folder.

**Running the tests:**

```bash
# Using invoke (Python)
invoke tests

# Or manually build and run
msbuild unittests\UnitTests.dproj /p:Config=CI /p:Platform=Win32
unittests\Win32\CI\UnitTests.exe
```

**Test coverage includes:**
- Core logging functionality (TLogItem, log levels, log formatting)
- TLoggerProFilter (proxy/decorator pattern)
- Dynamic appender management (add/remove at runtime)
- TLoggerProMemoryRingBufferAppender (ring buffer, thread safety, filtering)
- TLoggerProCallbackAppender (callbacks, synchronization)
- TLoggerProTimeRotatingFileAppender (daily, hourly, weekly, monthly rotation)
- TLoggerProHTTPAppender (JSON serialization, headers, URL building)

## 📄 License

Apache License, Version 2.0

## 🤝 Contributing

Contributions welcome! Please submit issues and pull requests on GitHub.

## 👏 Credits

- **Daniele Teti** - Creator and maintainer
- **Community contributors** - Thank you to everyone who has submitted issues, pull requests, and improvements

## 🔗 Links

- GitHub: https://github.com/danieleteti/loggerpro
- Author: https://github.com/danieleteti
