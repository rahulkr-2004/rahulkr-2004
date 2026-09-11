Add-Type -AssemblyName System.Drawing

$imgPath = "c:\Users\rahul\OneDrive\Desktop\github\assets\avatar.png"
$bmp = [System.Drawing.Bitmap]::FromFile($imgPath)
$cols = 72
$rows = 72
$cell = 8
$pad = 12

# Rescale image to 72x72
$resized = New-Object System.Drawing.Bitmap($cols, $rows)
$g = [System.Drawing.Graphics]::FromImage($resized)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($bmp, 0, 0, $cols, $rows)
$g.Dispose()
$bmp.Dispose()

$w = $cols * $cell
$h = $rows * $cell
$totalW = $w + 2 * $pad
$totalH = $h + 2 * $pad

$svgHeader = @"
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalW $totalH" width="$totalW" height="$totalH" role="img" aria-label="Rahul Kumar, rendered as a dot matrix">
  <style>
    @keyframes dp { 0%, 100% { opacity: .45 } 50% { opacity: 1 } }
    .d { animation: dp 2.8s ease-in-out infinite }
    .l0 { animation-delay: 0.00s }
    .l1 { animation-delay: 0.28s }
    .l2 { animation-delay: 0.56s }
    .l3 { animation-delay: 0.84s }
    .l4 { animation-delay: 1.12s }
    .l5 { animation-delay: 1.40s }
    .l6 { animation-delay: 1.68s }
    .l7 { animation-delay: 1.96s }
    .l8 { animation-delay: 2.24s }
    .l9 { animation-delay: 2.52s }
  </style>
  <rect width="100%" height="100%" fill="none"/>
  <g transform="translate($pad,$pad)">
"@

$sb = New-Object System.Text.StringBuilder
$null = $sb.Append($svgHeader)

$max_r = $cell * 0.5 * 0.95
$centerCol = $cols / 2
$centerRow = $rows / 2
$maxDist = $cols / 2

for ($y = 0; $y -lt $rows; $y++) {
    for ($x = 0; $x -lt $cols; $x++) {
        $pixel = $resized.GetPixel($x, $y)
        
        # Circular vignette / cutout
        $dx = $x - $centerCol
        $dy = $y - $centerRow
        $dist = [Math]::Sqrt($dx * $dx + $dy * $dy)
        if ($dist -gt ($maxDist - 1)) {
            continue
        }
        
        # Perceived luminance: standard rec601
        $lum = (0.299 * $pixel.R + 0.587 * $pixel.G + 0.114 * $pixel.B) / 255.0
        
        # Invert or enhance contrast so face details emerge
        # In hacker dark theme, brighter pixels get larger dots
        $v = [Math]::Pow($lum, 0.9)
        if ($v -lt 0.08) {
            continue
        }
        
        $r = $max_r * [Math]::Pow($v, 0.8)
        if ($r -lt 0.4) {
            continue
        }
        
        $cx = $x * $cell + $cell / 2.0
        $cy = $y * $cell + $cell / 2.0
        
        # GitHub Green matrix tones based on luminance
        $fill = "#39d353"
        if ($v -lt 0.35) {
            $fill = "#0e4429"
        } elseif ($v -lt 0.60) {
            $fill = "#006d32"
        } elseif ($v -lt 0.85) {
            $fill = "#26a641"
        } else {
            $fill = "#39d353"
        }
        
        $lane = $x % 10
        $line = [string]::Format([System.Globalization.CultureInfo]::InvariantCulture, '<circle cx="{0:F1}" cy="{1:F1}" r="{2:F2}" fill="{3}" class="d l{4}"/>', $cx, $cy, $r, $fill, $lane)
        $null = $sb.Append($line)
    }
}

$resized.Dispose()
$null = $sb.Append("`n  </g>`n</svg>")

[System.IO.File]::WriteAllText("c:\Users\rahul\OneDrive\Desktop\github\assets\portrait.svg", $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Successfully generated assets/portrait.svg from Rahul's avatar!"
