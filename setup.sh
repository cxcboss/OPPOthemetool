#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "OPPO Theme Tool - 项目构建脚本"
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

if [ ! -d "build/Release/OPPOThemeTool.app" ]; then
    echo "错误: 构建失败"
    exit 1
fi

echo ""
echo "步骤 3: 复制应用到桌面..."
cp -R "build/Release/OPPOThemeTool.app" "$HOME/Desktop/"

echo ""
echo "=========================================="
echo "构建完成!"
echo "应用已复制到桌面: OPPOThemeTool.app"
echo "=========================================="

open "$HOME/Desktop/OPPOThemeTool.app"
