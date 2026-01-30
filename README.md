# OPPO 主题打包解包工具

一个功能强大的 macOS 应用，用于解包和打包 OPPO 主题文件（.theme 格式）。

## 功能特性

- **主题解包**：支持拖入 .theme 文件或包含主题文件的文件夹，自动解压并整理文件结构
- **主题打包**：支持将文件夹打包成标准的 .theme 格式，方便分享和安装
- **直观界面**：简洁的拖放界面，操作简单便捷
- **跨平台兼容**：生成的主题文件可在 OPPO 手机上正常使用

## 系统要求

- macOS 12.0 或更高版本
- Xcode 15.0 或更高版本
- Homebrew（用于安装 XcodeGen）

## 安装方法

### 方法一：直接使用（推荐）

1. 下载最新版本的 `OPPO主题打包解包工具.app`
2. 将应用拖入「应用程序」文件夹
3. 双击打开应用即可使用

### 方法二：从源码构建

```bash
# 克隆项目
git clone https://github.com/cxcboss/OPPOthemetool.git
cd OPPOthemetool/OPPOThemeTool

# 安装 XcodeGen（如果未安装）
brew install xcodegen

# 生成项目并构建
./setup.sh
```

## 使用说明

### 解包主题

1. 打开应用，切换到「解包」标签页
2. 将 .theme 文件或主题文件夹拖入指定区域
3. 点击「开始解压」按钮
4. 解压后的文件将保存在原文件同级目录下

### 打包主题

1. 打开应用，切换到「打包」标签页
2. 将需要打包的主题文件夹拖入指定区域
3. 点击「开始打包」按钮
4. 打包后的 .theme 文件将保存在原文件夹同级目录下

## 项目结构

```
OPPOthemetool/
├── OPPOThemeTool/
│   ├── Sources/              # Swift 源码
│   │   ├── App.swift
│   │   ├── ContentView.swift
│   │   └── UnpackView.swift
│   ├── Resources/            # 资源文件
│   │   ├── Assets.xcassets/  # 应用图标
│   │   ├── Info.plist
│   │   └── OPPOThemeTool.entitlements
│   ├── Python/               # Python 处理脚本
│   │   └── processor.py
│   └── project.yml           # XcodeGen 配置
├── icon.png                  # 应用图标源文件
├── OPPO打包.py               # 原始打包脚本
├── 解包.py                   # 原始解包脚本
└── setup.sh                  # 构建脚本
```

## 技术实现

- **前端**：SwiftUI 构建的现代化 macOS 界面
- **后端**：Python 脚本处理主题文件的解包和打包逻辑
- **构建工具**：XcodeGen 管理 Xcode 项目配置

## 许可证

本项目采用 MIT 许可证开源。

## 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

## 联系方式

- GitHub：https://github.com/cxcboss/OPPOthemetool

## 感谢

感谢所有为这个项目提供帮助和建议的人！
