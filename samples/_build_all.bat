@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat" >nul

set FAILED=0
set ROOT=%~dp0

for /R "%ROOT%" %%F in (*.dpr) do (
  echo %%F | findstr /C:"\Win32\" /C:"\bin\" /C:"\__history\" >nul
  if errorlevel 1 (
    call :compile "%%F"
  )
)

echo.
echo ===========================================
echo Samples build sweep: %FAILED% failure(s)
echo ===========================================
exit /b %FAILED%

:compile
dcc32.exe ^
  -B ^
  -NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win ^
  -u"C:\DEV\LoggerPro" ^
  -U"C:\DEV\LoggerPro" ^
  %1 >nul 2>&1
if errorlevel 1 (
  echo FAIL  %1
  set /A FAILED+=1
) else (
  echo OK    %1
)
goto :eof
