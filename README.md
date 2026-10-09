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
- Python 3（随 Xcode Command Line Tools 提供；macOS 12.3 起系统不再内置 Python，未安装 CLT 时请先在终端执行 `xcode-select --install`）

从源码构建可选择以下方式（均输出 x86_64 + arm64 双架构）：

- Xcode 15.0 或更高版本 + XcodeGen（`brew install xcodegen`），运行 `./setup.sh`
- 仅安装 Command Line Tools，运行 `./build_universal.sh`

## 🚀 安装方法

### 方法一：直接使用（推荐）

1. 下载最新版本的 `OPPO主题打包解包工具.app`（仓库根目录已提供最新构建产物）
2. 将应用拖入「应用程序」文件夹
3. 双击打开应用即可使用
4. 首次打开时如遇安全提示，请在「系统偏好设置 > 安全性与隐私」中点击「仍要打开」

> 应用为 ad-hoc 签名，首次打开需要手动允许。

### 方法二：从源码构建

```bash
# 克隆项目
git clone https://github.com/cxcboss/OPPOthemetool.git
cd OPPOthemetool

# 安装 XcodeGen（如果未安装）
brew install xcodegen

# 生成项目并构建
./setup.sh

# 构建完成后，app 文件位于 build/OPPO主题打包解包工具.app
```

仅安装 Command Line Tools 时：

```bash
./build_universal.sh
# 产物位于 build_universal/，包含双架构 .app、ZIP 和 DMG
```

源码构建支持 Intel Mac 与 Apple Silicon Mac；仓库已有二进制请单独确认架构。

setup.sh 会依次完成：XcodeGen 生成工程 → xcodebuild Release 构建 → 复制应用图标 → ad-hoc 重新签名。

## 🧪 运行测试

```bash
python3 tests/test_processor.py
bash tests/test_build.sh  # 完整构建并验证双架构、签名、资源与版本号
```

测试覆盖 ZIP 识别、themeInfo.xml 解析、打包输出与打包→解包回环。

## 📖 使用说明

### 解包主题

1. 打开应用，切换到「解包」标签页
2. 将 .theme 文件或主题文件夹拖入指定区域（或点击选择）
3. 点击「开始解压」按钮
4. 解压后的文件将保存在原文件同级目录下

**支持的输入**：
- `.theme` 文件（ZIP 格式的 OPPO 主题）
- 包含主题 ZIP 资源的文件夹（根目录及 `lockscreen/` 下的 zip 会自动解压）
- 包含 `themeInfo.xml` 的目录

### 打包主题

1. 打开应用，切换到「打包」标签页
2. 将需要打包的主题文件夹拖入指定区域（或点击选择）
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
│   │   └── UnpackView.swift  # 打包/解包视图与 Python 调用层
│   ├── Resources/            # 资源文件
│   │   ├── Assets.xcassets/  # 应用图标资源
│   │   ├── Info.plist        # 应用配置
│   │   └── OPPOThemeTool.entitlements
│   └── Python/
│       └── processor.py      # 主题处理核心逻辑（唯一脚本源，构建时打包进 App Resources）
├── tests/
│   ├── test_processor.py     # Python 核心逻辑单元测试
│   └── test_build.sh         # 双架构构建验证
├── OPPOThemeTool.app/        # 最新构建产物（随仓库分发）
├── icon.png                  # 应用图标源文件
├── project.yml               # XcodeGen 项目配置
├── setup.sh                  # Xcode 构建脚本
├── build_universal.sh        # Command Line Tools 双架构构建脚本
└── README.md
```

> `OPPOThemeTool.xcodeproj` 由 XcodeGen 生成，不入库；克隆后运行 `./setup.sh` 即可重新生成。

## 🛠️ 技术实现

- **前端**：SwiftUI 构建的 macOS 界面，AppKit 处理拖放
- **后端**：`OPPOThemeTool/Python/processor.py` 处理主题的解包和打包逻辑，构建时随资源打包进 App，运行时由 App 通过系统 Python3 调用
- **构建工具**：XcodeGen 管理 Xcode 项目配置
- **签名**：ad-hoc 签名（复制图标后重新签名，保证签名封条有效）

## 📝 更新日志

### v1.1.1 (2026-09-26)

- 🐛 修复界面字符串转义错误导致的插值失效（输出路径、已选择文件夹名、错误信息显示为字面量）
- 🐛 修复打包成功后不显示输出文件路径的问题（`output_file` 键未解析）
- 🐛 修复 setup.sh 图标路径错误，并补充复制图标后的重新签名步骤
- 🔧 Python 脚本改为从 App Resources 加载，消除与仓库内 processor.py 的双份维护
- 🔧 增加系统 Python3 可用性检查与安装指引提示
- 🧹 移除误提交的构建中间产物与生成文件，新增单元测试

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

## 📞 联系方式

- GitHub Issues：https://github.com/cxcboss/OPPOthemetool/issues
- 项目地址：https://github.com/cxcboss/OPPOthemetool
