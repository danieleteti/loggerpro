@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat"
msbuild "C:\DEV\loggerpro\unittests\UnitTests.dproj" /t:Build /p:Config=CI /p:Platform=Win32 /v:minimal
