library LoggerProTestDLL;

{
  Test DLL for Issue #109 - Windows Loader Lock deadlock.

  This DLL intentionally initializes LoggerPro inside its main block, which
  Delphi executes during DLL_PROCESS_ATTACH (Loader Lock held).

  Without the System.IsLibrary guard added by PR #109, the spin-wait in
  TCustomLogWriter.Initialize deadlocks at this point:

    1. LoadLibrary holds the Windows Loader Lock.
    2. DLL main block calls BuildLogWriter, which creates the logger thread.
    3. spin-wait: "while not FLoggerThread.Started do Sleep(1)"
    4. Logger thread needs DLL_THREAD_ATTACH to run -> needs Loader Lock -> BLOCKED.
    5. DEADLOCK: main thread waits for logger, logger waits for main thread.

  With the fix (System.IsLibrary guard), the spin-wait is skipped.
  DLL_PROCESS_ATTACH returns promptly; the Loader Lock is released;
  the logger thread can then complete DLL_THREAD_ATTACH and start executing.

  NOTE: FreeLibrary intentionally NOT supported.
  Calling FreeLibrary causes a symmetric deadlock during DLL_PROCESS_DETACH:
  Shutdown() waits for the logger thread, but the thread cannot exit until
  DLL_THREAD_DETACH fires, which needs the Loader Lock that FreeLibrary holds.
  The test subprocess (TestDLLLoad.exe) exits via Halt() which lets the OS
  handle thread and DLL cleanup cleanly without holding the Loader Lock.

  Exported symbols
  ----------------
  GetMessageCount(): Integer  stdcall
    Returns the number of messages logged during DLL initialization.
    Returns -1 if initialization failed.
}

uses
  Winapi.Windows,
  System.SysUtils,
  LoggerPro in '..\..\LoggerPro.pas',
  LoggerPro.Renderers in '..\..\LoggerPro.Renderers.pas',
  LoggerPro.FileAppender in '..\..\LoggerPro.FileAppender.pas',
  LoggerPro.MemoryAppender in '..\..\LoggerPro.MemoryAppender.pas';

var
  GLog: ILogWriter;
  GAppender: TLoggerProMemoryRingBufferAppender;

function GetMessageCount: Integer; stdcall;
begin
  if Assigned(GAppender) then
    Result := GAppender.Count
  else
    Result := -1;
end;

exports
  GetMessageCount;

begin
  // -----------------------------------------------------------------------
  // Everything below runs during DLL_PROCESS_ATTACH (Loader Lock held).
  // This is exactly the scenario that triggered the deadlock in Issue #109.
  // -----------------------------------------------------------------------
  try
    GAppender := TLoggerProMemoryRingBufferAppender.Create(100);
    GLog := BuildLogWriter([GAppender]);
    GLog.Info('DLL initialized - Loader Lock deadlock regression test', 'DLL_INIT');
    GLog.Info('PR #109 IsLibrary guard is working correctly', 'DLL_INIT');
  except
    // Initialization failed; GetMessageCount() will return -1.
  end;
end.
