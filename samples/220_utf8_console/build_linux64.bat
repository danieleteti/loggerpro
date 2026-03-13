@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild "%~dp0utf8_console.dproj" /t:Build /p:Config=Debug /p:Platform=Linux64
