param([string]$bg, [string]$s1, [string]$s2, [string]$out, [int]$W = 1440, [int]$H = 720)
Add-Type -AssemblyName System.Drawing
$o = New-Object System.Drawing.Bitmap $W, $H
$g = [System.Drawing.Graphics]::FromImage($o)
$g.SmoothingMode = 'AntiAlias'; $g.InterpolationMode = 'HighQualityBicubic'; $g.TextRenderingHint = 'AntiAliasGridFit'
# background: cover-crop
$b = [System.Drawing.Image]::FromFile($bg)
$k = [math]::Max($W / $b.Width, $H / $b.Height)
$sw = [int]($W / $k); $sh = [int]($H / $k)
$g.DrawImage($b, (New-Object System.Drawing.Rectangle 0, 0, $W, $H), (New-Object System.Drawing.Rectangle ([int](($b.Width - $sw) / 2)), ([int](($b.Height - $sh) / 2)), $sw, $sh), ([System.Drawing.GraphicsUnit]::Pixel))
# darken left half for text
$lg = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 0, 0, ([int]($W * 0.75) + 1), $H), ([System.Drawing.Color]::FromArgb(200, 0, 10, 20)), ([System.Drawing.Color]::FromArgb(0, 0, 10, 20)), 0.0
$g.FillRectangle($lg, 0, 0, [int]($W * 0.75), $H)
# text
$white = [System.Drawing.Brushes]::White
$soft = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 200, 230, 240))
$g.DrawString("SoCal Ocean`nFishing Regs", (New-Object System.Drawing.Font 'Segoe UI', ([float]($H * 0.1)), ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)), $white, [float]($W * 0.05), [float]($H * 0.17))
$g.DrawString("Fishing & spearfishing regs`non your Descent, with ID photos", (New-Object System.Drawing.Font 'Segoe UI', ([float]($H * 0.05)), ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)), $soft, [float]($W * 0.055), [float]($H * 0.50))
$g.DrawString("Offline  |  Bag, size, season, spear status  |  Unofficial", (New-Object System.Drawing.Font 'Segoe UI', ([float]($H * 0.03)), ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)), $soft, [float]($W * 0.057), [float]($H * 0.69))
# two watch screens as circles with a bezel ring
$d = [int]($H * 0.5)
$pos = @(@([int]($W * 0.56), [int]($H * 0.1)), @([int]($W * 0.56 + $d * 0.6), [int]($H * 0.38)))
$shots = @($s1, $s2)
for ($i = 0; $i -lt 2; $i++) {
  $x = $pos[$i][0]; $y = $pos[$i][1]; $r = 10
  $g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 45, 45, 50))), $x - $r, $y - $r, $d + 2 * $r, $d + 2 * $r)
  $s = [System.Drawing.Image]::FromFile($shots[$i])
  $p = New-Object System.Drawing.Drawing2D.GraphicsPath; $p.AddEllipse($x, $y, $d, $d)
  $g.SetClip($p); $g.FillEllipse([System.Drawing.Brushes]::Black, $x, $y, $d, $d)
  $g.DrawImage($s, $x, $y, $d, $d); $g.ResetClip()
}
$o.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
