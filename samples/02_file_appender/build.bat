@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\rsvars.bat"
msbuild "C:\DEV\loggerpro\samples\02_file_appender\file_appender.dproj" /t:Build /p:Config=Debug /p:Platform=Win32
