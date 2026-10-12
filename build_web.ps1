# Build script for exporting Club Budget: The Game to Web for itch.io
$ErrorActionPreference = "Stop"

$GODOT_BIN = "C:\Program Files\Godot\Godot_v4.7.2-stable_win64_console.exe"
if (-not (Test-Path $GODOT_BIN)) {
    Write-Error "Godot binary not found at $GODOT_BIN"
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Club Budget: The Game for Web" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Run Tests
Write-Host "`n[1/4] Running GDScript Test Suites..." -ForegroundColor Yellow
& $GODOT_BIN --headless -s res://tests/test_runner.gd
if ($LASTEXITCODE -ne 0) {
    Write-Error "Model unit tests failed! Aborting export."
    exit 1
}

& $GODOT_BIN --headless tests/test_ui.tscn
if ($LASTEXITCODE -ne 0) {
    Write-Error "UI flow tests failed! Aborting export."
    exit 1
}
Write-Host "  -> All tests passed successfully!" -ForegroundColor Green

# 2. Prepare build directory
Write-Host "`n[2/4] Preparing output directory 'build/web'..." -ForegroundColor Yellow
if (Test-Path "build\web") {
    Remove-Item -Recurse -Force "build\web\*"
} else {
    New-Item -ItemType Directory -Force -Path "build\web" | Out-Null
}

# 3. Export Web release
Write-Host "`n[3/4] Exporting Web build with Godot..." -ForegroundColor Yellow
& $GODOT_BIN --headless --export-release "Web" build/web/index.html
if ($LASTEXITCODE -ne 0) {
    Write-Error "Godot Web export failed!"
    exit 1
}
Write-Host "  -> Export completed successfully!" -ForegroundColor Green

# 4. Package zip for itch.io
Write-Host "`n[4/4] Packaging 'build/club-budget-the-game-web.zip' for itch.io..." -ForegroundColor Yellow
$zipPath = "build\club-budget-the-game-web.zip"
if (Test-Path $zipPath) {
    Remove-Item -Force $zipPath
}
Compress-Archive -Path "build\web\*" -DestinationPath $zipPath -Force
Write-Host "  -> Created: $zipPath" -ForegroundColor Green

$zipSize = (Get-Item $zipPath).Length / 1MB
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "Archive: $zipPath ($([math]::Round($zipSize, 2)) MB)" -ForegroundColor White
Write-Host "`nitch.io Upload Instructions:" -ForegroundColor Yellow
Write-Host "1. Upload '$zipPath' to your itch.io project dashboard." -ForegroundColor White
Write-Host "2. Check the box: 'This file will be played in the browser'." -ForegroundColor White
Write-Host "3. Embed options: Embed in page" -ForegroundColor White
Write-Host "4. Viewport dimensions: 1280 width x 720 height" -ForegroundColor White
Write-Host "5. Check: 'Fullscreen button'" -ForegroundColor White
Write-Host "6. Uncheck: 'SharedArrayBuffer support' (single-threaded build, no special headers needed!)" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan
