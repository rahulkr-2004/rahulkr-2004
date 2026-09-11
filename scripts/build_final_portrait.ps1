Add-Type -AssemblyName System.Drawing

$inputPath = "c:\Users\rahul\OneDrive\Desktop\github\assets\jacket.png"
if (-not (Test-Path $inputPath)) {
    Write-Error "jacket.png not found!"
    exit 1
}

$fs = [System.IO.File]::Open($inputPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
$origBmp = [System.Drawing.Image]::FromStream($fs)

$cols = 100
$rows = 100
$cell = 10.0
$pad = 8.0
$dotScale = 0.92
$max_r = $cell * 0.5 * $dotScale # 4.60
$floor = 0.045 # ignore background pitch black
$revealTime = 2.5
$revealFade = 0.45

# Bicubic resampling to 100x100
$small = New-Object System.Drawing.Bitmap($cols, $rows)
$g = [System.Drawing.Graphics]::FromImage($small)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.DrawImage($origBmp, 0, 0, $cols, $rows)
$g.Dispose()
$origBmp.Dispose()
$fs.Close()
$fs.Dispose()

$totalW = $cols * $cell + 2 * $pad
$totalH = $rows * $cell + 2 * $pad

# Build reveal cascade transition animation matching Gargi's profile
$css = New-Object System.Text.StringBuilder
$null = $css.Append("<style>")
$null = $css.Append("@keyframes rv{from{opacity:0}to{opacity:1}}")
$null = $css.Append(".rw{animation:rv " + $revealFade.ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture) + "s ease-out both}")
$step = $revealTime / [Math]::Max($rows - 1, 1)
for ($y = 0; $y -lt $rows; $y++) {
    $delay = ($y * $step).ToString("F3", [System.Globalization.CultureInfo]::InvariantCulture)
    $null = $css.Append(".r$y{animation-delay:" + $delay + "s}")
}
$null = $css.Append("</style>")

$sb = New-Object System.Text.StringBuilder
$header = [string]::Format(
    [System.Globalization.CultureInfo]::InvariantCulture,
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {0:F1} {1:F1}" width="{0:F1}" height="{1:F1}" role="img" aria-label="Rahul Kumar, rendered as a dot matrix">{2}<g transform="translate({3:F1},{3:F1})">',
    $totalW, $totalH, $css.ToString(), $pad
)
$null = $sb.Append($header)

for ($y = 0; $y -lt $rows; $y++) {
    $rowSb = New-Object System.Text.StringBuilder
    $hasDots = $false
    
    for ($x = 0; $x -lt $cols; $x++) {
        $p = $small.GetPixel($x, $y)
        
        # Perceptual luminance (rec601)
        $lum = (0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B) / 255.0
        
        # Skip pure pitch black background
        if ($lum -lt $floor -or ($p.R -lt 15 -and $p.G -lt 15 -and $p.B -lt 15)) {
            continue
        }
        
        # Power curve matching dotify.py: r = max_r * (v ** 0.85)
        $r = $max_r * [Math]::Pow($lum, 0.85)
        if ($r -lt 0.20) { continue }
        
        $cx = $x * $cell + $cell / 2.0
        $cy = $y * $cell + $cell / 2.0
        $fill = [string]::Format("#{0:X2}{1:X2}{2:X2}", $p.R, $p.G, $p.B)
        
        $dot = [string]::Format(
            [System.Globalization.CultureInfo]::InvariantCulture,
            '<circle cx="{0:F1}" cy="{1:F1}" r="{2:F2}" fill="{3}"/>',
            $cx, $cy, $r, $fill
        )
        $null = $rowSb.Append($dot)
        $hasDots = $true
    }
    
    if ($hasDots) {
        $null = $sb.Append([string]::Format('<g class="rw r{0}">{1}</g>', $y, $rowSb.ToString()))
    }
}

$small.Dispose()
$null = $sb.Append("</g></svg>")

$outPath = "c:\Users\rahul\OneDrive\Desktop\github\assets\portrait.svg"
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outPath, $sb.ToString(), $utf8NoBom)
Write-Host "Success! Created $outPath with row-by-row cascade transition animation!"
