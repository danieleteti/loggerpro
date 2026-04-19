@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"

dcc32.exe ^
  "%~dp0config_per_level.dpr" ^
  -B ^
  -NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win ^
  -u"C:\DEV\LoggerPro" ^
  -E"C:\DEV\LoggerPro\samples\244_config_per_level"

if errorlevel 1 (
  echo.
  echo ERROR: config_per_level build failed.
  exit /b 1
)

echo.
echo Build OK. Run:
echo   %~dp0config_per_level.exe
