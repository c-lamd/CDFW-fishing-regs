# Store icon: orange reef fish over kelp on an ocean gradient. Original artwork, no agency marks.
# powershell -File icon.ps1 -Size 512 -Out icon-512.png
param([int]$Size = 512, [string]$Out = "icon.png")
Add-Type -AssemblyName System.Drawing
$s = $Size / 100.0   # draw on a 100x100 grid
$o = New-Object System.Drawing.Bitmap $Size, $Size
$g = [System.Drawing.Graphics]::FromImage($o)
$g.SmoothingMode = 'AntiAlias'
function P([double]$x, [double]$y) { New-Object System.Drawing.PointF ([float]($x * $s)), ([float]($y * $s)) }
function C([int]$a, [int]$r, [int]$gr, [int]$b) { [System.Drawing.Color]::FromArgb($a, $r, $gr, $b) }

# ocean
$bg = New-Object System.Drawing.Drawing2D.LinearGradientBrush (P 0 0), (P 0 100), (C 255 18 120 150), (C 255 4 30 48)
$g.FillRectangle($bg, 0, 0, $Size, $Size)
# light rays
$ray = New-Object System.Drawing.SolidBrush (C 28 255 255 255)
$g.FillPolygon($ray, [System.Drawing.PointF[]]@((P 55 0), (P 70 0), (P 45 100), (P 25 100)))
$g.FillPolygon($ray, [System.Drawing.PointF[]]@((P 78 0), (P 86 0), (P 72 100), (P 60 100)))

# kelp strands
$kelp = New-Object System.Drawing.Pen (C 210 70 120 40), ([float](5 * $s))
$kelp.StartCap = 'Round'; $kelp.EndCap = 'Round'
$g.DrawBezier($kelp, (P 16 104), (P 6 70), (P 26 45), (P 14 8))
$g.DrawBezier($kelp, (P 88 104), (P 98 75), (P 80 55), (P 92 20))
$leaf = New-Object System.Drawing.SolidBrush (C 215 95 145 45)
foreach ($l in @(@(13, 80, -1), @(19, 58, 1), @(15, 33, -1), @(89, 84, 1), @(86, 62, -1), @(91, 40, 1))) {
  $x = $l[0]; $y = $l[1]; $d = $l[2]
  $g.FillClosedCurve($leaf, [System.Drawing.PointF[]]@((P $x $y), (P ($x + 6 * $d) ($y - 7)), (P ($x + 13 * $d) ($y - 5)), (P ($x + 7 * $d) ($y - 1))), [System.Drawing.Drawing2D.FillMode]::Winding, 0.6)
}

# fish (faces right): forked tail, fins, curved body with lighter back, eye, gill
$dark = New-Object System.Drawing.SolidBrush (C 255 220 80 10)
$g.FillPolygon($dark, [System.Drawing.PointF[]]@((P 32 50), (P 14 31), (P 21 50), (P 14 69)))
$g.FillClosedCurve($dark, [System.Drawing.PointF[]]@((P 38 36), (P 50 22), (P 64 30), (P 60 36)), [System.Drawing.Drawing2D.FillMode]::Winding, 0.5)
$g.FillClosedCurve($dark, [System.Drawing.PointF[]]@((P 44 63), (P 50 73), (P 58 64)), [System.Drawing.Drawing2D.FillMode]::Winding, 0.5)
$body = New-Object System.Drawing.Drawing2D.GraphicsPath
$body.AddBezier((P 29 50), (P 42 26), (P 72 26), (P 83 48))
$body.AddBezier((P 83 48), (P 84 53), (P 82 55), (P 78 58))
$body.AddBezier((P 78 58), (P 66 72), (P 42 72), (P 29 50))
$shade = New-Object System.Drawing.Drawing2D.LinearGradientBrush (P 0 30), (P 0 70), (C 255 255 150 40), (C 255 240 95 10)
$g.FillPath($shade, $body)
$g.FillEllipse([System.Drawing.Brushes]::White, [float](67 * $s), [float](40 * $s), [float](8 * $s), [float](8 * $s))
$g.FillEllipse((New-Object System.Drawing.SolidBrush (C 255 20 20 25)), [float](70 * $s), [float](42.5 * $s), [float](4 * $s), [float](4 * $s))
$gill = New-Object System.Drawing.Pen (C 160 190 70 5), ([float](1.6 * $s))
$g.DrawArc($gill, [float](56 * $s), [float](37 * $s), [float](10 * $s), [float](26 * $s), -70, 140)

$o.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
