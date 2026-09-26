import SwiftUI

struct UnpackView: View {
    @State private var selectedPath: String = ""
    @State private var isProcessing = false
    @State private var statusMessage = "拖入主题文件夹到此处\n或点击选择"
    @State private var statusColor: Color = .gray
    @State private var outputPath = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("OPPO主题解包工具")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)

            FolderDropView(
                selectedPath: $selectedPath,
                isProcessing: $isProcessing,
                statusMessage: $statusMessage,
                statusColor: $statusColor,
                placeholder: "拖入主题文件夹到此处\n或点击选择",
                onDropped: { path in
                    processUnpack(path: path)
                }
            )
            .frame(height: 150)
            .padding(.horizontal)

            if !selectedPath.isEmpty {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text(selectedPath.split(separator: "/").last.map(String.init) ?? selectedPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(statusColor)
                    .font(.footnote)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }

            if !outputPath.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("输出目录: \(outputPath)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            Spacer()

            Button(action: {
                if !selectedPath.isEmpty {
                    processUnpack(path: selectedPath)
                }
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isProcessing ? "解压中..." : "开始解压")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background((selectedPath.isEmpty || isProcessing) ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(selectedPath.isEmpty || isProcessing)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    private func processUnpack(path: String) {
        guard !path.isEmpty else { return }

        isProcessing = true
        statusMessage = "正在解压..."
        statusColor = .orange
        outputPath = ""

        DispatchQueue.global(qos: .userInitiated).async {
            let parentPath = (path as NSString).deletingLastPathComponent
            let result = runPythonScript(mode: "unpack", path: path, parentPath: parentPath)

            DispatchQueue.main.async {
                isProcessing = false

                if result.success {
                    statusMessage = result.message ?? "解压完成"
                    statusColor = .green
                    outputPath = result.outputFolder ?? ""
                    selectedPath = ""
                } else {
                    statusMessage = result.error ?? "解压失败"
                    statusColor = .red
                }
            }
        }
    }
}

struct PackView: View {
    @State private var selectedPath: String = ""
    @State private var isProcessing = false
    @State private var statusMessage = "拖入需要打包的文件夹到此处\n或点击选择"
    @State private var statusColor: Color = .gray
    @State private var outputPath = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("OPPO主题打包工具")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 20)

            FolderDropView(
                selectedPath: $selectedPath,
                isProcessing: $isProcessing,
                statusMessage: $statusMessage,
                statusColor: $statusColor,
                placeholder: "拖入需要打包的文件夹到此处\n或点击选择",
                onDropped: { path in
                    processPack(path: path)
                }
            )
            .frame(height: 150)
            .padding(.horizontal)

            if !selectedPath.isEmpty {
                HStack {
                    Image(systemName: "folder.fill")
                        .foregroundColor(.blue)
                    Text(selectedPath.split(separator: "/").last.map(String.init) ?? selectedPath)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            }

            if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundColor(statusColor)
                    .font(.footnote)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }

            if !outputPath.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("输出文件: \(outputPath)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
            }

            Spacer()

            Button(action: {
                if !selectedPath.isEmpty {
                    processPack(path: selectedPath)
                }
            }) {
                HStack {
                    if isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                    Text(isProcessing ? "打包中..." : "开始打包")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background((selectedPath.isEmpty || isProcessing) ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(selectedPath.isEmpty || isProcessing)
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    private func processPack(path: String) {
        guard !path.isEmpty else { return }

        isProcessing = true
        statusMessage = "正在打包..."
        statusColor = .orange
        outputPath = ""

        DispatchQueue.global(qos: .userInitiated).async {
            let result = runPythonScript(mode: "pack", path: path)

            DispatchQueue.main.async {
                isProcessing = false

                if result.success {
                    statusMessage = result.message ?? "打包完成"
                    statusColor = .green
                    outputPath = result.outputFile ?? result.outputFolder ?? ""
                    selectedPath = ""
                } else {
                    statusMessage = result.error ?? "打包失败"
                    statusColor = .red
                }
            }
        }
    }
}

struct FolderDropView: NSViewRepresentable {
    @Binding var selectedPath: String
    @Binding var isProcessing: Bool
    @Binding var statusMessage: String
    @Binding var statusColor: Color
    let placeholder: String
    let onDropped: (String) -> Void

    func makeNSView(context: NSViewRepresentableContext<FolderDropView>) -> NSView {
        let view = DroppableView()
        view.placeholderText = placeholder
        view.onDrop = { path in
            guard !isProcessing else { return }
            selectedPath = path
            updateStatus(for: path)
            onDropped(path)
        }
        view.onClick = {
            guard !isProcessing else { return }
            openPanel()
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<FolderDropView>) {
    }

    private func updateStatus(for path: String) {
        statusMessage = "已选择: \((path as NSString).lastPathComponent)"
        statusColor = .green
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            selectedPath = url.path
            updateStatus(for: url.path)
            onDropped(url.path)
        }
    }
}

class DroppableView: NSView {
    var onDrop: ((String) -> Void)?
    var onClick: (() -> Void)?
    var placeholderText: String = "拖入文件夹到此处\n或点击选择"

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        registerForDraggedTypes([.fileURL])
        self.layer?.cornerRadius = 12
        self.layer?.borderWidth = 2
        self.layer?.borderColor = NSColor.gray.cgColor
        self.layer?.backgroundColor = .clear
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 16),
            .foregroundColor: NSColor.gray,
            .paragraphStyle: paragraphStyle
        ]

        let attributedString = NSAttributedString(string: placeholderText, attributes: attributes)
        let textSize = attributedString.size()
        let textRect = NSRect(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributedString.draw(in: textRect)
    }

    override func mouseDown(with event: NSEvent) {
        onClick?()
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.layer?.borderColor = NSColor.systemBlue.cgColor
        self.layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.1).cgColor
        return .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.layer?.borderColor = NSColor.gray.cgColor
        self.layer?.backgroundColor = .clear
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        self.layer?.borderColor = NSColor.gray.cgColor
        self.layer?.backgroundColor = .clear

        guard let pasteboard = sender.draggingPasteboard.propertyList(forType: .fileURL) as? String,
              let url = URL(string: pasteboard) else {
            return false
        }

        let path = url.path
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: path) {
            if fileManager.isDirectory(path: path) {
                onDrop?(path)
                return true
            } else if path.hasSuffix(".theme") {
                onDrop?(path)
                return true
            }
        }

        return false
    }
}

extension FileManager {
    func isDirectory(path: String) -> Bool {
        var isDirectory: ObjCBool = false
        fileExists(atPath: path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
}

struct PythonResult {
    var success: Bool
    var message: String?
    var error: String?
    var outputFolder: String?
    var outputFile: String?
}

func getPythonScriptPath() -> String? {
    // 打包后的应用从 Resources 中读取 processor.py，与仓库中保持唯一一份逻辑
    if let bundlePath = Bundle.main.path(forResource: "processor", ofType: "py"),
       FileManager.default.fileExists(atPath: bundlePath) {
        return bundlePath
    }
    return nil
}

func runPythonScript(mode: String, path: String, parentPath: String? = nil) -> PythonResult {
    var result = PythonResult(success: false, message: nil, error: nil, outputFolder: nil, outputFile: nil)

    let pythonPath = "/usr/bin/python3"

    guard let scriptPath = getPythonScriptPath() else {
        result.error = "应用资源中缺少 processor.py，请重新构建应用"
        return result
    }

    guard FileManager.default.isExecutableFile(atPath: pythonPath) else {
        result.error = "未找到系统 Python3。请在终端执行 xcode-select --install 安装 Command Line Tools 后重试"
        return result
    }

    var args = [scriptPath, mode, path]
    if let parent = parentPath {
        args.append(parent)
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: pythonPath)
    process.arguments = args

    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    let errorPipe = Pipe()
    process.standardError = errorPipe

    do {
        try process.run()

        // 先读完管道再等待进程退出，避免子进程输出超过管道缓冲时互相等待
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        var jsonParsed = false

        if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
            if let jsonData = output.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                jsonParsed = true
                result.success = json["success"] as? Bool ?? false
                result.message = json["message"] as? String
                result.error = json["error"] as? String
                result.outputFolder = json["output_folder"] as? String
                result.outputFile = json["output_file"] as? String
            }
        }

        if let errorOutput = String(data: errorData, encoding: .utf8), !errorOutput.isEmpty {
            if result.error == nil {
                result.error = errorOutput.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        if process.terminationStatus != 0 {
            result.success = false
            if result.error == nil {
                result.error = "脚本执行失败，退出码: \(process.terminationStatus)"
            }
        }

        if !jsonParsed && result.success {
            result.success = false
        }

        // macOS 12.3 起系统不再内置 python3，/usr/bin/python3 是触发安装引导的垫片
        if !result.success, let err = result.error,
           err.contains("developer tools") || err.contains("Command Line Tools") || err.contains("license") {
            result.error = "未安装 Xcode Command Line Tools，无法运行 Python。请在终端执行 xcode-select --install 后重试\n\n原始错误: \(err)"
        }

    } catch {
        result.error = "启动Python失败: \(error.localizedDescription)"
    }

    return result
}

#Preview {
    UnpackView()
}
