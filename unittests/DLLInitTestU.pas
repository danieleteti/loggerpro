unit DLLInitTestU;

{ Issue #109 - Windows Loader Lock deadlock in DLL initialization.

  Context
  -------
  When LoggerPro is used inside a DLL (e.g. loaded via P/Invoke from C#),
  calling BuildLogWriter / TCustomLogWriter.Initialize during DLL_PROCESS_ATTACH
  deadlocks without the fix in PR #109:

    1. LoadLibrary holds the Windows Loader Lock.
    2. DLL main block creates the logger thread (TThread.Start).
    3. Spin-wait: "while not FLoggerThread.Started do Sleep(1)".
    4. The new thread needs DLL_THREAD_ATTACH to run, which requires the
       Loader Lock -> BLOCKED.
    5. DEADLOCK: main thread waits for logger thread; logger thread waits
       for main thread.

  The fix (PR #109) skips the spin-wait when System.IsLibrary is True.
  FQueue is allocated before Start, so enqueuing is safe immediately.

  Why a real DLL loaded by a subprocess?
  ---------------------------------------
  System.IsLibrary is a compile-time constant (True only in DLL projects).
  The spin-wait code path can only be exercised by loading an actual DLL.

  If the deadlock IS present (regression), LoadLibrary never returns.
  Running the load in a SUBPROCESS (TestDLLLoad.exe) means we can kill
  the deadlocked process cleanly from the test runner without corrupting
  the test runner's own thread / Loader Lock state. Any other approach
  (background thread in the test runner) would hold the Loader Lock and
  prevent subsequent tests from creating threads (DLL_THREAD_ATTACH).

  Build artefacts (unittests/Win32/CI/)
  ----------------------------------------
    LoggerProTestDLL.dll   DLL initializing LoggerPro in DLL_PROCESS_ATTACH
    TestDLLLoad.exe        subprocess helper: loads the DLL and reports result
}

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDLLInitTest = class
  public
    // Spawns TestDLLLoad.exe which calls LoadLibrary on LoggerProTestDLL.dll.
    // LoggerProTestDLL initializes LoggerPro during DLL_PROCESS_ATTACH
    // (Loader Lock held). If the IsLibrary guard is absent the subprocess
    // deadlocks; the parent kills it after 5 s and fails the test.
    // On success, TestDLLLoad.exe exits with 0 and this test passes.
    [Test]
    procedure TestDLLInitializationUnderLoaderLock;
  end;

implementation

uses
  Winapi.Windows,
  System.SysUtils;

const
  SUBPROCESS_TIMEOUT_MS = 5000; // 5 s — plenty for a healthy DLL init

{ TDLLInitTest }

procedure TDLLInitTest.TestDLLInitializationUnderLoaderLock;
var
  lSI: TStartupInfo;
  lPI: TProcessInformation;
  lExePath: string;
  lWaitResult: DWORD;
  lExitCode: DWORD;
  lOutDir: string;
begin
  lOutDir  := ExtractFilePath(ParamStr(0));
  lExePath := lOutDir + 'TestDLLLoad.exe';

  FillChar(lSI, SizeOf(lSI), 0);
  lSI.cb := SizeOf(lSI);
  FillChar(lPI, SizeOf(lPI), 0);

  Assert.IsTrue(
    CreateProcess(PChar(lExePath), nil, nil, nil,
                  {bInheritHandles=}False, 0, nil,
                  PChar(lOutDir), // set working dir so DLL is found
                  lSI, lPI),
    Format('Could not start "%s": %s', [lExePath, SysErrorMessage(GetLastError)]));

  try
    lWaitResult := WaitForSingleObject(lPI.hProcess, SUBPROCESS_TIMEOUT_MS);

    // ------------------------------------------------------------------
    // ASSERTION 1 — no deadlock (subprocess completed within timeout)
    // ------------------------------------------------------------------
    if lWaitResult = WAIT_TIMEOUT then
    begin
      TerminateProcess(lPI.hProcess, 99);
      Assert.Fail(
        Format('TestDLLLoad.exe did not complete within %d ms. ' +
               'This indicates the Windows Loader Lock deadlock (Issue #109). ' +
               'Verify that the System.IsLibrary guard is present in ' +
               'TCustomLogWriter.Initialize (LoggerPro.pas).',
               [SUBPROCESS_TIMEOUT_MS]));
    end;

    GetExitCodeProcess(lPI.hProcess, lExitCode);

    // ------------------------------------------------------------------
    // ASSERTION 2 — subprocess reported success (exit code 0)
    // ------------------------------------------------------------------
    Assert.AreEqual(DWORD(0), lExitCode,
      Format('TestDLLLoad.exe exited with code %d. ' +
             'Exit codes: 1=LoadLibrary failed, 2=export not found, ' +
             '3=no messages logged.',
             [lExitCode]));
  finally
    CloseHandle(lPI.hProcess);
    CloseHandle(lPI.hThread);
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TDLLInitTest);

end.
