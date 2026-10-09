#!/bin/bash
# tests/test_build.sh
# 验证 Universal Binary 构建产物

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_DIR"

echo "=========================================="
echo "兼容性构建验证"
echo "=========================================="

# 使用不依赖 Xcode 的脚本构建 Universal Binary
./build_universal.sh

BUILD_DIR="${OPPO_BUILD_DIR:-$PROJECT_DIR/build_universal}"
APP_DIR="$BUILD_DIR/OPPO主题打包解包工具.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/OPPO主题打包解包工具"

echo ""
echo "验证二进制架构..."
file "$EXECUTABLE" | grep -E "x86_64|arm64|universal"

if file "$EXECUTABLE" | grep -q "universal binary"; then
    echo "✅ 是 Universal Binary"
else
    echo "❌ 不是 Universal Binary"
    exit 1
fi

if file "$EXECUTABLE" | grep -q "x86_64"; then
    echo "✅ 包含 x86_64 架构"
else
    echo "❌ 缺少 x86_64 架构"
    exit 1
fi

if file "$EXECUTABLE" | grep -q "arm64"; then
    echo "✅ 包含 arm64 架构"
else
    echo "❌ 缺少 arm64 架构"
    exit 1
fi

echo ""
echo "验证代码签名..."
codesign --verify --deep --strict "$APP_DIR"
echo "✅ 代码签名有效"

echo ""
echo "验证应用 bundle 结构..."
for item in "Info.plist" "PkgInfo" "Resources/icon.png" "Resources/OPPOThemeTool.entitlements" "Resources/processor.py"; do
    if [ -e "$APP_DIR/Contents/$item" ]; then
        echo "✅ $item 存在"
    else
        echo "❌ $item 缺失"
        exit 1
    fi
done

echo ""
echo "验证版本号..."
SOURCE_PLIST="$PROJECT_DIR/OPPOThemeTool/Resources/Info.plist"
for key in CFBundleShortVersionString CFBundleVersion; do
    expected=$(/usr/libexec/PlistBuddy -c "Print :$key" "$SOURCE_PLIST")
    actual=$(/usr/libexec/PlistBuddy -c "Print :$key" "$APP_DIR/Contents/Info.plist")
    [ "$expected" = "$actual" ] || { echo "❌ $key 不匹配"; exit 1; }
done
echo "✅ 版本号与源码一致"
cmp "$PROJECT_DIR/OPPOThemeTool/Python/processor.py" "$APP_DIR/Contents/Resources/processor.py"

echo "验证 ZIP 和 DMG 安装包..."
if [ -f "$BUILD_DIR/OPPO主题打包解包工具-universal.zip" ]; then
    echo "✅ ZIP 安装包已生成"
else
    echo "❌ ZIP 安装包未生成"
    exit 1
fi

if [ -f "$BUILD_DIR/OPPO主题打包解包工具-universal.dmg" ]; then
    echo "✅ DMG 安装包已生成"
else
    echo "❌ DMG 安装包未生成"
    exit 1
fi

echo ""
echo "=========================================="
echo "所有验证通过"
echo "=========================================="
