#!/bin/bash
#
# build_universal.sh
# 不依赖完整 Xcode 的 Universal Binary 构建脚本
# 适用于仅安装了 Command Line Tools 的环境
# 构建产物同时支持 Intel (x86_64) 和 Apple Silicon (arm64) Mac

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=========================================="
echo "OPPO 主题打包解包工具 - Universal 构建脚本"
echo "=========================================="

BUILD_DIR="$SCRIPT_DIR/build_universal"
APP_NAME="OPPO主题打包解包工具"
BUNDLE_ID="com.oppo.oppothemetool"

# 清理旧构建
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 检查必要工具
for tool in swiftc lipo codesign hdiutil zip; do
    if ! command -v "$tool" &> /dev/null; then
        echo "错误: 缺少必要工具: $tool"
        exit 1
    fi
done

# 步骤 1: 准备源码（#Preview 已用 #if swift(>=5.9) 包裹，兼容 Swift 5.8）
echo ""
echo "步骤 1: 准备源码..."
SRC_DIR="$BUILD_DIR/Sources"
mkdir -p "$SRC_DIR"
cp OPPOThemeTool/Sources/*.swift "$SRC_DIR/"

# 步骤 2: 编译 x86_64 可执行文件
echo ""
echo "步骤 2: 编译 x86_64 可执行文件..."
swiftc -parse-as-library -target x86_64-apple-macos12.0 \
    "$SRC_DIR/App.swift" \
    "$SRC_DIR/ContentView.swift" \
    "$SRC_DIR/UnpackView.swift" \
    -o "$BUILD_DIR/${APP_NAME}_x86_64"

# 步骤 3: 编译 arm64 可执行文件
echo ""
echo "步骤 3: 编译 arm64 可执行文件..."
swiftc -parse-as-library -target arm64-apple-macos12.0 \
    "$SRC_DIR/App.swift" \
    "$SRC_DIR/ContentView.swift" \
    "$SRC_DIR/UnpackView.swift" \
    -o "$BUILD_DIR/${APP_NAME}_arm64"

# 步骤 4: 合并为 Universal Binary
echo ""
echo "步骤 4: 合并为 Universal Binary..."
lipo -create \
    "$BUILD_DIR/${APP_NAME}_x86_64" \
    "$BUILD_DIR/${APP_NAME}_arm64" \
    -output "$BUILD_DIR/$APP_NAME"

echo "合并后的二进制架构:"
file "$BUILD_DIR/$APP_NAME"

# 步骤 5: 创建 .app bundle
echo ""
echo "步骤 5: 创建应用 bundle..."
APP_DIR="$BUILD_DIR/${APP_NAME}.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

cp "$BUILD_DIR/$APP_NAME" "$MACOS_DIR/"

# 步骤 6: 生成 Info.plist
echo ""
echo "步骤 6: 生成 Info.plist..."
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh-CN</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>icon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.1.0</string>
    <key>CFBundleVersion</key>
    <string>2</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. All rights reserved.</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 步骤 7: 复制资源文件
echo ""
echo "步骤 7: 复制资源文件..."
cp OPPOThemeTool/Resources/OPPOThemeTool.entitlements "$RESOURCES_DIR/"
if [ -f "icon.png" ]; then
    cp "icon.png" "$RESOURCES_DIR/icon.png"
    echo "图标已复制"
else
    echo "警告: 图标文件不存在"
fi

# 生成 PkgInfo
echo "APPL????" > "$CONTENTS_DIR/PkgInfo"

# 步骤 8: 代码签名
echo ""
echo "步骤 8: 进行 ad-hoc 代码签名..."
codesign --force --deep --sign - "$APP_DIR"

# 步骤 9: 验证签名和架构
echo ""
echo "步骤 9: 验证签名和架构..."
codesign -dvv "$APP_DIR" 2>&1 | head -15
file "$APP_DIR/Contents/MacOS/$APP_NAME"

# 步骤 10: 打包为 zip
echo ""
echo "步骤 10: 打包为 zip..."
ZIP_PATH="$BUILD_DIR/${APP_NAME}-universal.zip"
cd "$BUILD_DIR"
zip -r -y "${APP_NAME}-universal.zip" "${APP_NAME}.app"
cd "$SCRIPT_DIR"

# 步骤 11: 创建 DMG 安装包
echo ""
echo "步骤 11: 创建 DMG 安装包..."
DMG_NAME="${APP_NAME}-universal.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
TEMP_DMG="$BUILD_DIR/temp.dmg"
MOUNT_DIR="$BUILD_DIR/mount"
VOLUME_NAME="OPPO主题打包解包工具"

rm -rf "$MOUNT_DIR"
mkdir -p "$MOUNT_DIR"
cp -R "$APP_DIR" "$MOUNT_DIR/"

hdiutil create -srcfolder "$MOUNT_DIR" -volname "$VOLUME_NAME" -fs HFS+ -format UDZO "$TEMP_DMG" -ov
mv "$TEMP_DMG" "$DMG_PATH"
rm -rf "$MOUNT_DIR"

echo ""
echo "=========================================="
echo "构建完成!"
echo "应用路径: $APP_DIR"
echo "ZIP 压缩包: $ZIP_PATH"
echo "DMG 安装包: $DMG_PATH"
echo "=========================================="
