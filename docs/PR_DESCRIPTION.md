# PR 描述：增加 x86_64 / Universal Binary 支持

## 标题

feat: 支持 Intel Mac (x86_64) 并构建 Universal Binary

## 摘要

当前 Release 版本的应用仅包含 `arm64` 架构，导致 Intel Mac 用户在打开应用时遇到 `bad CPU type in executable` 错误。本 PR 通过以下改进，使应用同时支持 Intel (x86_64) 和 Apple Silicon (arm64) Mac：

1. 在 `project.yml` 和 `setup.sh` 中启用 `ARCHS="x86_64 arm64"`，让 Xcode 构建流程默认输出 Universal Binary。
2. 新增 `build_universal.sh` 脚本，允许仅安装 Command Line Tools 的环境构建 Universal Binary（无需完整 Xcode）。
3. 用 `#if swift(>=5.9)` 包裹 `#Preview` 宏，兼容 Swift 5.8 命令行工具链。
4. 修复 `setup.sh` 中图标路径错误（`../icon.png` → `$SCRIPT_DIR/icon.png`）。
5. 新增测试脚本和兼容性测试报告。

## 改动清单

- `project.yml`: 添加 `ARCHS: "x86_64 arm64"` 和 `ONLY_ACTIVE_ARCH: NO`
- `setup.sh`: 传递 `ARCHS` 参数，修正图标路径
- `OPPOThemeTool/Sources/ContentView.swift`: `#Preview` 添加版本条件编译
- `OPPOThemeTool/Sources/UnpackView.swift`: `#Preview` 添加版本条件编译
- `build_universal.sh`: 新增，不依赖 Xcode 的 Universal 构建脚本
- `tests/test_processor.py`: 新增，Python 核心逻辑单元测试
- `tests/test_build.sh`: 新增，Universal Binary 构建验证
- `docs/COMPATIBILITY_REPORT.md`: 新增，兼容性测试报告
- `README.md`: 更新系统要求、安装方法和项目结构
- `.gitignore`: 忽略构建产物和 Python 缓存

## 测试情况

- [x] `python3 tests/test_processor.py` 全部通过
- [x] `tests/test_build.sh` 构建验证通过
- [x] 构建产物为 Universal Binary（同时包含 x86_64 和 arm64）
- [x] 代码签名验证通过
- [x] ZIP 和 DMG 安装包生成成功

## 影响评估

- **对现有功能的影响**：打包/解包核心逻辑未做任何修改，功能保持不变。
- **对构建流程的影响**：
  - 原有 Xcode + xcodegen 构建流程仍然可用，且默认输出 Universal Binary。
  - 新增 `build_universal.sh` 作为备选构建方案，不破坏原有流程。
- **对发布包的影响**：建议后续 Release 使用 Universal Binary，替换现有的 arm64-only 包。
- **对系统要求的影响**：最低系统要求仍为 macOS 12.0，无需额外依赖。

## 复现原问题

在 Intel Mac 上运行当前 Release 的 `OPPO主题打包解包工具.app`：

```bash
$ ./OPPOThemeTool.app/Contents/MacOS/OPPO主题打包解包工具
zsh: bad CPU type in executable: ./OPPOThemeTool.app/Contents/MacOS/OPPO主题打包解包工具
```

使用本 PR 构建后：

```bash
$ file build_universal/OPPO主题打包解包工具.app/Contents/MacOS/OPPO主题打包解包工具
Mach-O universal binary with 2 architectures: [x86_64:...] [arm64:...]
```

## 建议发布策略

1. 合并本 PR 后，使用 `setup.sh` 或 `build_universal.sh` 重新构建 Release。
2. 将新的 Release 包命名为 `OPPO主题打包解包工具-universal.dmg` / `.zip`。
3. 在 Release Notes 中说明已支持 Intel Mac。
