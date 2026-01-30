#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "OPPO 主题打包解包工具 - 构建脚本"
echo "=========================================="

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
xcodebuild -project OPPOThemeTool.xcodeproj \
    -scheme OPPOThemeTool \
    -configuration Release \
    -destination "platform=macOS" \
    build

APP_PATH="build/Release/OPPO主题打包解包工具.app"
if [ ! -d "$APP_PATH" ]; then
    echo "错误: 构建失败，未找到应用"
    exit 1
fi

echo ""
echo "步骤 3: 复制 Resources 文件夹到应用..."
if [ -d "OPPOThemeTool/Resources" ]; then
    cp -R "OPPOThemeTool/Resources" "$APP_PATH/Contents/"
    echo "Resources 文件夹已复制"
fi

echo ""
echo "步骤 4: 复制应用到桌面..."
cp -R "$APP_PATH" "$HOME/Desktop/"

echo ""
echo "=========================================="
echo "构建完成!"
echo "应用已复制到桌面: $HOME/Desktop/OPPO主题打包解包工具.app"
echo "=========================================="

# 询问是否打开应用
read -p "是否打开应用? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "$HOME/Desktop/OPPO主题打包解包工具.app"
fi
