#!/bin/bash

# Tenzin Build Script
# Энэ скрипт нь апп бүтээх команд агуулна

echo "🚀 Tenzin Build Script"
echo "====================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter олдсонгүй. Эхлээд Flutter суулгана уу.${NC}"
    exit 1
fi

# Get build type from argument
BUILD_TYPE=${1:-"debug"}

echo -e "${YELLOW}Build type: $BUILD_TYPE${NC}"

# Clean
echo "🧹 Цэвэрлэж байна..."
flutter clean

# Get dependencies
echo "📦 Dependencies татаж байна..."
flutter pub get

# Run code generation (if needed)
# echo "⚙️ Code generation..."
# flutter pub run build_runner build --delete-conflicting-outputs

# Build based on type
case $BUILD_TYPE in
    "debug")
        echo "🔧 Debug APK бүтээж байна..."
        flutter build apk --debug
        echo -e "${GREEN}✅ Debug APK бэлэн: build/app/outputs/flutter-apk/app-debug.apk${NC}"
        ;;
    "release")
        echo "📱 Release APK бүтээж байна..."
        flutter build apk --release
        echo -e "${GREEN}✅ Release APK бэлэн: build/app/outputs/flutter-apk/app-release.apk${NC}"
        ;;
    "bundle")
        echo "📦 App Bundle бүтээж байна..."
        flutter build appbundle --release
        echo -e "${GREEN}✅ App Bundle бэлэн: build/app/outputs/bundle/release/app-release.aab${NC}"
        ;;
    "ios")
        echo "🍎 iOS бүтээж байна..."
        flutter build ios --release
        echo -e "${GREEN}✅ iOS build бэлэн${NC}"
        ;;
    "ipa")
        echo "🍎 IPA бүтээж байна..."
        flutter build ipa
        echo -e "${GREEN}✅ IPA бэлэн: build/ios/ipa/${NC}"
        ;;
    "all")
        echo "📱 Бүх platform бүтээж байна..."
        flutter build apk --release
        flutter build appbundle --release
        flutter build ios --release
        echo -e "${GREEN}✅ Бүх build бэлэн${NC}"
        ;;
    "test")
        echo "🧪 Тест ажиллуулж байна..."
        flutter test
        echo -e "${GREEN}✅ Тестүүд дууссан${NC}"
        ;;
    *)
        echo -e "${RED}Үл мэдэгдэх build type: $BUILD_TYPE${NC}"
        echo "Боломжит утгууд: debug, release, bundle, ios, ipa, all, test"
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}🎉 Build амжилттай!${NC}"
