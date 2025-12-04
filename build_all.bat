@echo off
echo ============================================================
echo   Building Cadence Tool - Full Auto Build
echo ============================================================
echo.

echo [1/2] Building standalone installer...
call build_standalone.bat

echo.
echo [2/2] Building executable...
powershell.exe -ExecutionPolicy Bypass -File build_exe_simple.ps1

echo.
echo ============================================================
echo   All builds complete!
echo ============================================================
echo.
echo Output files:
echo   1. CadenceSVNPlugin_Standalone.bat
echo   2. CadenceTool\Cadence Tool.exe
echo.
echo Ready for distribution!
echo.
