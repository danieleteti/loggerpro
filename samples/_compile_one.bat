@echo off
call "C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\rsvars.bat" >nul
dcc32.exe -B -NSSystem;System.Win;Winapi;Vcl;Vcl.Imaging;Data;Data.Win -u"C:\DEV\LoggerPro" -U"C:\DEV\LoggerPro" %1
