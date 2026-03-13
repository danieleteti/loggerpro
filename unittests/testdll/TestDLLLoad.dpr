program TestDLLLoad;

{
  Subprocess helper for DLLInitTestU.pas (Issue #109).

  Loads LoggerProTestDLL.dll (which initializes LoggerPro during
  DLL_PROCESS_ATTACH) and exits with a meaningful exit code.
  The parent test process applies a timeout and kills this process
  if it deadlocks, keeping the test runner clean.

  NOTE: FreeLibrary is intentionally NOT called.
  Unloading a DLL whose logger thread is still running causes a symmetric
  Loader Lock deadlock in DLL_PROCESS_DETACH (Shutdown waits for the thread;
  the thread cannot exit without DLL_THREAD_DETACH; DLL_THREAD_DETACH needs
  the Loader Lock that FreeLibrary is holding). We exit via Halt() instead,
  letting the OS clean up threads and DLLs without Loader Lock contention.

  Exit codes
  ----------
  0  : success — DLL loaded, messages were logged
  1  : LoadLibrary failed (OS error)
  2  : GetMessageCount export not found
  3  : DLL loaded but no messages were logged (LoggerPro init may have failed)
}

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  System.SysUtils;

type
  TGetMessageCount = function: Integer; stdcall;

var
  lHandle: HMODULE;
  lGetCount: TGetMessageCount;
  lCount: Integer;
  lDLLPath: string;

begin
  lDLLPath := ExtractFilePath(ParamStr(0)) + 'LoggerProTestDLL.dll';

  // This is the call that deadlocked before PR #109:
  // DLL_PROCESS_ATTACH runs BuildLogWriter -> creates logger thread ->
  // spin-wait; but new thread cannot start until DLL_THREAD_ATTACH
  // completes, which requires the same Loader Lock -> deadlock.
  lHandle := LoadLibrary(PChar(lDLLPath));
  if lHandle = 0 then
  begin
    WriteLn('FAIL: LoadLibrary(', ExtractFileName(lDLLPath), ') failed: ',
            SysErrorMessage(GetLastError));
    Halt(1);
  end;

  // Give the async logger thread time to process messages enqueued
  // during DLL_PROCESS_ATTACH.
  Sleep(400);

  @lGetCount := GetProcAddress(lHandle, 'GetMessageCount');
  if not Assigned(@lGetCount) then
  begin
    WriteLn('FAIL: export GetMessageCount not found');
    Halt(2);
  end;

  lCount := lGetCount();
  WriteLn('Message count: ', lCount);

  if lCount <= 0 then
  begin
    WriteLn('FAIL: expected > 0 messages, got ', lCount);
    Halt(3);
  end;

  WriteLn('OK: DLL initialized without Loader Lock deadlock');

  // NOTE: FreeLibrary is intentionally omitted — see file header.
  Halt(0);
end.
