# 与原作者沟通的技术说明：x86 兼容特性

## 1. 这个特性解决了什么问题？

我们注意到当前 GitHub Release 中的 `OPPO主题打包解包工具.app` 仅包含 `arm64` 架构。这意味着：

- **Intel Mac 用户无法打开应用**，会直接报错 `bad CPU type in executable`。
- 在 macOS 用户群体中，仍有大量 Intel Mac 用户（尤其是 macOS 12/13/14 的可升级设备）。
- 用户从 Release 下载后无法使用，容易产生项目"不可用"的误解。

本特性通过构建 **Universal Binary**（同时包含 `x86_64` 和 `arm64`），让同一个 `.app` 在两类 Mac 上都能正常运行。

## 2. 实现方式

### 2.1 Xcode 构建流程（推荐）

在 `project.yml` 和 `setup.sh` 中明确指定构建架构：

```yaml
# project.yml
settings:
  base:
    ARCHS: "x86_64 arm64"
    ONLY_ACTIVE_ARCH: NO
```

```bash
# setup.sh
xcodebuild ... ARCHS="x86_64 arm64" ONLY_ACTIVE_ARCH=NO build
```

这样使用原有 Xcode + xcodegen 流程时，默认就会输出 Universal Binary。

### 2.2 命令行工具构建流程（备选）

新增 `build_universal.sh`，适用于未安装完整 Xcode 的环境：

1. 分别用 `swiftc -target x86_64-apple-macos12.0` 和 `swiftc -target arm64-apple-macos12.0` 编译两个可执行文件。
2. 使用 `lipo -create` 合并为 Universal Binary。
3. 手动创建 `.app` bundle，写入 `Info.plist`、复制图标和 entitlements。
4. 使用 `codesign --sign -` 进行 ad-hoc 签名。
5. 生成 `.zip` 和 `.dmg` 分发包。

### 2.3 Swift 版本兼容性

源码中使用了 Swift 5.9 的 `#Preview` 宏。为了兼容 Swift 5.8 的命令行工具链，已用条件编译包裹：

```swift
#if swift(>=5.9)
#Preview {
    ContentView()
}
#endif
```

这不会影响 Xcode 15 用户的预览功能，同时让低版本工具链也能成功编译。

### 2.4 其他修复

- 修复 `setup.sh` 中的图标路径：`../icon.png` 在脚本执行目录下并不正确，已改为 `$SCRIPT_DIR/icon.png`。

## 3. 对现有功能的影响

| 方面 | 影响 |
|------|------|
| 打包/解包核心逻辑 | **无修改**，功能完全一致 |
| 界面代码 | 仅 `#Preview` 添加条件编译，无行为变化 |
| Xcode 构建流程 | 仍然可用，默认输出 Universal Binary |
| 系统要求 | 仍为 macOS 12.0+ |
| 应用体积 | Universal Binary 比单一 arm64 包略大（约 2 倍可执行文件大小），但在可接受范围内 |
| 代码签名 | 仍为 ad-hoc 签名，用户首次打开仍需手动允许 |

## 4. 为什么建议合并？

1. **扩大用户覆盖范围**：同时支持 Intel 和 Apple Silicon Mac，避免用户因架构问题放弃使用。
2. **提升项目专业度**：Release 包直接可用，减少 Issue 中"无法打开"的反馈。
3. **构建流程更灵活**：提供 Xcode 和 Command Line Tools 两种构建方式，降低贡献者门槛。
4. **测试覆盖增加**：新增 Python 单元测试和构建验证脚本，便于后续回归测试。

## 5. 建议的后续操作

1. 合并 PR 后，使用 `setup.sh` 或 `build_universal.sh` 重新构建 Release。
2. 将新的 Release 包命名为 `OPPO主题打包解包工具-universal.dmg` / `.zip`。
3. 在 Release Notes 中注明：
   - 新增 Intel Mac (x86_64) 支持
   - 单个安装包同时兼容 Intel 和 Apple Silicon
4. 如果未来不再需要单独维护 arm64-only 包，可以只发布 Universal Binary。

## 6. 联系我们

如果对本 PR 有任何疑问或需要调整，欢迎随时在 PR 中评论或提出修改建议。
