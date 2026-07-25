import SwiftUI

let pythonScript = """
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import os
import re
import shutil
import zipfile
import tempfile
import json

def get_output_folder_name(source_folder):
    theme_info_path = os.path.join(source_folder, 'themeInfo.xml')
    if not os.path.exists(theme_info_path):
        return None
    
    try:
        with open(theme_info_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        editor_version = re.search(r'<EditorVersion>(\\d+)</EditorVersion>', content)
        summary = re.search(r'<Summary>(.*?)</Summary>', content)
        
        if editor_version and summary:
            editor = editor_version.group(1)[:-3]
            summary_text = summary.group(1).strip().replace(' ', '')
            return "{}{}".format(editor, summary_text)
        return None
    except Exception as e:
        print("读取themeInfo.xml失败: {}".format(e), file=sys.stderr)
        return None

def is_zip_file(file_path):
    try:
        with open(file_path, 'rb') as f:
            header = f.read(4)
            return header[:4] == b"PK\\x03\\x04" or header[:4] == b"PK\\x05\\x06"
    except:
        return False

def get_zip_files(source_folder):
    zip_files = []
    for item in os.listdir(source_folder):
        item_path = os.path.join(source_folder, item)
        if item.lower() == 'lockscreen' and os.path.isdir(item_path):
            for sub_item in os.listdir(item_path):
                sub_path = os.path.join(item_path, sub_item)
                if os.path.isfile(sub_path) and is_zip_file(sub_path):
                    zip_files.append(('lockscreen', sub_path))
        elif os.path.isfile(item_path) and is_zip_file(item_path):
            zip_files.append(('root', item_path))
    return zip_files

def unpack_theme(theme_path, parent_folder):
    source_folder = theme_path
    
    if not os.path.exists(source_folder):
        return {"success": False, "error": "资源路径不存在"}
    
    temp_dir = None
    
    if os.path.isfile(source_folder):
        if source_folder.endswith('.theme'):
            if not is_zip_file(source_folder):
                return {"success": False, "error": "不是有效的theme文件"}
            
            try:
                temp_dir = tempfile.mkdtemp()
                with zipfile.ZipFile(source_folder, 'r') as zip_ref:
                    zip_ref.extractall(temp_dir)
                source_folder = temp_dir
            except Exception as e:
                if temp_dir:
                    shutil.rmtree(temp_dir, ignore_errors=True)
                return {"success": False, "error": "解压theme文件失败: {}".format(e)}
    
    if not os.path.isdir(source_folder):
        if temp_dir:
            shutil.rmtree(temp_dir, ignore_errors=True)
        return {"success": False, "error": "资源路径不是有效的文件夹"}
    
    dest_folder = parent_folder
    
    zip_files = get_zip_files(source_folder)
    has_theme_widget = os.path.exists(os.path.join(source_folder, 'theme-widget')) and os.path.isdir(os.path.join(source_folder, 'theme-widget'))
    
    if not zip_files and not has_theme_widget:
        return {"success": False, "error": "未找到需要解压的zip文件"}
    
    folder_name = get_output_folder_name(source_folder)
    if folder_name:
        dest_folder = os.path.join(dest_folder, folder_name)
    
    os.makedirs(dest_folder, exist_ok=True)
    
    picture_src = os.path.join(source_folder, 'picture')
    picture_dest = os.path.join(dest_folder, 'picture')
    if os.path.exists(picture_src) and os.path.isdir(picture_src):
        if os.path.exists(picture_dest):
            shutil.rmtree(picture_dest)
        shutil.copytree(picture_src, picture_dest)
    
    theme_info_src = os.path.join(source_folder, 'themeInfo.xml')
    theme_info_dest = os.path.join(dest_folder, 'themeInfo.xml')
    if os.path.exists(theme_info_src):
        shutil.copy2(theme_info_src, theme_info_dest)
    
    theme_widget_src = os.path.join(source_folder, 'theme-widget')
    theme_widget_dest = os.path.join(dest_folder, 'theme-widget')
    if os.path.exists(theme_widget_src) and os.path.isdir(theme_widget_src):
        if os.path.exists(theme_widget_dest):
            shutil.rmtree(theme_widget_dest)
        shutil.copytree(theme_widget_src, theme_widget_dest)
    
    lockscreen_dest = os.path.join(dest_folder, 'lockscreen')
    os.makedirs(lockscreen_dest, exist_ok=True)
    
    for location, zip_file in zip_files:
        file_name = os.path.basename(zip_file)
        if file_name.endswith('.zip'):
            base_name = file_name[:-4]
        else:
            base_name = file_name
        
        if location == 'lockscreen':
            extract_path = lockscreen_dest
        else:
            extract_path = os.path.join(dest_folder, base_name)
        
        try:
            if location == 'lockscreen':
                with zipfile.ZipFile(zip_file, 'r') as zip_ref:
                    for member in zip_ref.namelist():
                        target_path = os.path.join(extract_path, member)
                        if os.path.exists(target_path):
                            if os.path.isdir(target_path):
                                shutil.rmtree(target_path)
                            else:
                                os.remove(target_path)
                    zip_ref.extractall(extract_path)
            else:
                if os.path.exists(extract_path):
                    shutil.rmtree(extract_path)
                os.makedirs(extract_path, exist_ok=True)
                with zipfile.ZipFile(zip_file, 'r') as zip_ref:
                    zip_ref.extractall(extract_path)
        except Exception as e:
            print("解压 {} 失败: {}".format(file_name, e), file=sys.stderr)
    
    if temp_dir:
        shutil.rmtree(temp_dir, ignore_errors=True)
    
    return {"success": True, "output_folder": dest_folder, "message": "解压完成: " + os.path.basename(dest_folder)}

def ensure_unicode_path(path):
    if isinstance(path, bytes):
        return path.decode('utf-8')
    return str(path)

def pack_theme(folder_path):
    folder_a = ensure_unicode_path(folder_path)
    
    try:
        normalized_path = os.path.normpath(folder_a)
        folder_name = os.path.basename(normalized_path)
        
        import xml.etree.ElementTree as ET
        version_name = ""
        theme_info_path = ensure_unicode_path(os.path.join(normalized_path, 'themeInfo.xml'))
        if os.path.exists(theme_info_path):
            try:
                tree = ET.parse(theme_info_path)
                root = tree.getroot()
                version_elem = root.find('VersionName')
                if version_elem is not None:
                    version_name = version_elem.text.strip()
            except:
                pass
        
        lockscreen_path = ensure_unicode_path(os.path.join(normalized_path, 'lockscreen'))
        picture_path = ensure_unicode_path(os.path.join(normalized_path, 'picture'))
        theme_widget_path = ensure_unicode_path(os.path.join(normalized_path, 'theme-widget'))
        has_lockscreen = os.path.isdir(lockscreen_path)
        has_picture = os.path.isdir(picture_path)
        has_theme_widget = os.path.isdir(theme_widget_path)
        
        subfolders = []
        for item in os.listdir(normalized_path):
            if item.startswith('.'):
                continue
            item_path = ensure_unicode_path(os.path.join(normalized_path, item))
            if os.path.isdir(item_path) and item not in ('lockscreen', 'picture', 'theme-widget'):
                subfolders.append(item)
        
        temp_dir = tempfile.mkdtemp()
        temp_folder_000 = ensure_unicode_path(os.path.join(temp_dir, '000'))
        os.makedirs(temp_folder_000)
        
        for subfolder_name in subfolders:
            subfolder_path = ensure_unicode_path(os.path.join(normalized_path, subfolder_name))
            zip_path = ensure_unicode_path(os.path.join(temp_folder_000, subfolder_name))
            zip_folder_content(subfolder_path, zip_path)
        
        if has_lockscreen:
            lockscreen_temp = ensure_unicode_path(os.path.join(temp_folder_000, 'lockscreen'))
            os.makedirs(lockscreen_temp)
            
            advance_path = ensure_unicode_path(os.path.join(lockscreen_path, 'advance'))
            if os.path.isdir(advance_path):
                zip_path = ensure_unicode_path(os.path.join(lockscreen_temp, 'lockstyle'))
                zip_folder_without_extension(advance_path, zip_path, lockscreen_path)
        
        files_to_zip = []
        for item in os.listdir(normalized_path):
            if item.startswith('.'):
                continue
            item_path = ensure_unicode_path(os.path.join(normalized_path, item))
            if os.path.isfile(item_path):
                files_to_zip.append((item_path, item))
            elif os.path.isdir(item_path) and item == 'picture':
                for root, dirs, files in os.walk(picture_path):
                    root = ensure_unicode_path(root)
                    dirs[:] = [d for d in dirs if not ensure_unicode_path(d).startswith('.')]
                    for file in files:
                        file = ensure_unicode_path(file)
                        if file.startswith('.'):
                            continue
                        file_path = ensure_unicode_path(os.path.join(root, file))
                        rel_path = ensure_unicode_path(os.path.relpath(file_path, normalized_path))
                        files_to_zip.append((file_path, rel_path))
            elif os.path.isdir(item_path) and item == 'theme-widget':
                for root, dirs, files in os.walk(theme_widget_path):
                    root = ensure_unicode_path(root)
                    dirs[:] = [d for d in dirs if not ensure_unicode_path(d).startswith('.')]
                    for file in files:
                        file = ensure_unicode_path(file)
                        if file.startswith('.'):
                            continue
                        file_path = ensure_unicode_path(os.path.join(root, file))
                        rel_path = ensure_unicode_path(os.path.relpath(file_path, normalized_path))
                        files_to_zip.append((file_path, rel_path))
        
        for item in os.listdir(temp_folder_000):
            item_path = ensure_unicode_path(os.path.join(temp_folder_000, item))
            if os.path.isfile(item_path):
                files_to_zip.append((item_path, item))
            elif os.path.isdir(item_path) and item == 'lockscreen':
                for root, dirs, files in os.walk(item_path):
                    root = ensure_unicode_path(root)
                    dirs[:] = [d for d in dirs if not ensure_unicode_path(d).startswith('.')]
                    for file in files:
                        file = ensure_unicode_path(file)
                        if file.startswith('.'):
                            continue
                        file_path = ensure_unicode_path(os.path.join(root, file))
                        rel_path = ensure_unicode_path(os.path.relpath(file_path, temp_folder_000))
                        files_to_zip.append((file_path, rel_path))
        
        final_zip_name = '{}{}.theme'.format(folder_name, version_name)
        final_zip_path = ensure_unicode_path(os.path.join(os.path.dirname(normalized_path), final_zip_name))
        
        if os.path.exists(final_zip_path):
            os.remove(final_zip_path)
        
        with zipfile.ZipFile(final_zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
            for file_path, arcname in files_to_zip:
                zipf.write(file_path, arcname)
        
        shutil.rmtree(temp_dir)
        
        return {"success": True, "output_file": final_zip_path, "message": "打包完成: " + final_zip_name}
        
    except Exception as e:
        return {"success": False, "error": str(e)}

def zip_folder_without_extension(folder_path, zip_path, base_path=None):
    folder_path = ensure_unicode_path(folder_path)
    zip_path = ensure_unicode_path(zip_path)
    if base_path is None:
        base_path = folder_path
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(folder_path):
            root = ensure_unicode_path(root)
            dirs[:] = [d for d in dirs if not ensure_unicode_path(d).startswith('.')]
            
            for file in files:
                file = ensure_unicode_path(file)
                if file.startswith('.'):
                    continue
                file_path = ensure_unicode_path(os.path.join(root, file))
                rel_path = ensure_unicode_path(os.path.relpath(file_path, base_path))
                zipf.write(file_path, rel_path)

def zip_folder_content(folder_path, zip_path):
    folder_path = ensure_unicode_path(folder_path)
    zip_path = ensure_unicode_path(zip_path)
    
    with zipfile.ZipFile(zip_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(folder_path):
            root = ensure_unicode_path(root)
            dirs[:] = [d for d in dirs if not ensure_unicode_path(d).startswith('.')]
            
            for file in files:
                file = ensure_unicode_path(file)
                if file.startswith('.'):
                    continue
                file_path = ensure_unicode_path(os.path.join(root, file))
                rel_path = ensure_unicode_path(os.path.relpath(file_path, folder_path))
                zipf.write(file_path, rel_path)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(json.dumps({"success": False, "error": "参数不足"}))
        sys.exit(1)
    
    mode = sys.argv[1]
    path = sys.argv[2]
    
    if mode == 'unpack':
        parent_folder = sys.argv[3] if len(sys.argv) > 3 else os.path.dirname(path)
        result = unpack_theme(path, parent_folder)
        print(json.dumps(result, ensure_ascii=False))
    elif mode == 'pack':
        result = pack_theme(path)
        print(json.dumps(result, ensure_ascii=False))
    else:
        print(json.dumps({"success": False, "error": "未知模式"}))
"""

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
                    Text("输出目录: \\(outputPath)")
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
    @State private var statusMessage = "拖入需要打包的文件夹到此处\\n或点击选择"
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
                    Text("输出文件: \\(outputPath)")
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
                    outputPath = result.outputFolder ?? ""
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
        statusMessage = "已选择: \\((path as NSString).lastPathComponent)"
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
    var placeholderText: String = "拖入文件夹到此处\\n或点击选择"
    
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
}

func getPythonScriptPath() -> String {
    let tempDir = NSTemporaryDirectory()
    let scriptPath = (tempDir as NSString).appendingPathComponent("processor.py")
    
    let fileManager = FileManager.default
    do {
        try pythonScript.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: 0o755)], ofItemAtPath: scriptPath)
    } catch {
        print("无法创建Python脚本: \\(error)")
    }
    
    return scriptPath
}

func runPythonScript(mode: String, path: String, parentPath: String? = nil) -> PythonResult {
    var result = PythonResult(success: false, message: nil, error: nil, outputFolder: nil)
    
    let scriptPath = getPythonScriptPath()
    
    var args = [scriptPath, mode, path]
    if let parent = parentPath {
        args.append(parent)
    }
    
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
    process.arguments = args
    
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    let errorPipe = Pipe()
    process.standardError = errorPipe
    
    do {
        try process.run()
        process.waitUntilExit()
        
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        
        if let output = String(data: outputData, encoding: .utf8), !output.isEmpty {
            if let jsonData = output.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                result.success = json["success"] as? Bool ?? false
                result.message = json["message"] as? String
                result.error = json["error"] as? String
                result.outputFolder = json["output_folder"] as? String
            } else {
                result.success = true
                result.message = output.trimmingCharacters(in: .whitespacesAndNewlines)
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
                result.error = "脚本执行失败，退出码: \\(process.terminationStatus)"
            }
        }
        
    } catch {
        result.error = "启动Python失败: \\(error.localizedDescription)"
    }
    
    return result
}

#if swift(>=5.9)
#Preview {
    UnpackView()
}
#endif
