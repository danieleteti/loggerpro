# LoggerPro - Stato della Sessione Claude

**Data ultimo aggiornamento:** 2026-02-08

---

## Sessione Corrente (2026-02-08)

### Fix Issue #105 - Context Rendering con Curly Braces

**Problema:** Discrepanza tra documentazione e implementazione. La documentazione mostrava `{order_id=12345, amount=99.99}` ma l'output effettivo era `order_id=12345 amount=99.99`.

**Soluzione:** Modificati 3 punti nel codice:
1. `LoggerPro.Renderers.pas:117-158` - `RenderContext()` ora usa separatore `, ` e wrapper `{}`
2. `LoggerPro.pas:1781-1817` - `RenderContextToString()` stesso formato per pre-rendered context
3. `LoggerPro.Renderers.pas:239-244` - Rimosso shortcut `PreRenderedContext` da LogFmt (preserva formato logfmt standard)

**Commit:** `c0ad85f` - Pushato su origin/master
**Test:** 101 test unitari passano
**Issue:** #105 CHIUSA

---

## Lavoro Completato in Sessione Precedente (2025-12-21)

### 1. Fix Thread Safety nel Destroy

Risolto race condition durante la distruzione del logger quando altri thread tentano di accodare log.

**Problema:** Un thread potrebbe passare il check `FEnabled`, poi `Destroy` libera `FLoggerThread` causando access violation.

**Soluzione:** Aggiunto flag `FShuttingDown: Boolean` senza lock (la lettura di un Boolean e' atomica):

```delphi
// In TCustomLogWriter
FShuttingDown: Boolean;

// Constructor
FShuttingDown := False;

// Destructor (prima cosa)
FShuttingDown := True;

// Nei metodi Log e EnqueueLogItem
Assert(not FShuttingDown, 'Cannot log: logger is shutting down');
if FShuttingDown then Exit;
```

| Build | Comportamento |
|-------|---------------|
| Debug | `EAssertionFailed` - rivela il bug immediatamente |
| Release | Silent drop - graceful degradation |

**Test aggiunti** (`ThreadSafetyTestU.pas`):
- `TestDestroyWhileThreadsAreLogging` (x5)
- `TestDestroyWhileThreadsAreLoggingWithContext` (x5)
- `TestRapidCreateDestroy`

---

### 2. Exception Logging con Stack Trace Pluggabile

```delphi
// Senza stack trace formatter
Log.LogException(E);
Log.LogException(E, 'Operation failed');
Log.LogException(E, 'Operation failed', 'MYTAG');

// Con stack trace formatter (JCL, madExcept, EurekaLog, etc.)
Log := LoggerProBuilder
  .WithStackTraceFormatter(
    function(E: Exception): string
    begin
      Result := JclLastExceptStackListToString;
    end)
  .WriteToConsole.Done
  .Build;
```

**Design:**
- `TStackTraceFormatter = TFunc<Exception, string>` - nessuna interfaccia custom
- Zero dipendenze inverse - la libreria di stack trace non dipende da LoggerPro
- TAG sempre come ultimo parametro (consistente con tutta l'API)

**Test aggiunti** (`BuilderTestU.pas`):
- `TestLogExceptionWithoutFormatter`
- `TestLogExceptionWithStackTraceFormatter`
- `TestLogExceptionWithMessageAndTag`

---

### 3. Tag Opzionale con Default Configurabile

```delphi
// Default tag = 'main'
Log.Info('Messaggio');                    // tag = 'main'
Log.Info('Messaggio', 'CUSTOM');          // tag = 'CUSTOM'

// Configurato nel Builder
Log := LoggerProBuilder
  .WithDefaultTag('MYAPP')
  .WriteToConsole.Done
  .Build;

// Sub-logger con default tag
OrderLog := Log.WithDefaultTag('ORDERS');
OrderLog.Info('Nuovo ordine');            // tag = 'ORDERS'
```

---

### 4. Minimum Log Level Globale

Gate prima dell'accodamento - evita overhead per messaggi filtrati.

```delphi
Log := LoggerProBuilder
  .WithMinimumLevel(TLogType.Warning)  // Debug e Info filtrati
  .WriteToConsole.Done
  .Build;

Log.Debug('Ignorato');   // Non accodato - zero overhead
Log.Info('Ignorato');    // Non accodato - zero overhead
Log.Warn('Loggato');     // OK
```

**Vantaggi:**
- Nessun oggetto `TLogItem` creato per messaggi filtrati
- Gate globale indipendente dai log level degli appender

**Test aggiunto:**
- `TestWithMinimumLevel`

---

## Sessione Precedente

### Refactoring Builder API: WriteTo* (Serilog-style)

| Vecchio | Nuovo |
|---------|-------|
| `AddConsoleAppender` | `WriteToConsole.Done` |
| `AddFileAppender` | `WriteToFile.Done` |
| `ConfigureFileAppender` | `WriteToFile` |
| `ConfigureHTTPAppender` | `WriteToHTTP` |
| `AddAppender(x)` | `WriteToAppender(x)` |

---

## Test

**98 test unitari passano**

---

## Architettura Builder

```
ILoggerProBuilder
  |-- WriteTo* Methods
  |   |-- WriteToConsole, WriteToFile, WriteToHTTP, etc.
  |       |-- .WithXxx() -> configurazione
  |       |-- .Done -> ritorna ILoggerProBuilder
  |
  |-- Global Config
  |   |-- WithMinimumLevel (gate globale)
  |   |-- WithDefaultLogLevel (default appender)
  |   |-- WithDefaultRenderer
  |   |-- WithDefaultTag
  |   |-- WithStackTraceFormatter
  |
  |-- Build() -> ILogWriter
```

---

## Comandi Utili

```batch
# Build e Test
cd C:\DEV\loggerpro\unittests
.\build_tests.bat && .\Win32\CI\UnitTests.exe

# Build Sample Console
C:\DEV\loggerpro\samples\160_console\build.bat
```

---

## TODO Immediati

1. [ ] **README.md** - Scrivere come hook per portare traffico al blog
2. [ ] **Documentazione blog** - Articolo completo per danieleteti.it
3. [ ] **Gestione Issue GitHub** - Vedere sezione "GitHub Issues Aperte" sotto

---

## GitHub Issues Aperte - Analisi e Proposte

**Data analisi:** 2026-02-08
**Issue totali aperte:** 12 (escludendo #105 già chiusa)

---

### 🔴 CRITICHE - Da Affrontare Subito

#### Issue #101 - Version 2.0.0 won't compile on Delphi 10.3 Rio
**Labels:** `accepted`, `compatibility`
**Autore:** Scytheroid
**Creata:** 2025-12-02

**Problema:**
LoggerPro 2.0 non compila su Delphi 10.3 Rio.

**Proposte di soluzione:**
1. **Opzione A - Backport (Effort: Alto)**
   - Testare compilazione su Delphi 10.3
   - Identificare feature incompatibili (inline vars, helper estesi, nuove RTL)
   - Aggiungere direttive condizionali `{$IF CompilerVersion >= 34.0}` (Delphi 10.4+)
   - Fornire fallback per feature non disponibili

2. **Opzione B - Documentare requisiti (Effort: Basso, CONSIGLIATO)**
   - Dichiarare Delphi 10.4 Sydney (CompilerVersion 34.0) come versione minima
   - Aggiornare README.md con tabella compatibilità
   - LoggerPro 1.x rimane disponibile per 10.3 e precedenti
   - Chiudere issue con spiegazione chiara

**Raccomandazione:** Opzione B - documentare 10.4+ come minimo, mantenere 1.x per legacy.

---

#### Issue #100 - Hanging in destructor
**Autore:** seer-true
**Creata:** 2025-10-09

**Problema:**
L'applicazione si blocca durante la distruzione del logger.

**Proposte di soluzione:**
1. **Verificare se già risolto (Effort: Basso)**
   - Il commit `540244d` (fix thread-safety) potrebbe aver risolto
   - Chiedere a seer-true di testare con versione corrente
   - Verificare che `Shutdown()` venga chiamato prima di `Free`

2. **Debugging approfondito (Effort: Medio)**
   - Richiedere esempio riproducibile
   - Verificare deadlock in `TLoggerThread.Execute`
   - Controllare se coda eventi è bloccata
   - Testare con i test thread-safety esistenti

3. **Miglioramenti preventivi (Effort: Medio)**
   - Aggiungere timeout nel destructor
   - Warning se Shutdown non chiamato
   - Documentare best practice di cleanup

**Raccomandazione:** Prima chiedere conferma se ancora presente, poi eventualmente debug.

---

#### Issue #97 - Data Loss When Logger is Destroyed
**Labels:** `accepted`, `question`
**Autore:** fastbike
**Creata:** 2025-02-21

**Problema:**
Messaggi in coda vengono persi quando il logger viene distrutto senza chiamare `Shutdown()`.

**Proposte di soluzione:**
1. **Migliorare Shutdown (Effort: Medio, PRIORITÀ ALTA)**
   - Verificare che `Shutdown()` faccia flush completo della coda
   - Aggiungere timeout configurabile (attualmente hardcoded?)
   - Aggiungere metodo esplicito `FlushAndWait(TimeoutMs: Integer)`
   - Warning in destructor se ci sono messaggi pendenti

2. **Auto-flush nel destructor (Effort: Medio)**
   - Chiamare automaticamente `Shutdown()` nel destructor
   - Timeout di 5 secondi max per evitare hang
   - Log warning se timeout scaduto con messaggi persi

3. **Documentazione (Effort: Basso)**
   - README con esempio corretto di cleanup
   - Pattern: `try...finally Log.Shutdown; end;`
   - Spiegare architettura asincrona

**Raccomandazione:** Implementare auto-flush con timeout + migliorare documentazione.

---

### 🟡 QUICK WINS - Basso Effort, Alta Utilità

#### Issue #99 - Disabling logging
**Labels:** `question`
**Milestone:** `2_0_0`
**Autore:** seer-true
**Creata:** 2025-03-10

**Problema:**
Come disabilitare completamente il logging a runtime.

**Proposte di soluzione:**
1. **Solo documentazione (Effort: Basso, CONSIGLIATO)**
   - Già possibile con `WithMinimumLevel(TLogType.Fatal)`
   - Aggiungere sezione README "How to disable logging"
   - Esempio: `Log := LoggerProBuilder.WithMinimumLevel(TLogType.Fatal).Build;`

2. **API esplicita (Effort: Medio)**
   - Aggiungere metodi `Enable()` / `Disable()` runtime
   - Proprietà globale `LoggerPro.GlobalEnabled := False`
   - Appender "null" dedicato: `WriteToNull`

**Raccomandazione:** Prima solo documentazione, API esplicita se richiesta da più utenti.

---

#### Issue #95 - How to get current log file name?
**Labels:** `accepted`
**Autore:** MarcosCunhaLima
**Creata:** 2024-12-18

**Problema:**
Non c'è modo di ottenere il nome del file di log corrente (utile per inviarlo via email, upload, etc.).

**Proposte di soluzione:**
1. **Aggiungere proprietà (Effort: Basso)**
   ```delphi
   // In TLoggerProFileAppender
   property CurrentLogFileName: string read GetCurrentLogFileName;
   ```

2. **Interfaccia dedicata (Effort: Medio)**
   ```delphi
   ILogFileInfo = interface
     function GetCurrentFileName: string;
     function GetLogFiles: TArray<string>;
     function GetLogFileSize: Int64;
   end;
   ```

3. **Helper nel Builder (Effort: Medio)**
   ```delphi
   var
     FileInfo: ILogFileInfo;
   begin
     if Log.TryGetAppenderInfo<ILogFileInfo>(FileInfo) then
       EmailLogFile(FileInfo.GetCurrentFileName);
   end;
   ```

**Raccomandazione:** Soluzione 1 (proprietà semplice) + esempio nel README.

---

#### Issue #90 - UTC Time to Local Time in TLoggerProUDPSyslogAppender
**Autore:** EberhardBierl
**Creata:** 2024-05-11

**Problema:**
Syslog appender usa UTC, l'utente vuole local time.

**Proposte di soluzione:**
1. **Aggiungere opzione (Effort: Basso)**
   ```delphi
   .WriteToSyslog
     .WithServer('10.0.0.1')
     .WithUseLocalTime(True)  // Default: False (UTC)
     .Done
   ```

2. **Documentare standard (Effort: Basso)**
   - RFC 3164: local time
   - RFC 5424: UTC
   - Spiegare perché UTC è preferibile

**Raccomandazione:** Implementare opzione + documentare best practice.

---

#### Issue #82 - Authentication on TElasticSearchAppender
**Labels:** `enhancement`
**Autore:** Basti-Fantasti
**Creata:** 2023-10-23

**Problema:**
ElasticSearch appender non supporta autenticazione (Basic Auth, API Key, Bearer token).

**Proposte di soluzione:**
1. **Header HTTP personalizzati (Effort: Basso)**
   ```delphi
   .WriteToElasticSearch
     .WithURL('https://elastic.example.com')
     .WithBasicAuth('user', 'password')
     .WithApiKey('my-api-key')
     .WithBearerToken('jwt-token')
     .WithCustomHeader('X-Custom', 'value')
     .Done
   ```

2. **Implementazione interna (Effort: Medio)**
   - Modificare `TLoggerProElasticSearchAppender`
   - Aggiungere header `Authorization` in base al metodo scelto
   - Testare con ElasticSearch Cloud (richiede auth)

**Raccomandazione:** Implementare Basic Auth + API Key (i più comuni).

---

### 🟢 ENHANCEMENT - Feature Nuove

#### Issue #94 - Feature request - OnAfterRotate
**Milestone:** `2_0_0`
**Autore:** mfpta
**Creata:** 2024-09-13

**Problema:**
Manca callback dopo rotazione file (utile per upload, compressione, cleanup).

**Proposte di soluzione:**
1. **Eventi callback (Effort: Medio)**
   ```delphi
   .WriteToFile
     .WithFileBaseName('app')
     .WithOnAfterRotate(
       procedure(const OldFileName: string)
       begin
         // Comprimi file vecchio
         CompressFile(OldFileName);
         // Upload a S3
         UploadToCloud(OldFileName);
       end)
     .Done
   ```

2. **Thread safety (Effort: Medio)**
   - Callback chiamato dal logger thread o main thread?
   - Opzione `WithSynchronizeCallback(True)` per UI updates
   - Gestire eccezioni nel callback

**Raccomandazione:** Implementare callback asincrono con gestione errori.

---

#### Issue #92 - TLoggerProFileAppender File Rotation options
**Labels:** `accepted`
**Autore:** fastbike
**Creata:** 2024-07-30

**Problema:**
Richiesta di opzioni avanzate per rotazione file.

**Proposte di soluzione:**
1. **Analizzare richieste specifiche (Effort: Basso)**
   - Chiedere a fastbike esattamente cosa manca
   - Confrontare con Serilog/NLog

2. **Opzioni possibili (Effort: Alto)**
   - Rotazione combinata (size AND time)
   - Retention policy: `WithRetainDays(7)`, `WithMaxFiles(30)`
   - Compressione automatica: `WithCompressOldFiles(True)`
   - Pattern nome custom: `app-{date:yyyy-MM-dd}-{sequence}.log`

**Raccomandazione:** Prima analizzare necessità reali, poi implementare incrementalmente.

---

#### Issue #85 - Log to TStringList
**Labels:** `accepted`
**Milestone:** `2_0_0`
**Autore:** ads69
**Creata:** 2023-12-14

**Problema:**
Loggare direttamente in `TStringList` (in-memory, utile per debug UI).

**Proposte di soluzione:**
1. **Nuovo appender (Effort: Basso-Medio)**
   ```delphi
   var
     LogList: TStringList;
   begin
     LogList := TStringList.Create;

     Log := LoggerProBuilder
       .WriteToStringList
         .WithStringList(LogList)
         .WithMaxLines(1000)  // Limite per evitare OOM
         .Done
       .Build;

     // Mostra in UI
     Memo1.Lines.Assign(LogList);
   end;
   ```

2. **Thread safety (Effort: Medio)**
   - Sincronizzare accesso alla TStringList
   - Opzione per sincronizzare con main thread (VCL)

3. **Alternativa con callback (Effort: Basso)**
   - Usare `WriteToCallback` esistente
   ```delphi
   .WriteToCallback
     .WithCallback(
       procedure(const LogItem: TLogItem)
       begin
         TThread.Synchronize(nil, procedure
           begin
             Memo1.Lines.Add(LogItem.LogMessage);
           end);
       end)
     .Done
   ```

**Raccomandazione:** Creare `TLoggerProStringListAppender` dedicato.

---

#### Issue #84 - EMail Appender: Collective E-Mail
**Labels:** `enhancement`
**Milestone:** `2_0_0`
**Autore:** Basti-Fantasti
**Creata:** 2023-10-24

**Problema:**
Email appender invia 1 email per log entry. Serve batching (es. ogni 100 messaggi o ogni 5 minuti).

**Proposte di soluzione:**
1. **Batch con trigger multipli (Effort: Medio-Alto)**
   ```delphi
   .WriteToEmail
     .WithSMTP('smtp.gmail.com', 587)
     .WithCredentials('user@example.com', 'password')
     .WithBatchSize(100)           // Invia ogni 100 log
     .WithBatchInterval(300)       // O ogni 5 minuti
     .WithFlushOnLevel(TLogType.Error)  // Flush immediato su errori
     .Done
   ```

2. **Template HTML (Effort: Medio)**
   - Email con tabella contenente N log entries
   - Subject: `[APP] 15 errors in last 5 minutes`
   - Formato HTML responsive

**Raccomandazione:** Implementare batching con flush configurabile.

---

#### Issue #77 - Microsoft AppCenter Support
**Autore:** otomazeli
**Creata:** 2023-06-21

**Problema:**
Richiesta supporto Microsoft AppCenter (analytics/crash reporting per mobile).

**Proposte di soluzione:**
1. **Nuovo appender mobile (Effort: Alto)**
   ```delphi
   .WriteToAppCenter
     .WithAppSecret('your-appcenter-secret')
     .WithUserId(CurrentUserId)
     .Done
   ```

2. **Dipendenze (Effort: Alto)**
   - Richiede AppCenter SDK (Objective-C/Java wrapper)
   - Test su iOS + Android
   - Mappare TLogType → AppCenter severity

3. **Priorità (Bassa)**
   - Utile solo per app mobile
   - Pochi utenti Delphi mobile

**Raccomandazione:** Bassa priorità, valutare se c'è domanda reale.

---

## Priorità di Implementazione - Proposta

### 🔴 **FASE 1 - Bug Fix Critici** (1-2 settimane)
1. **#100** - Hanging in destructor (verificare se già risolto dal fix thread-safety)
2. **#97** - Data loss on destroy (implementare auto-flush + documentazione)
3. **#101** - Delphi 10.3 compatibility (documentare versione minima 10.4+)

### 🟡 **FASE 2 - Quick Wins** (1 settimana)
1. **#99** - Disable logging (documentare `WithMinimumLevel`)
2. **#95** - Get current log filename (aggiungere proprietà)
3. **#90** - Syslog local time (aggiungere opzione booleana)
4. **#82** - ElasticSearch auth (Basic Auth + API Key)

### 🟢 **FASE 3 - Enhancement** (priorità da definire con community)
1. **#94** - OnAfterRotate callback
2. **#85** - TStringList appender
3. **#92** - Advanced file rotation (analizzare necessità)
4. **#84** - Batched email
5. **#77** - AppCenter (solo se richiesto da più utenti)

---

## Tabella Riepilogativa Issue

| Issue | Titolo | Priorità | Effort | Fase | Note |
|-------|--------|----------|--------|------|------|
| #101 | Delphi 10.3 compatibility | 🔴 Alta | Basso | 1 | Documentare minimo 10.4+ |
| #100 | Hanging in destructor | 🔴 Alta | Medio | 1 | Verificare se già risolto |
| #97 | Data loss on destroy | 🔴 Alta | Medio | 1 | Auto-flush + doc |
| #99 | Disable logging | 🟡 Media | Basso | 2 | Solo documentazione |
| #95 | Get log filename | 🟡 Media | Basso | 2 | Aggiungere proprietà |
| #90 | Syslog local time | 🟡 Media | Basso | 2 | Opzione booleana |
| #82 | ElasticSearch auth | 🟡 Media | Medio | 2 | Basic Auth + API Key |
| #94 | OnAfterRotate | 🟢 Bassa | Medio | 3 | Callback post-rotazione |
| #92 | Advanced rotation | 🟢 Bassa | Alto | 3 | Analizzare prima |
| #85 | TStringList appender | 🟢 Bassa | Medio | 3 | Per debug UI |
| #84 | Batched email | 🟢 Bassa | Alto | 3 | Buffering email |
| #77 | AppCenter | 🟢 Bassa | Alto | 3 | Solo se richiesto |

---

## Roadmap Feature Future

### Priorita Alta (Effort Basso)

| Feature | Stato |
|---------|-------|
| Minimum Log Level globale | COMPLETATO |
| Exception Logging | COMPLETATO |

### Priorita Media (Effort Medio)

#### Enrichers Automatici
```delphi
Log := LoggerProBuilder
  .Enrich.WithMachineName
  .Enrich.WithProcessId
  .Enrich.WithThreadId
  .Enrich.WithProperty('app_version', '2.0')
  .WriteToConsole.Done
  .Build;
```

#### Conditional Logging
```delphi
Log.DebugIf(IsDetailedLogging, 'Heavy computation: %s', [ExpensiveToString]);
// oppure
if Log.IsDebugEnabled then
  Log.Debug('...');
```

### Priorita Bassa (Effort Alto)

#### Log Scopes (Contesti Annidati)
```delphi
using Log.BeginScope('ProcessOrder', [LogParam.I('order_id', 123)]) do
begin
  Log.Info('Starting');   // include order_id automaticamente
  Log.Info('Completed');
end;
```

#### Sampling / Rate Limiting
```delphi
.WriteToHTTP
  .WithURL('...')
  .WithSampling(0.1)      // logga solo 10%
  .WithRateLimit(100)     // max 100 msg/sec
  .Done
```

#### Self-Diagnostics
```delphi
LoggerPro.SelfLog := procedure(msg: string)
  begin
    WriteLn('[LoggerPro] ' + msg);
  end;
```

### Preset nel Builder
```delphi
_Log := LoggerProBuilder.DevelopmentDefaults.Build;
_Log := LoggerProBuilder.ProductionDefaults.Build;
```

---

## Tabella Riepilogativa Roadmap

| Priorita | Feature | Effort | Stato |
|----------|---------|--------|-------|
| Alta | Minimum Log Level globale | Basso | COMPLETATO |
| Alta | Exception Logging | Basso | COMPLETATO |
| Media | Enrichers automatici | Medio | Da fare |
| Media | Conditional Logging | Basso | Da fare |
| Bassa | Log Scopes | Alto | Da fare |
| Bassa | Sampling/Rate Limiting | Medio | Da fare |
| Bassa | Self-Diagnostics | Basso | Da fare |
| Bassa | Preset Builder | Basso | Da fare |

---

## File con Modifiche WIP (Work In Progress)

**ATTENZIONE:** Queste modifiche sono presenti ma non committate (sembrano incomplete):
- `LoggerPro.Builder.pas` - Tracking configuratori pendenti (SetPendingConfigurator/ClearPendingConfigurator)
- `LoggerPro.WindowsEventLogAppender.pas` - Fix direttive compilazione condizionale

**Nota:** Le feature della sessione 2025-12-21 (MinimumLevel, LogException, ThreadSafety) sono già state committate in precedenza.

---

## Note Tecniche Importanti

### Firma LogException
Il TAG e' SEMPRE l'ultimo parametro in tutta l'API:
```delphi
LogException(E);
LogException(E, aMessage);
LogException(E, aMessage, aTag);  // TAG ultimo!
```

### WithDefaultLogLevel vs WithMinimumLevel
- `WithDefaultLogLevel` - default per appender senza livello specifico (non usato attualmente)
- `WithMinimumLevel` - gate globale del LogWriter, filtra PRIMA dell'accodamento
