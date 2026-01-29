# Tenzin Build Script (Windows PowerShell)
# Энэ скрипт нь апп бүтээх команд агуулна

param(
    [string]$BuildType = "debug"
)

Write-Host "🚀 Tenzin Build Script" -ForegroundColor Cyan
Write-Host "=====================" -ForegroundColor Cyan

# Check flutter
$flutterCheck = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutterCheck) {
    Write-Host "Flutter олдсонгүй. Эхлээд Flutter суулгана уу." -ForegroundColor Red
    exit 1
}

Write-Host "Build type: $BuildType" -ForegroundColor Yellow

# Clean
Write-Host "🧹 Цэвэрлэж байна..." -ForegroundColor White
flutter clean

# Get dependencies
Write-Host "📦 Dependencies татаж байна..." -ForegroundColor White
flutter pub get

# Build based on type
switch ($BuildType) {
    "debug" {
        Write-Host "🔧 Debug APK бүтээж байна..." -ForegroundColor White
        flutter build apk --debug
        Write-Host "✅ Debug APK бэлэн: build\app\outputs\flutter-apk\app-debug.apk" -ForegroundColor Green
    }
    "release" {
        Write-Host "📱 Release APK бүтээж байна..." -ForegroundColor White
        flutter build apk --release
        Write-Host "✅ Release APK бэлэн: build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Green
    }
    "bundle" {
        Write-Host "📦 App Bundle бүтээж байна..." -ForegroundColor White
        flutter build appbundle --release
        Write-Host "✅ App Bundle бэлэн: build\app\outputs\bundle\release\app-release.aab" -ForegroundColor Green
    }
    "all" {
        Write-Host "📱 Бүх platform бүтээж байна..." -ForegroundColor White
        flutter build apk --release
        flutter build appbundle --release
        Write-Host "✅ Бүх build бэлэн" -ForegroundColor Green
    }
    "test" {
        Write-Host "🧪 Тест ажиллуулж байна..." -ForegroundColor White
        flutter test
        Write-Host "✅ Тестүүд дууссан" -ForegroundColor Green
    }
    default {
        Write-Host "Үл мэдэгдэх build type: $BuildType" -ForegroundColor Red
        Write-Host "Боломжит утгууд: debug, release, bundle, all, test" -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ""
Write-Host "🎉 Build амжилттай!" -ForegroundColor Green
