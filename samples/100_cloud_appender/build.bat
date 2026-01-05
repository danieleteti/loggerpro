@echo off
cd /d "%~dp0"
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild CloudAppenderDemo.dproj /t:Build /p:Config=Debug /p:Platform=Win32
