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

# Step 1: Collect non-background pixels and build histogram
$hist = New-Object int[] 256
$subjectPixels = 0
$lumGrid = New-Object 'double[,]' $cols, $rows
$isSubject = New-Object 'bool[,]' $cols, $rows

for ($y = 0; $y -lt $rows; $y++) {
    for ($x = 0; $x -lt $cols; $x++) {
        $p = $small.GetPixel($x, $y)
        $lum = (0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B) / 255.0
        
        # Background threshold: pitch black background
        if ($p.R -lt 16 -and $p.G -lt 16 -and $p.B -lt 16) {
            $isSubject[$x, $y] = $false
        } else {
            $isSubject[$x, $y] = $true
            $lumByte = [Math]::Min(255, [Math]::Max(0, [int]($lum * 255.0)))
            $hist[$lumByte]++
            $subjectPixels++
        }
        $lumGrid[$x, $y] = $lum
    }
}

# Step 2: Compute Cumulative Distribution Function (CDF) for equalization
$cdf = New-Object int[] 256
$cum = 0
$cdfMin = -1
for ($i = 0; $i -lt 256; $i++) {
    $cum += $hist[$i]
    $cdf[$i] = $cum
    if ($cum -gt 0 -and $cdfMin -eq -1) {
        $cdfMin = $cum
    }
}

# Step 3: Build CSS animation cascade matching Gargi exactly
$totalW = $cols * $cell + 2 * $pad
$totalH = $rows * $cell + 2 * $pad

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
        if (-not $isSubject[$x, $y]) {
            continue
        }
        
        $p = $small.GetPixel($x, $y)
        $lum = $lumGrid[$x, $y]
        $lumByte = [Math]::Min(255, [Math]::Max(0, [int]($lum * 255.0)))
        
        # Equalized luminance (0.0 to 1.0)
        $eqLum = ($cdf[$lumByte] - $cdfMin) / [double]($subjectPixels - $cdfMin)
        
        # Blend original and equalized luminance for natural balance (70% equalized + 30% original)
        $blendLum = 0.70 * $eqLum + 0.30 * $lum
        
        # Power curve for dot sizing
        $v = [Math]::Pow($blendLum, 0.75)
        $r = $max_r * (0.22 + 0.78 * $v)
        
        if ($r -lt 0.35) { continue }
        if ($r -gt $max_r) { $r = $max_r }
        
        $cx = $x * $cell + $cell / 2.0
        $cy = $y * $cell + $cell / 2.0
        
        # Boost color saturation and warmth slightly so it looks vibrant like Gargi's
        $rVal = [Math]::Min(255, [int]($p.R * 1.12))
        $gVal = [Math]::Min(255, [int]($p.G * 1.05))
        $bVal = [Math]::Min(255, [int]($p.B * 0.98))
        $fill = [string]::Format("#{0:X2}{1:X2}{2:X2}", $rVal, $gVal, $bVal)
        
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
Write-Host "Success! Created enhanced $outPath with full coverage & cascade transition!"
