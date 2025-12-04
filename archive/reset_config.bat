@echo off
echo ====================================
echo Reset SVN Plugin Configuration
echo ====================================
echo.

REM Find and delete config file in common locations
set "found=0"

REM Check current directory
if exist ".capture_svn_config" (
    del ".capture_svn_config"
    echo Config file deleted: %CD%\.capture_svn_config
    set "found=1"
)

REM Check user's Cadence project directories (common working directories)
for /d %%d in (C:\Cadence\*, D:\Cadence\*, C:\Users\%USERNAME%\Documents\*) do (
    if exist "%%d\.capture_svn_config" (
        del "%%d\.capture_svn_config"
        echo Config file deleted: %%d\.capture_svn_config
        set "found=1"
    )
)

echo.
if "%found%"=="1" (
    echo ====================================
    echo Configuration reset complete!
    echo Auto-show will be enabled on next startup
    echo ====================================
) else (
    echo No config file found.
    echo The plugin will use default settings (auto-show enabled^)
)
echo.
echo Press any key to exit...
pause >nul
