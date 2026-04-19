@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"

dcc32.exe ^
  "%~dp0exewatch_appender.dpr" ^
  -B ^
  -NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win ^
  -u"C:\DEV\LoggerPro" ^
  -u"C:\dev\exewatchsamples\DelphiCommons" ^
  -E"C:\DEV\LoggerPro\samples\260_exewatch_appender"

if errorlevel 1 (
  echo.
  echo ERROR: exewatch_appender build failed.
  exit /b 1
)

echo.
echo Build OK. Run:
echo   %~dp0exewatch_appender.exe
