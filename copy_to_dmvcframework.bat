@echo off
REM ============================================================================
REM LoggerPro - Copy to DMVCFramework
REM ============================================================================
REM This script copies LoggerPro source files to the DMVCFramework lib folder
REM Usage: copy_to_dmvcframework.bat
REM ============================================================================

setlocal EnableDelayedExpansion

REM Source and destination paths
set "SRC=%~dp0"
set "DEST=..\dmvcframework\lib\loggerpro"

REM Check if destination exists
if not exist "%DEST%" (
    echo ERROR: Destination folder does not exist: %DEST%
    echo Please ensure DMVCFramework is installed at C:\DEV\dmvcframework
    exit /b 1
)

echo ============================================================================
echo LoggerPro - Copying files to DMVCFramework
echo ============================================================================
echo Source:      %SRC%
echo Destination: %DEST%
echo.

REM List of LoggerPro source files to copy
set FILES=^
    LoggerPro.pas ^
    LoggerPro.Builder.pas ^
    LoggerPro.CallbackAppender.pas ^
    LoggerPro.ConsoleAppender.pas ^
    LoggerPro.DBAppender.pas ^
    LoggerPro.DBAppender.ADO.pas ^
    LoggerPro.DBAppender.FireDAC.pas ^
    LoggerPro.ElasticSearchAppender.pas ^
    LoggerPro.EMailAppender.pas ^
    LoggerPro.FileAppender.pas ^
    LoggerPro.GlobalLogger.pas ^
    LoggerPro.HTTPAppender.pas ^
    LoggerPro.JSONLFileAppender.pas ^
    LoggerPro.MemoryAppender.pas ^
    LoggerPro.NSQAppender.pas ^
    LoggerPro.OutputDebugStringAppender.pas ^
    LoggerPro.Proxy.pas ^
    LoggerPro.Renderers.pas ^
    LoggerPro.TimeRotatingFileAppender.pas ^
    LoggerPro.UDPSyslogAppender.pas ^
    LoggerPro.Utils.pas ^
    LoggerPro.VCLListBoxAppender.pas ^
    LoggerPro.VCLListViewAppender.pas ^
    LoggerPro.VCLMemoAppender.pas ^
    LoggerPro.WindowsEventLogAppender.pas ^
    ThreadSafeQueueU.pas

REM Copy each file
set COUNT=0
for %%F in (%FILES%) do (
    if exist "%SRC%%%F" (
        copy /Y "%SRC%%%F" "%DEST%\%%F" >nul
        if !errorlevel! equ 0 (
            echo   [OK] %%F
            set /a COUNT+=1
        ) else (
            echo   [ERROR] Failed to copy %%F
        )
    ) else (
        echo   [SKIP] %%F (not found in source)
    )
)

REM Copy additional files
echo.
echo Copying additional files...
if exist "%SRC%License.txt" (
    copy /Y "%SRC%License.txt" "%DEST%\License.txt" >nul
    echo   [OK] License.txt
)
if exist "%SRC%VERSION.TXT" (
    copy /Y "%SRC%VERSION.TXT" "%DEST%\VERSION.TXT" >nul
    echo   [OK] VERSION.TXT
)

REM Copy packages (d100-d130)
echo.
echo Copying packages...
set PKGCOUNT=0
for %%D in (d100 d101 d102 d103 d104 d110 d120 d130) do (
    if exist "%SRC%packages\%%D" (
        if not exist "%DEST%\packages\%%D" mkdir "%DEST%\packages\%%D"
        copy /Y "%SRC%packages\%%D\loggerproRT.dpk" "%DEST%\packages\%%D\" >nul 2>&1
        copy /Y "%SRC%packages\%%D\loggerproRT.dproj" "%DEST%\packages\%%D\" >nul 2>&1
        echo   [OK] packages\%%D
        set /a PKGCOUNT+=1
    )
)

REM Delete old .dcu files
echo.
echo Deleting old .dcu files...
del /q "%DEST%\*.dcu" 2>nul
for %%D in (d100 d101 d102 d103 d104 d110 d120 d130) do (
    del /q "%DEST%\packages\%%D\*.dcu" 2>nul
    del /q "%DEST%\packages\%%D\*.dcp" 2>nul
    del /q "%DEST%\packages\%%D\*.bpl" 2>nul
)
echo   [OK] Old compiled files deleted

echo.
echo ============================================================================
echo Copied %COUNT% source files + %PKGCOUNT% packages to DMVCFramework
echo ============================================================================

endlocal
