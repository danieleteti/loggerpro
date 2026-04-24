program stderr_warnings;

{$APPTYPE CONSOLE}

{$R *.res}

(*
  Two appenders on the same logger, each on a DIFFERENT stream:

    * stdout: colored console, minimum level = Debug.  Full trace
              for the human watching the terminal.
    * stderr: plain SimpleConsole, minimum level = Warning.  Only
              warnings / errors / fatals, clean text (no ANSI), ready
              for machine ingestion or an MCP host's log pane.

  Why two streams? stdout and stderr are independent file descriptors.
  You can redirect one without touching the other:

    stderr_warnings.exe  > full.log  2> problems.log

  full.log      -> every level, with ANSI color escapes if the terminal
                   rendered them (run inside a real TTY to see colors;
                   WithColors auto-degrades to plain text when stdout is
                   piped, so a file redirect gets clean text too).
    problems.log -> only Warn / Error / Fatal, plain text.

  Typical use: MCP servers (stdout is the JSON-RPC channel, stderr is
  the log channel the host surfaces to the user), Unix daemons, and
  container workloads where the orchestrator picks up stderr for its
  alerting pipeline.
*)

uses
  System.SysUtils,
  System.Classes,
  LoggerPro,
  LoggerPro.Builder,
  LoggerPro.ConsoleAppender;

var
  Log: ILogWriter;
  i: Integer;

begin
  try
    Log := LoggerProBuilder
      .WithMinimumLevel(TLogType.Debug)
      // Colored console, every level, goes to stdout.
      .WriteToConsole
        .WithColors
        .WithMinimumLevel(TLogType.Debug)
        .Done
      // Plain simple console, Warn+, goes to stderr.
      // Same process, different stream, different level filter.
      .WriteToSimpleConsole
        .WithStdErr
        .WithMinimumLevel(TLogType.Warning)
        .Done
      .Build;

    Log.Debug('Boot sequence starting (stdout only)', 'BOOT');
    Log.Info('Application started on port 8080 (stdout only)', 'HTTP');

    for i := 1 to 3 do
      Log.Info('Order placed (stdout only)', 'ORDERS',
               [LogParam.I('order_id', 1000 + i)]);

    Log.Warn('Cache hit ratio below 80% (stdout + stderr)', 'CACHE');
    Log.Error('Payment gateway timeout (stdout + stderr)', 'ORDERS',
              [LogParam.I('order_id', 1005)]);
    Log.Fatal('Out of memory - aborting (stdout + stderr)', 'SYS');

    Log.Shutdown;
    Log := nil;

    Writeln;
    Writeln('Done. Try redirecting:');
    Writeln('  stderr_warnings.exe  > full.log  2> problems.log');
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
