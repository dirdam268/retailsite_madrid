Add-Type -AssemblyName System.Drawing

function New-Icon([int]$size, [string]$path, [bool]$rounded, [double]$pad) {
  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.Clear([System.Drawing.Color]::Transparent)

  $bg = [System.Drawing.Color]::FromArgb(255, 22, 163, 74) # #16a34a
  $brush = New-Object System.Drawing.SolidBrush $bg

  if ($rounded) {
    $r = $size * 0.22
    $path2 = New-Object System.Drawing.Drawing2D.GraphicsPath
    $d = $r * 2
    $path2.AddArc(0, 0, $d, $d, 180, 90)
    $path2.AddArc($size - $d, 0, $d, $d, 270, 90)
    $path2.AddArc($size - $d, $size - $d, $d, $d, 0, 90)
    $path2.AddArc(0, $size - $d, $d, $d, 90, 90)
    $path2.CloseFigure()
    $g.FillPath($brush, $path2)
  } else {
    $g.FillRectangle($brush, 0, 0, $size, $size)
  }

  $inner = $size * (1 - $pad * 2)
  $ox = $size * $pad
  $oy = $size * $pad
  $s = $inner / 100.0

  $penW = [Math]::Max(2, 6 * $s)
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::White), $penW
  $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

  $pts = @(
    [System.Drawing.PointF]::new($ox + 18*$s, $oy + 22*$s),
    [System.Drawing.PointF]::new($ox + 30*$s, $oy + 22*$s),
    [System.Drawing.PointF]::new($ox + 38*$s, $oy + 62*$s),
    [System.Drawing.PointF]::new($ox + 80*$s, $oy + 62*$s),
    [System.Drawing.PointF]::new($ox + 88*$s, $oy + 34*$s),
    [System.Drawing.PointF]::new($ox + 34*$s, $oy + 34*$s)
  )
  $g.DrawLines($pen, $pts)

  $wheelBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $wr = 7 * $s
  $g.FillEllipse($wheelBrush, $ox + 46*$s - $wr, $oy + 78*$s - $wr, $wr*2, $wr*2)
  $g.FillEllipse($wheelBrush, $ox + 74*$s - $wr, $oy + 78*$s - $wr, $wr*2, $wr*2)

  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $g.Dispose()
  $bmp.Dispose()
}

$dir = Join-Path $PSScriptRoot "icons"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

New-Icon -size 512 -path (Join-Path $dir "icon-512.png") -rounded $true -pad 0.0
New-Icon -size 512 -path (Join-Path $dir "icon-512-maskable.png") -rounded $false -pad 0.12
New-Icon -size 192 -path (Join-Path $dir "icon-192.png") -rounded $true -pad 0.0
New-Icon -size 180 -path (Join-Path $dir "apple-touch-icon.png") -rounded $false -pad 0.06
New-Icon -size 32  -path (Join-Path $dir "favicon-32.png") -rounded $true -pad 0.0

Write-Host "Iconos generados en $dir"
