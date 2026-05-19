# Script to fix corrupted NDK issue
# Run this script in PowerShell as Administrator if needed

$ndkPath = "C:\Users\tanse\AppData\Local\Android\sdk\ndk\28.2.13676358"

Write-Host "Checking NDK path: $ndkPath" -ForegroundColor Yellow

if (Test-Path $ndkPath) {
    Write-Host "Found corrupted NDK folder. Deleting..." -ForegroundColor Yellow
    Remove-Item -Path $ndkPath -Recurse -Force
    Write-Host "NDK folder deleted successfully!" -ForegroundColor Green
    Write-Host "The Android Gradle Plugin will automatically re-download it on next build." -ForegroundColor Green
} else {
    Write-Host "NDK folder not found. It may have already been deleted." -ForegroundColor Cyan
}

Write-Host "`nYou can now run: flutter build apk --debug" -ForegroundColor Green

