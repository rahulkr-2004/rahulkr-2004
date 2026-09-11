Add-Type -AssemblyName System.Drawing

$imgPath = "c:\Users\rahul\OneDrive\Desktop\github\assets\avatar.png"
if (-not (Test-Path $imgPath)) {
    Write-Error "avatar.png not found!"
    exit 1
}

$bmp = [System.Drawing.Bitmap]::FromFile($imgPath)
$cols = 100
$origW = $bmp.Width
$origH = $bmp.Height

# Calculate square crop centered on face
$side = [Math]::Min($origW, $origH)
$cropX = [Math]::Max(0, [int](($origW - $side) / 2))
$cropY = [Math]::Max(0, [int](($origH - $side) / 2))

$cropRect = New-Object System.Drawing.Rectangle($cropX, $cropY, $side, $side)
$cropped = $bmp.Clone($cropRect, $bmp.PixelFormat)
$bmp.Dispose()

# Rows proportional (1:1 square)
$rows = 100
$cell = 6.0
$pad = 10.0

$resized = New-Object System.Drawing.Bitmap($cols, $rows)
$g = [System.Drawing.Graphics]::FromImage($resized)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
$g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
$g.DrawImage($cropped, 0, 0, $cols, $rows)
$g.Dispose()
$cropped.Dispose()

$w = $cols * $cell
$h = $rows * $cell
$totalW = $w + 2 * $pad
$totalH = $h + 2 * $pad

$lanes = 10
$duration = 2.8

$cssBuilder = New-Object System.Text.StringBuilder
$null = $cssBuilder.Append("<style>")
$null = $cssBuilder.Append("@keyframes dp{0%,100%{opacity:.45}50%{opacity:1}}")
$null = $cssBuilder.Append(".d{animation:dp " + $duration + "s ease-in-out infinite}")
for ($i = 0; $i -lt $lanes; $i++) {
    $delay = ($i / $lanes * $duration).ToString("F2", [System.Globalization.CultureInfo]::InvariantCulture)
    $null = $cssBuilder.Append(".l$i{animation-delay:" + $delay + "s}")
}
$null = $cssBuilder.Append("</style>")

$svgHeader = [string]::Format(
    [System.Globalization.CultureInfo]::InvariantCulture,
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {0:F0} {1:F0}" width="{0:F0}" height="{1:F0}" role="img" aria-label="Rahul Kumar, rendered as a dot matrix">{2}<rect width="100%" height="100%" fill="none"/><g transform="translate({3:F0},{3:F0}">',
    $totalW, $totalH, $cssBuilder.ToString(), $pad
)

$sb = New-Object System.Text.StringBuilder
$null = $sb.Append($svgHeader)

$max_r = $cell * 0.5 * 0.94
$centerCol = $cols / 2.0
$centerRow = $rows / 2.0
$maxRadius = $cols / 2.0

for ($y = 0; $y -lt $rows; $y++) {
    for ($x = 0; $x -lt $cols; $x++) {
        $p = $resized.GetPixel($x, $y)
        
        # Soft circular vignette to fade smoothly at edges
        $dx = $x - $centerCol + 0.5
        $dy = $y - $centerRow + 0.5
        $dist = [Math]::Sqrt($dx * $dx + $dy * $dy)
        
        $feather = 3.0
        $falloff = 1.0
        if ($dist -gt ($maxRadius - $feather)) {
            $falloff = ($maxRadius - $dist) / $feather
            if ($falloff -le 0.0) { continue }
        }
        
        # Standard perceptual luminance
        $lum = (0.299 * $p.R + 0.587 * $p.G + 0.114 * $p.B) / 255.0
        
        # Apply gentle gamma curve & falloff
        $v = [Math]::Pow($lum, 0.95) * $falloff
        if ($v -lt 0.04) { continue }
        
        $r = $max_r * [Math]::Pow($v, 0.85)
        if ($r -lt 0.20) { continue }
        
        $cx = $x * $cell + $cell / 2.0
        $cy = $y * $cell + $cell / 2.0
        
        # Full true natural RGB color from the source photo!
        $hexColor = [string]::Format("#{0:X2}{1:X2}{2:X2}", $p.R, $p.G, $p.B)
        
        $lane = $x % $lanes
        $line = [string]::Format(
            [System.Globalization.CultureInfo]::InvariantCulture,
            '<circle cx="{0:F1}" cy="{1:F1}" r="{2:F2}" fill="{3}" class="d l{4}"/>',
            $cx, $cy, $r, $hexColor, $lane
        )
        $null = $sb.Append($line)
    }
}

$resized.Dispose()
$null = $sb.Append("`n  </g>`n</svg>")

$outPath = "c:\Users\rahul\OneDrive\Desktop\github\assets\portrait.svg"
[System.IO.File]::WriteAllText($outPath, $sb.ToString(), [System.Text.Encoding]::UTF8)
Write-Host "Generated color dot-matrix portrait successfully at $outPath!"
