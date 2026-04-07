Add-Type -AssemblyName System.Drawing

$base = "C:\Users\Admin\Documents\khrushchev\GunBlade\assets\Tiny Swords (Free Pack)\UI Elements"

function Cut-SpriteSheet {
    param(
        [string]$ImagePath,
        [string]$OutputDir,
        [int]$TileWidth,
        [int]$TileHeight,
        [string]$Prefix
    )

    $img = [System.Drawing.Image]::FromFile($ImagePath)
    $cols = [int][math]::Floor($img.Width / $TileWidth)
    $rows = [int][math]::Floor($img.Height / $TileHeight)

    if (!(Test-Path $OutputDir)) { New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null }

    for ($y = 0; $y -lt $rows; $y++) {
        for ($x = 0; $x -lt $cols; $x++) {
            $px = [int]$x * [int]$TileWidth
            $py = [int]$y * [int]$TileHeight
            $rect = New-Object System.Drawing.Rectangle($px, $py, [int]$TileWidth, [int]$TileHeight)
            $bitmap = New-Object System.Drawing.Bitmap([int]$TileWidth, [int]$TileHeight)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $destRect = New-Object System.Drawing.Rectangle(0, 0, [int]$TileWidth, [int]$TileHeight)
            $graphics.DrawImage($img, $destRect, $rect, [System.Drawing.GraphicsUnit]::Pixel)
            
            $fileName = "${Prefix}_r${y}_c${x}.png"
            $bitmap.Save("$OutputDir\$fileName", [System.Drawing.Imaging.ImageFormat]::Png)
            
            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }

    $img.Dispose()
    Write-Host "Нарезано: $(Split-Path $ImagePath -Leaf) -> $OutputDir (${cols}x${rows} тайлов)"
}

# BigRibbons.png (448x640) - 7x10 тайлов по 64px
Cut-SpriteSheet -ImagePath "$base\UI Elements\Ribbons\BigRibbons.png" -OutputDir "$base\cut\Ribbons\Big" -TileWidth 64 -TileHeight 64 -Prefix "BigRibbon"

# SmallRibbons.png (320x640) - 5x10 тайлов по 64px
Cut-SpriteSheet -ImagePath "$base\UI Elements\Ribbons\SmallRibbons.png" -OutputDir "$base\cut\Ribbons\Small" -TileWidth 64 -TileHeight 64 -Prefix "SmallRibbon"

# Swords.png (448x640) - 7x10 тайлов по 64px
Cut-SpriteSheet -ImagePath "$base\UI Elements\Swords\Swords.png" -OutputDir "$base\cut\Swords" -TileWidth 64 -TileHeight 64 -Prefix "Sword"

# Banner.png из магазина (704x512) - 11x8 тайлов по 64px
$bannerPath = (Get-ChildItem "$base\UI Banners from the store page" -Filter "Banner.png" -Recurse | Where-Object { $_.Length -gt 10KB } | Select-Object -First 1).FullName
if ($bannerPath) {
    Cut-SpriteSheet -ImagePath $bannerPath -OutputDir "$base\cut\Banners" -TileWidth 64 -TileHeight 64 -Prefix "Banner"
}

# Avatars (256x256) - 4x4 тайла по 64px
Get-ChildItem "$base\UI Elements\Human Avatars" -Filter "Avatars_*.png" | ForEach-Object {
    $name = $_.BaseName
    Cut-SpriteSheet -ImagePath $_.FullName -OutputDir "$base\cut\Avatars\$name" -TileWidth 64 -TileHeight 64 -Prefix $name
}

Write-Host "`nГотово! Все нарезанные файлы в: $base\cut\"
