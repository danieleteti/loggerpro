# LoggerPro for Delphi

<p align="center">
  <img src="loggerpro_logo.png" alt="LoggerPro Logo" width="300"/>
</p>

<h3 align="center">The Modern, Async, Pluggable Logging Framework for Delphi</h3>

<p align="center">
  <a href="https://github.com/danieleteti/loggerpro/releases/tag/v2.1.0"><img src="https://img.shields.io/badge/version-2.1.0-brightgreen.svg" alt="Version"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"></a>
  <a href="https://www.embarcadero.com/products/delphi"><img src="https://img.shields.io/badge/Delphi-10.2%20to%2013-orange.svg" alt="Delphi"></a>
  <a href="https://www.danieleteti.it/loggerpro/"><img src="https://img.shields.io/badge/docs-danieleteti.it%2Floggerpro-green.svg" alt="Documentation"></a>
</p>

---

<h2 align="center">
  📖 The official guide — install, API reference, tutorials, code samples, FAQ:<br><br>
  <a href="https://www.danieleteti.it/loggerpro/">https://www.danieleteti.it/loggerpro/</a>
</h2>

<p align="center">
  Available in
  <a href="https://www.danieleteti.it/loggerpro/">🇬🇧 English</a> ·
  <a href="https://www.danieleteti.it/loggerpro-it/">🇮🇹 Italiano</a> ·
  <a href="https://www.danieleteti.it/loggerpro-es/">🇪🇸 Español</a> ·
  <a href="https://www.danieleteti.it/loggerpro-de/">🇩🇪 Deutsch</a>
</p>

---

## What is LoggerPro

Async, pluggable, production-proven logging framework for Delphi. Used in
thousands of applications worldwide since 2010.

- **Async by design** - non-blocking, zero impact on your app's hot path
- **20+ built-in appenders** - File, Console, HTTP, ExeWatch cloud observability, Grafana Loki via LogFmt, ElasticSearch, UDP Syslog, Windows Event Log, Database, ...
- **Fluent Builder API** - Serilog-style configuration
- **JSON configuration** - reshape the logger at deploy time without rebuilding
- **Structured logging** - first-class `LogParam` context
- **Cross-platform** - Windows, Linux, macOS, Android, iOS
- **Thread-safe**, **DLL-safe**, Apache 2.0

## What's New in 2.1

- 🆕 **JSON configuration** - reshape your logger at deploy time without rebuilding
- 🆕 **HTML live log viewer** - self-contained `.html` with filters, search, export, live tailing
- 🆕 **ExeWatch integration** - first-class cloud observability via [ExeWatch](https://exewatch.com)
- 🆕 **Pluggable appenders** - optional backends self-register, just add the `uses` clause
- 🆕 **LogFmt renderer** - spec-compliant `key=value` output for Loki, humanlog, ripgrep
- 🆕 **FileBySource appender** - per-tenant subfolders with day+size rotation
- 🆕 **Runtime log level** - change the global gate on the fly via `ILogWriter.MinimumLevel`
- 🆕 **UTF-8 console output** - correct Unicode in Docker and Windows consoles
- 🆕 **DLL-safe init** - fixes the Windows Loader Lock deadlock
- 🆕 **ElasticSearch auth** - Basic / API Key / Bearer Token
- 🆕 **UDP Syslog local time** option
- 🆕 **`GetCurrentLogFileName` API** on file appenders

---

## 👉 Everything else — install, full API, every code sample, LogFmt querying, Docker/DLL guidance, Windows Service integration, JSON config schema, FAQ — lives in the official guide:

## [www.danieleteti.it/loggerpro](https://www.danieleteti.it/loggerpro/)

---

## License

Apache License 2.0 - free for personal and commercial use.

## Author

**Daniele Teti**

- Blog & docs: [danieleteti.it](https://www.danieleteti.it) · [danieleteti.it/loggerpro](https://www.danieleteti.it/loggerpro/)
- Twitter/X: [@danieleteti](https://twitter.com/danieleteti)

---

<p align="center">
  <b>LoggerPro - Professional Logging for Professional Delphi Developers</b><br>
  <a href="https://www.danieleteti.it/loggerpro/">📖 Full documentation →</a>
</p>
