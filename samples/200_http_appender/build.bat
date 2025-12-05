@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild "C:\DEV\loggerpro\samples\200_http_appender\http_appender.dproj" /t:Build /p:Config=Debug /p:Platform=Win32
