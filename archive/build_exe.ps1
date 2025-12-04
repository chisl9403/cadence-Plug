# Build Cadence Tool Executable with Icon
# This script compiles the BAT installer into an EXE with custom icon

$ErrorActionPreference = "Stop"

Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Building Cadence Tool Executable" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Step 1: Generate icon
Write-Host "[1/5] Generating icon..." -ForegroundColor Yellow
if (-not (Test-Path "app.ico")) {
    & powershell.exe -ExecutionPolicy Bypass -File "icon.ps1"
}
if (Test-Path "app.ico") {
    Write-Host "      > Icon ready: app.ico" -ForegroundColor Green
} else {
    Write-Host "      [ERROR] Icon generation failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 2: Rebuild standalone installer
Write-Host "[2/5] Rebuilding installer..." -ForegroundColor Yellow
& cmd.exe /c "build_standalone.bat" | Out-Null
if (Test-Path "CadenceSVNPlugin_Standalone.bat") {
    $size = [Math]::Round((Get-Item "CadenceSVNPlugin_Standalone.bat").Length / 1KB, 2)
    Write-Host "      > Installer ready: $size KB" -ForegroundColor Green
} else {
    Write-Host "      [ERROR] Build failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 3: Create IExpress SED file with icon
Write-Host "[3/5] Creating installer configuration..." -ForegroundColor Yellow

$sedContent = @"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=0
HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$PWD\CadenceTool_temp.exe
FriendlyName=Cadence Tool - SVN Plugin Installer
AppLaunched=cmd /c CadenceSVNPlugin_Standalone.bat
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
FILE0="CadenceSVNPlugin_Standalone.bat"
[SourceFiles]
SourceFiles0=$PWD\
[SourceFiles0]
%FILE0%=
"@

$sedFile = "$PWD\installer_with_icon.sed"
[System.IO.File]::WriteAllText($sedFile, $sedContent, [System.Text.Encoding]::ASCII)
Write-Host "      > Configuration created" -ForegroundColor Green
Write-Host ""

# Step 4: Build with IExpress (without icon first)
Write-Host "[4/5] Compiling executable..." -ForegroundColor Yellow
$iexpress = "$env:SystemRoot\System32\iexpress.exe"

if (Test-Path $iexpress) {
    $proc = Start-Process -FilePath $iexpress -ArgumentList "/N `"$sedFile`"" -Wait -NoNewWindow -PassThru
    
    if ($proc.ExitCode -eq 0 -and (Test-Path "CadenceTool_temp.exe")) {
        Write-Host "      > EXE compiled successfully" -ForegroundColor Green
    } else {
        Write-Host "      [ERROR] IExpress compilation failed (Exit code: $($proc.ExitCode))" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      [ERROR] IExpress not found" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 5: Add icon using ResourceHacker or native method
Write-Host "[5/5] Adding icon to executable..." -ForegroundColor Yellow

# Try to use ResourceHacker if available
$rhPath = "C:\Program Files (x86)\Resource Hacker\ResourceHacker.exe"
if (-not (Test-Path $rhPath)) {
    $rhPath = "ResourceHacker.exe"
}

$outputDir = "$PWD\CadenceTool"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$finalExe = "$outputDir\Cadence Tool.exe"

try {
    if (Get-Command "ResourceHacker.exe" -ErrorAction SilentlyContinue) {
        # Use ResourceHacker to add icon
        & ResourceHacker.exe -open "CadenceTool_temp.exe" -save "$finalExe" -action addoverwrite -res "app.ico" -mask ICONGROUP,MAINICON,
        Write-Host "      > Icon added with ResourceHacker" -ForegroundColor Green
    } else {
        # Just copy without icon modification
        Copy-Item "CadenceTool_temp.exe" "$finalExe" -Force
        Write-Host "      > EXE created (ResourceHacker not found, icon not embedded)" -ForegroundColor Yellow
    }
} catch {
    Copy-Item "CadenceTool_temp.exe" "$finalExe" -Force
    Write-Host "      > EXE created (icon embedding skipped)" -ForegroundColor Yellow
}

# Cleanup temp files
Remove-Item "CadenceTool_temp.exe" -Force -ErrorAction SilentlyContinue
Remove-Item $sedFile -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   Build Complete!" -ForegroundColor Cyan
Write-Host "════════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Output directory: $outputDir" -ForegroundColor Green
Write-Host "Executable: Cadence Tool.exe" -ForegroundColor Green

$exeSize = [Math]::Round((Get-Item "$finalExe").Length / 1KB, 2)
Write-Host "Size: $exeSize KB" -ForegroundColor Green
Write-Host ""
Write-Host "Distribution ready!" -ForegroundColor White
Write-Host ""
Write-Host "Simply distribute the 'CadenceTool' folder to users" -ForegroundColor White
Write-Host "They can double-click 'Cadence Tool.exe' to install" -ForegroundColor White
Write-Host ""
Write-Host "Features:" -ForegroundColor White
Write-Host "  - Windows executable with custom icon" -ForegroundColor White
Write-Host "  - Install/Uninstall options" -ForegroundColor White
Write-Host "  - Auto-detects Cadence installation" -ForegroundColor White
Write-Host ""
