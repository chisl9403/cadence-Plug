# Build Cadence Tool - Simple EXE Builder
# Creates a .NET compiled executable wrapper

$ErrorActionPreference = "Stop"

Write-Host "Building Cadence Tool Executable..." -ForegroundColor Cyan
Write-Host ""

# Create output directory
$outputDir = "$PSScriptRoot\CadenceTool"

# Backup existing README if it exists
$readmeBackup = $null
if (Test-Path "$outputDir\README.txt") {
    $readmeBackup = "$PSScriptRoot\README_backup.txt"
    Copy-Item "$outputDir\README.txt" $readmeBackup -Force
}

if (Test-Path $outputDir) {
    Remove-Item -Recurse -Force $outputDir
}
New-Item -ItemType Directory -Path $outputDir | Out-Null

# Copy the BAT installer
Write-Host "[1/3] Copying installer..." -ForegroundColor Yellow
Copy-Item "$PSScriptRoot\CadenceSVNPlugin_Standalone.bat" "$outputDir\installer.bat" -Force
$batSize = [Math]::Round((Get-Item "$outputDir\installer.bat").Length / 1KB, 2)
Write-Host "      > Copied: $batSize KB" -ForegroundColor Green
Write-Host ""

# Create C# wrapper source
Write-Host "[2/3] Creating executable wrapper..." -ForegroundColor Yellow

$csCode = @'
using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;

namespace CadenceTool
{
    class Program
    {
        [STAThread]
        static void Main(string[] args)
        {
            try
            {
                // Extract embedded BAT file
                string tempBat = Path.Combine(Path.GetTempPath(), "CadenceSVN_" + Guid.NewGuid().ToString() + ".bat");
                
                using (Stream stream = Assembly.GetExecutingAssembly().GetManifestResourceStream("CadenceTool.installer.bat"))
                {
                    if (stream == null)
                    {
                        Console.WriteLine("Error: Installer resource not found.");
                        Console.ReadKey();
                        return;
                    }
                    
                    using (FileStream fileStream = File.Create(tempBat))
                    {
                        stream.CopyTo(fileStream);
                    }
                }
                
                // Run the BAT file
                ProcessStartInfo psi = new ProcessStartInfo
                {
                    FileName = tempBat,
                    UseShellExecute = true,
                    WorkingDirectory = Path.GetDirectoryName(tempBat)
                };
                
                Process process = Process.Start(psi);
                process.WaitForExit();
                
                // Cleanup
                try { File.Delete(tempBat); } catch { }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error: " + ex.Message);
                Console.ReadKey();
            }
        }
    }
}
'@

$csFile = "$outputDir\Program.cs"
[System.IO.File]::WriteAllText($csFile, $csCode, [System.Text.Encoding]::UTF8)

# Compile with csc.exe
$cscPath = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
if (-not (Test-Path $cscPath)) {
    $cscPath = "C:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe"
}

if (Test-Path $cscPath) {
    $exePath = "$outputDir\Cadence Tool.exe"
    
    # Compile
    & $cscPath /out:"$exePath" /target:winexe /win32icon:"$PSScriptRoot\app.ico" /resource:"$outputDir\installer.bat,CadenceTool.installer.bat" "$csFile" 2>&1 | Out-Null
    
    if (Test-Path $exePath) {
        Write-Host "      > Executable created" -ForegroundColor Green
        
        # Remove source files
        Remove-Item "$csFile" -Force
        Remove-Item "$outputDir\installer.bat" -Force
        
        $exeSize = [Math]::Round((Get-Item $exePath).Length / 1KB, 2)
        Write-Host "      > Size: $exeSize KB" -ForegroundColor Green
    } else {
        Write-Host "      [ERROR] Compilation failed" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "      [ERROR] .NET compiler not found" -ForegroundColor Red
    Write-Host "      Please install .NET Framework 4.0 or later" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "[3/3] Creating README..." -ForegroundColor Yellow

# Restore backed up README if it exists
if ($readmeBackup -and (Test-Path $readmeBackup)) {
    Copy-Item $readmeBackup "$outputDir\README.txt" -Force
    Remove-Item $readmeBackup -Force
    Write-Host "      > Restored existing README.txt" -ForegroundColor Green
} else {
    # Create default README
    $readmeContent = @"
Cadence Tool - SVN 插件安装程序
====================================

版本: 1.2
日期: 2025-12-09
作者: Sloan Chi

请查看项目文档获取详细使用说明。
项目地址: https://github.com/chisl9403/cadence-Plug

简要说明:
--------
双击运行 Cadence Tool.exe 即可安装插件。
安装后重启 Cadence Capture，工具栏将自动出现在屏幕右下角。

"@
    [System.IO.File]::WriteAllText("$outputDir\README.txt", $readmeContent, [System.Text.Encoding]::UTF8)
    Write-Host "      > README.txt created" -ForegroundColor Green
}

Write-Host ""
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Output: $outputDir" -ForegroundColor Cyan
Write-Host "Executable: Cadence Tool.exe" -ForegroundColor Cyan
Write-Host ""
Write-Host "Ready for distribution!" -ForegroundColor Green
Write-Host ""

exit 0
