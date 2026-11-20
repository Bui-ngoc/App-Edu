# run_app.ps1 - Automatic Pre-launch script for flutter analyze & flutter test

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host " [1/3] Running flutter analyze..." -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
flutter analyze

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] flutter analyze failed. App launch cancelled." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Green
Write-Host " [2/3] Running flutter test..." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
flutter test

if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] flutter test failed. App launch cancelled." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Yellow
Write-Host " [3/3] All checks PASSED! Launching EduMaster App..." -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Yellow
flutter run
