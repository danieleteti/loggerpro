@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"

dcc32.exe ^
  "%~dp0colors_demo.dpr" ^
  -B ^
  -NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win ^
  -u"C:\DEV\LoggerPro" ^
  -E"C:\DEV\LoggerPro\samples\03b_console_with_colors_appender"

if errorlevel 1 (
  echo.
  echo ERROR: colors_demo build failed.
  exit /b 1
)

echo.
echo Build OK. Run:
echo   %~dp0colors_demo.exe
