Add-Type -AssemblyName System.Drawing

$inputPath = "c:\Users\rahul\OneDrive\Desktop\github\assets\jacket.png"
$fs = [System.IO.File]::Open($inputPath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
$origBmp = [System.Drawing.Image]::FromStream($fs)

$cols = 100
$rows = 100
$cell = 10.0
$pad = 8.0
$dotScale = 0.92
$max_r = $cell * 0.5 * $dotScale # 4.60
$floor = 0.045 # ignore background pitch black

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

$sb = New-Object System.Text.StringBuilder
$header = [string]::Format(
    [System.Globalization.CultureInfo]::InvariantCulture,
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {0:F1} {1:F1}" width="{0:F1}" height="{1:F1}" role="img" aria-label="Rahul Kumar, rendered as a dot matrix"><rect width="100%" height="100%" fill="none"/><g transform="translate({2:F1},{2:F1}">',
    $totalW, $totalH, $pad
)
$null = $sb.Append($header)

for ($y = 0; $y -lt $rows; $y++) {
    for ($x = 0; $x -lt $cols; $x++) {
        $p = $small.GetPixel($x, $y)
        
        # Perceptual luminance (rec601)
        $lum = (0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B) / 255.0
        
        # Skip pure pitch black background
        if ($lum -lt $floor -and $p.R -lt 18 -and $p.G -lt 18 -and $p.B -lt 18) {
            continue
        }
        
        # Power curve for dot sizing
        $v = [Math]::Pow($lum, 0.85)
        $r = $max_r * (0.20 + 0.80 * $v)
        if ($r -lt 0.4) { continue }
        
        $cx = $x * $cell + $cell / 2.0
        $cy = $y * $cell + $cell / 2.0
        $fill = [string]::Format("#{0:X2}{1:X2}{2:X2}", $p.R, $p.G, $p.B)
        
        $dot = [string]::Format(
            [System.Globalization.CultureInfo]::InvariantCulture,
            '<circle cx="{0:F1}" cy="{1:F1}" r="{2:F2}" fill="{3}"/>',
            $cx, $cy, $r, $fill
        )
        $null = $sb.Append($dot)
    }
}

$small.Dispose()
$null = $sb.Append("`n  </g>`n</svg>")

$outPath = "c:\Users\rahul\OneDrive\Desktop\github\assets\portrait.svg"
[System.IO.File]::WriteAllText($outPath, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Success! Created $outPath"
