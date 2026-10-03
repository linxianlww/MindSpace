# Generate dual-layer adaptive icon package from icon.png (per density folder)
# Background: radial gradient
# Foreground: icon.png kept as-is (white background NOT removed)
# Result: each mipmap-{m,h,x,xx,xxxhdpi}/ic_launcher{,_round}.png
Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = 'Stop'

$iconPng = Resolve-Path "$PSScriptRoot\..\icon.png"
$outRoot  = "$PSScriptRoot\..\android\app\src\main\res"

$densities = @{ mdpi=1; hdpi=1.5; xhdpi=2; xxhdpi=3; xxxhdpi=4 }
$basePx   = 144

$bgCore = [System.Drawing.Color]::FromArgb(0x09, 0x4C, 0xB9)
$bgEdge = [System.Drawing.Color]::FromArgb(0x0E, 0x54, 0xA8)

function New-RadialBgBrush($w, $h, $inner, $outer) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.AddEllipse(0, 0, $w, $h)
    $b = New-Object System.Drawing.Drawing2D.PathGradientBrush($p)
    $b.CenterColor = $inner
    $b.SurroundColors = @($outer)
    $b.CenterPoint = New-Object System.Drawing.PointF(($w * 0.45), ($h * 0.45))
    $p.Dispose()
    return $b
}

function New-QualityG($bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode      = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode  = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode    = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    return $g
}

$icon = [System.Drawing.Bitmap]::new($iconPng.Path)
Write-Host "Icon loaded (no chrome-key): $($icon.Width)x$($icon.Height)"

foreach ($kv in $densities.GetEnumerator()) {
    $folderName = "mipmap-$($kv.Key)"
    $s          = $kv.Value
    $px         = [int]($basePx * $s)
    $outDir     = "$outRoot\$folderName"
    if (-not (Test-Path $outDir)) { New-Item -ItemType Directory $outDir | Out-Null }

    $bmp = New-Object System.Drawing.Bitmap($px, $px, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g   = New-QualityG $bmp
    $bgBrush = New-RadialBgBrush $px $px $bgCore $bgEdge
    $g.FillRectangle($bgBrush, 0, 0, $px, $px)
    $bgBrush.Dispose()

    # Foreground at 160% of 66/108 safe zone, ears/tail overflow clipped by adaptive mask
    $safe  = [int]($px * 66.0 / 108.0)
    $fgSz  = [int]($safe * 1.60)
    $fgX   = [int](($px - $fgSz) / 2)
    $g.DrawImage($icon, $fgX, $fgX, $fgSz, $fgSz)
    $g.Dispose()

    $bmp.Save("$outDir\ic_launcher.png",       [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Save("$outDir\ic_launcher_round.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Write-Host "  $folderName : ic_launcher{,_round}.png -> $($px)x$($px) (fg $($fgSz)px, white bg kept)"
}
$icon.Dispose()
Write-Host "Done."
