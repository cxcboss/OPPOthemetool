# OPPO 主题打包解包工具

一个功能强大的 macOS 应用，用于解包和打包 OPPO 主题文件（.theme 格式）。

## ✨ 功能特性

- **主题解包**：支持拖入 .theme 文件或主题文件夹，自动解压并整理文件结构
- **主题打包**：支持将文件夹打包成标准的 .theme 格式，方便分享和安装
- **主题支持**：支持传统 ZIP 格式主题和新型 theme-widget 格式主题
- **直观界面**：简洁的拖放界面，操作简单便捷
- **跨平台兼容**：生成的主题文件可在 OPPO 手机上正常使用

## 📋 支持的主题格式

| 格式 | 说明 | 状态 |
|------|------|------|
| 传统 ZIP 主题 | 包含 picture、lockscreen 等文件夹的 ZIP 文件 | ✅ 支持 |
| theme-widget 主题 | 包含 theme-widget 文件夹的新型主题格式 | ✅ 支持 |
| .theme 文件 | OPPO 官方主题文件格式 | ✅ 支持 |

## 🖥️ 系统要求

- macOS 12.0 (Monterey) 或更高版本
- 支持 Intel (x86_64) 和 Apple Silicon (arm64) Mac
- Python 3.x（系统自带）

## 🚀 安装方法

### 方法一：直接使用（推荐）

1. 下载最新版本的 `OPPO主题打包解包工具.app`
2. 将应用拖入「应用程序」文件夹
3. 双击打开应用即可使用
4. 首次打开时如遇安全提示，请在「系统偏好设置 > 安全性与隐私」中点击「仍要打开」

### 方法二：从源码构建（完整 Xcode）

```bash
# 克隆项目
git clone https://github.com/cxcboss/OPPOthemetool.git
cd OPPOthemetool

# 安装 XcodeGen（如果未安装）
brew install xcodegen

# 生成项目并构建（默认输出 Universal Binary，同时支持 x86_64 和 arm64）
./setup.sh

# 构建完成后，app 文件位于 build/Build/Products/Release/
```

### 方法三：从源码构建（仅 Command Line Tools）

如果你没有安装完整版 Xcode，也可以使用系统自带的命令行工具构建 Universal Binary：

```bash
# 克隆项目
git clone https://github.com/cxcboss/OPPOthemetool.git
cd OPPOthemetool

# 运行 Universal 构建脚本
./build_universal.sh

# 构建完成后，app 文件位于 build_universal/
# 同时会生成 .zip 和 .dmg 安装包
```

> **注意**：Release 版本现在统一构建为 Universal Binary，同时兼容 Intel Mac 和 Apple Silicon Mac。

## 📖 使用说明

### 解包主题

1. 打开应用，切换到「解包」标签页
2. 将 .theme 文件或主题文件夹拖入指定区域
3. 点击「开始解压」按钮
4. 解压后的文件将保存在原文件同级目录下

**支持的输入**：
- `.theme` 文件（ZIP 格式的 OPPO 主题）
- 包含主题文件的文件夹
- 包含 `themeInfo.xml` 的目录

### 打包主题

1. 打开应用，切换到「打包」标签页
2. 将需要打包的主题文件夹拖入指定区域
3. 点击「开始打包」按钮
4. 打包后的 `.theme` 文件将保存在原文件夹同级目录下

**打包要求**：
- 文件夹必须包含 `themeInfo.xml` 文件
- 可选包含 `picture`、`lockscreen`、`theme-widget` 等文件夹

## 📁 项目结构

```
OPPOthemetool/
├── OPPOThemeTool/
│   ├── Sources/              # Swift 源码
│   │   ├── App.swift         # 应用入口
│   │   ├── ContentView.swift # 主界面
│   │   └── UnpackView.swift  # 打包/解包视图（含嵌入式 Python 脚本）
│   ├── Resources/            # 资源文件
│   │   ├── Assets.xcassets/  # 应用图标资源
│   │   ├── Info.plist        # 应用配置
│   │   └── OPPOThemeTool.entitlements
│   ├── Python/               # Python 处理脚本
│   │   └── processor.py      # 主题处理核心逻辑
│   └── project.yml           # XcodeGen 项目配置
├── tests/                    # 测试脚本
│   ├── test_processor.py     # Python 核心逻辑测试
│   └── test_build.sh         # Universal Binary 构建验证
├── docs/                     # 文档
│   └── COMPATIBILITY_REPORT.md  # x86/Universal 兼容性测试报告
├── icon.png                  # 应用图标源文件
├── README.md                 # 项目说明文档
├── setup.sh                  # Xcode 构建脚本
└── build_universal.sh        # 命令行工具 Universal 构建脚本
```

## 🛠️ 技术实现

- **前端**：SwiftUI 构建的现代化 macOS 界面
- **后端**：Python 脚本处理主题文件的解包和打包逻辑
- **构建工具**：XcodeGen 管理 Xcode 项目配置
- **嵌入式脚本**：Python 脚本直接嵌入 Swift 代码，无需外部依赖

## 📝 更新日志

### v1.1.0 (2026-01-31)

- ✨ 新增直接拖入 .theme 文件的支持
- 🔧 修复图标打包问题
- 🐛 修复主题-widget 文件夹处理
- 📦 优化临时文件处理逻辑
- 🎨 改进用户界面体验

### v1.0.0 (2026-01-31)

- 🎉 初始版本发布
- ✨ 支持主题解包功能
- ✨ 支持主题打包功能
- ✨ 支持传统 ZIP 格式主题

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request 来帮助改进这个项目。

## 📄 许可证

本项目采用 MIT 许可证开源。

## 👨‍💻 作者

- GitHub：[@cxcboss](https://github.com/cxcboss)

## 🙏 感谢

感谢所有为这个项目提供帮助和建议的人！

## 📞 联系方式

- GitHub Issues：https://github.com/cxcboss/OPPOthemetool/issues
- 项目地址：https://github.com/cxcboss/OPPOthemetool
