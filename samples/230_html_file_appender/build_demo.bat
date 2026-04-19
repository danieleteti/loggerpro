@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"

dcc32.exe ^
  "%~dp0html_demo.dpr" ^
  -B ^
  -NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win ^
  -u"C:\DEV\LoggerPro" ^
  -E"C:\DEV\LoggerPro\samples\230_html_file_appender"

if errorlevel 1 (
  echo.
  echo ERROR: html_demo build failed.
  exit /b 1
)

echo.
echo Build OK. Run:
echo   %~dp0html_demo.exe
