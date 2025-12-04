# Create a simple ICO file for Cadence Tool
# This creates a 16x16 icon with "CT" text

$width = 16
$height = 16

Add-Type -AssemblyName System.Drawing

$bitmap = New-Object System.Drawing.Bitmap($width, $height)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

# Fill background with blue
$brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(0, 120, 215))
$graphics.FillRectangle($brush, 0, 0, $width, $height)

# Draw "CT" text in white
$font = New-Object System.Drawing.Font("Arial", 7, [System.Drawing.FontStyle]::Bold)
$textBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
$graphics.DrawString("CT", $font, $textBrush, 1, 3)

# Save as ICO
$iconPath = Join-Path $PSScriptRoot "app.ico"
$icon = [System.Drawing.Icon]::FromHandle($bitmap.GetHicon())
$stream = [System.IO.File]::Create($iconPath)
$icon.Save($stream)
$stream.Close()

$graphics.Dispose()
$bitmap.Dispose()
$brush.Dispose()
$textBrush.Dispose()
$font.Dispose()

Write-Host "Icon created: $iconPath" -ForegroundColor Green
