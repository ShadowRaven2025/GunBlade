Add-Type -AssemblyName System.Drawing

$base = "C:\Users\admin\Documents\khrushcev\GunBlade\assets\Tiny Swords (Free Pack)\Units\Yellow Units\Lancer"
$outputBase = "C:\Users\admin\Documents\khrushcev\GunBlade\assets\Tiny Swords (Free Pack)\Units\Yellow Units\Lancer\cut"

function Cut-SpriteSheet {
    param(
        [string]$ImagePath,
        [string]$OutputDir,
        [int]$TileWidth,
        [int]$TileHeight,
        [string]$OutputName
    )

    if (!(Test-Path $ImagePath)) {
        Write-Host "Файл не найден: $ImagePath" -ForegroundColor Red
        return
    }

    $img = [System.Drawing.Image]::FromFile($ImagePath)
    $cols = [int][math]::Floor($img.Width / $TileWidth)
    $rows = [int][math]::Floor($img.Height / $TileHeight)

    if (!(Test-Path $OutputDir)) { 
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null 
    }

    Write-Host "Нарезка: $(Split-Path $ImagePath -Leaf) -> ${cols}x${rows} кадров (${TileWidth}x${TileHeight}px)"

    for ($y = 0; $y -lt $rows; $y++) {
        for ($x = 0; $x -lt $cols; $x++) {
            $px = [int]$x * [int]$TileWidth
            $py = [int]$y * [int]$TileHeight
            $rect = New-Object System.Drawing.Rectangle($px, $py, [int]$TileWidth, [int]$TileHeight)
            $bitmap = New-Object System.Drawing.Bitmap([int]$TileWidth, [int]$TileHeight)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            $destRect = New-Object System.Drawing.Rectangle(0, 0, [int]$TileWidth, [int]$TileHeight)
            $graphics.DrawImage($img, $destRect, $rect, [System.Drawing.GraphicsUnit]::Pixel)
            
            $fileName = "${OutputName}_frame_${x}.png"
            $outputPath = "$OutputDir\$fileName"
            $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
            
            $graphics.Dispose()
            $bitmap.Dispose()
        }
    }

    $img.Dispose()
    Write-Host "  Сохранено в: $OutputDir" -ForegroundColor Green
}

Write-Host "=== Нарезка спрайтов Lancer ===" -ForegroundColor Cyan
Write-Host ""

# Lancer_Idle.png (3840x320) - 12 кадров по 320x320
Cut-SpriteSheet -ImagePath "$base\Lancer_Idle.png" -OutputDir "$outputBase\Idle" -TileWidth 320 -TileHeight 320 -OutputName "Lancer_Idle"

# Lancer_Run.png (1920x320) - 6 кадров по 320x320
Cut-SpriteSheet -ImagePath "$base\Lancer_Run.png" -OutputDir "$outputBase\Run" -TileWidth 320 -TileHeight 320 -OutputName "Lancer_Run"

# Lancer_Right_Attack.png (960x320) - 3 кадра по 320x320
Cut-SpriteSheet -ImagePath "$base\Lancer_Right_Attack.png" -OutputDir "$outputBase\Attack" -TileWidth 320 -TileHeight 320 -OutputName "Lancer_Right_Attack"

Write-Host ""
Write-Host "=== Готово! ===" -ForegroundColor Green
Write-Host "Все нарезанные файлы в: $outputBase" -ForegroundColor Yellow
