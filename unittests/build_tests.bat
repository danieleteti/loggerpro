@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"

echo.
echo Building LoggerProTestDLL (Issue #109 regression test)...
echo.

dcc32.exe ^
  "C:\DEV\loggerpro\unittests\testdll\LoggerProTestDLL.dpr" ^
  -B ^
  -u"C:\DEV\loggerpro" ^
  -E"C:\DEV\loggerpro\unittests\Win32\CI"

if errorlevel 1 (
  echo.
  echo ERROR: LoggerProTestDLL build failed.
  exit /b 1
)

echo.
echo Building TestDLLLoad (subprocess helper for Issue #109)...
echo.

dcc32.exe ^
  "C:\DEV\loggerpro\unittests\testdll\TestDLLLoad.dpr" ^
  -B ^
  -E"C:\DEV\loggerpro\unittests\Win32\CI"

if errorlevel 1 (
  echo.
  echo ERROR: TestDLLLoad build failed.
  exit /b 1
)

echo.
echo Building UnitTests...
echo.

msbuild "C:\DEV\loggerpro\unittests\UnitTests.dproj" /t:Build /p:Config=CI /p:Platform=Win32 /v:minimal
