program colors_demo;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Classes,
  LoggerPro,
  LoggerPro.Builder,
  LoggerPro.ConsoleAppender,
  LoggerPro.Renderers,
  LoggerPro.AnsiColors;

procedure Separator(const aTitle: string);
begin
  Writeln;
  Writeln(Fore.White + Style.Bright + '=== ' + Fore.Blue + aTitle + Fore.White + Style.Bright +' ===' + Style.ResetAll);
end;

var
  GSectionIdx: Integer = 0;

procedure RunSampleLogs(aLog: ILogWriter);
var
  CtxLog: ILogWriter;
  lSec: string;
begin
  Inc(GSectionIdx);
  lSec := Format('[sec=%d]', [GSectionIdx]);
  aLog.Debug(lSec + ' Boot sequence starting', 'BOOT');
  aLog.Info(lSec + ' Application started on port 8080', 'HTTP');
  aLog.Warn(lSec + ' Cache hit ratio below 80%', 'CACHE');
  aLog.Error(lSec + ' Database connection failed after 3 retries', 'DB');
  aLog.Fatal(lSec + ' Out of memory - aborting', 'SYS');

  CtxLog := aLog
    .WithProperty('order_id', 42)
    .WithProperty('customer', 'Acme Corp')
    .WithProperty('amount', 299.95)
    .WithProperty('paid', True);

  CtxLog.Info(lSec + ' Order placed', 'ORDERS');
  CtxLog.Error(lSec + ' Payment gateway timeout', 'ORDERS');
  CtxLog := nil;
end;

procedure DemoStyle(const aTitle: string; const aScheme: TLogColorScheme);
var
  Log: ILogWriter;
begin
  Separator(aTitle);

  Log := LoggerProBuilder
    .WriteToConsole
      .WithMinimumLevel(TLogType.Debug)
      .WithColorScheme(aScheme)
      .Done
    .WriteToFile                         // diagnostic mirror
      .WithLogsFolder('logs_diag')
      .Done
    .Build;

  RunSampleLogs(Log);

  Log.Shutdown;
  Log := nil;
  Sleep(300);
end;

procedure DemoDefault;
var
  Log: ILogWriter;
begin
  Separator('Default (Gin classic) - no prefix, line starts at date');

  Log := LoggerProBuilder
    .WriteToConsole
      .WithMinimumLevel(TLogType.Debug)
      .WithColors
      .Done
    .WriteToFile
      .WithLogsFolder('logs_diag')
      .Done
    .Build;

  RunSampleLogs(Log);

  Log.Shutdown;
  Log := nil;
  Sleep(300);
end;

procedure DemoWithPrefix;
var
  Log: ILogWriter;
begin
  Separator('With custom prefix - .WithPrefix(''MYAPP'')');

  Log := LoggerProBuilder
    .WriteToConsole
      .WithMinimumLevel(TLogType.Debug)
      .WithColors
      .WithPrefix('MYAPP')
      .Done
    .WriteToFile
      .WithLogsFolder('logs_diag')
      .Done
    .Build;

  RunSampleLogs(Log);

  Log.Shutdown;
  Log := nil;
  Sleep(300);
end;

procedure DemoPlainFallback;
var
  Log: ILogWriter;
begin
  Separator('No .WithColors - legacy whole-line coloring');

  Log := LoggerProBuilder
    .WriteToConsole
      .WithMinimumLevel(TLogType.Debug)
      .Done
    .Build;

  RunSampleLogs(Log);

  Log.Shutdown;
  Log := nil;
  Sleep(300);
end;

begin
  try
    DemoDefault;                                           // Gin classic, no prefix
    DemoWithPrefix;                                        // with custom prefix
    DemoStyle('Gin with level BADGES (colored backgrounds)', LogColorSchemes.GinBadge);
    DemoStyle('Gin MINIMAL (everything dim except level)',   LogColorSchemes.GinMinimal);
    DemoStyle('Gin VIBRANT (saturated rainbow)',             LogColorSchemes.GinVibrant);
    DemoStyle('MIDNIGHT (purple / magenta / green, dark-terminal friendly)', LogColorSchemes.Midnight);
    DemoStyle('NORD (cool arctic blues)',                    LogColorSchemes.Nord);
    DemoStyle('MATRIX (all green - hacker aesthetic)',       LogColorSchemes.Matrix);
    DemoStyle('AMBER CRT (80s terminal vibes)',              LogColorSchemes.Amber);
    DemoStyle('OCEAN (layered blues and cyans)',             LogColorSchemes.Ocean);
    DemoStyle('CYBERPUNK (neon magenta + cyan badges)',      LogColorSchemes.Cyberpunk);
    DemoPlainFallback;

    Writeln;
    Writeln('Press Enter to exit...');
    Readln;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
