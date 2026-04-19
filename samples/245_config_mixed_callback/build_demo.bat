@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"

dcc32.exe ^
  "%~dp0config_mixed.dpr" ^
  -B ^
  -NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win ^
  -u"C:\DEV\LoggerPro" ^
  -E"C:\DEV\LoggerPro\samples\245_config_mixed_callback"

if errorlevel 1 (
  echo.
  echo ERROR: config_mixed build failed.
  exit /b 1
)

echo.
echo Build OK. Run:
echo   %~dp0config_mixed.exe
