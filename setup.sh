#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "OPPO 主题打包解包工具 - 构建脚本"
echo "=========================================="

BUILD_DIR="$SCRIPT_DIR/build"

# 检查 XcodeGen 是否安装
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen 未安装，正在安装..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "错误: Homebrew 未安装，请先安装 Homebrew"
        echo "访问 https://brew.sh 获取安装说明"
        exit 1
    fi
fi

echo ""
echo "步骤 1: 生成 Xcode 项目..."
xcodegen generate

if [ ! -f "OPPOThemeTool.xcodeproj/project.pbxproj" ]; then
    echo "错误: Xcode 项目生成失败"
    exit 1
fi

echo ""
echo "步骤 2: 构建项目..."
rm -rf "$BUILD_DIR"
xcodebuild -project OPPOThemeTool.xcodeproj \
    -scheme OPPOThemeTool \
    -configuration Release \
    -destination "platform=macOS" \
    -derivedDataPath "$BUILD_DIR" \
    ARCHS="x86_64 arm64" \
    ONLY_ACTIVE_ARCH=NO \
    build

APP_PATH="$BUILD_DIR/Build/Products/Release/OPPO主题打包解包工具.app"
if [ ! -d "$APP_PATH" ]; then
    echo "错误: 构建失败，未找到应用"
    exit 1
fi

echo ""
echo "步骤 3: 复制图标文件到应用..."
ICON_PATH="$SCRIPT_DIR/icon.png"
if [ -f "$ICON_PATH" ]; then
    cp "$ICON_PATH" "$APP_PATH/Contents/Resources/icon.png"
    echo "图标文件已复制"
else
    echo "警告: 图标文件不存在: $ICON_PATH"
fi

echo ""
echo "步骤 4: 复制应用到临时目录..."
TEMP_APP="$BUILD_DIR/OPPO主题打包解包工具.app"
rm -rf "$TEMP_APP"
cp -R "$APP_PATH" "$TEMP_APP"
echo "应用已复制到: $TEMP_APP"

echo ""
echo "=========================================="
echo "构建完成!"
echo "请手动复制应用到桌面:"
echo "cp -R \"$TEMP_APP\" \"\$HOME/Desktop/\""
echo "=========================================="
