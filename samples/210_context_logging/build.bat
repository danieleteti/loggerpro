@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild "context_logging.dproj" /t:Build /p:Config=Debug /p:Platform=Win32 /v:minimal
