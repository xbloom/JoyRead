import SwiftUI
import UIKit

struct ReadingSettingsView: View {
    @ObservedObject var settingsManager: ReadingSettingsManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("主题") {
                    Picker("阅读主题", selection: $settingsManager.settings.theme) {
                        ForEach(ReadingSettings.ReadingTheme.allCases, id: \.self) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("字体") {
                    Picker("字体", selection: $settingsManager.settings.fontName) {
                        ForEach(FontOption.allFonts) { font in
                            Text(font.displayName).tag(font.name)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    // 只有系统字体支持粗细调节
                    if isSystemFont(settingsManager.settings.fontName) {
                        Picker("粗细", selection: $settingsManager.settings.fontWeight) {
                            ForEach(ReadingSettings.FontWeightOption.allCases, id: \.self) { weight in
                                Text(weight.rawValue).tag(weight)
                            }
                        }
                        .pickerStyle(.segmented)
                    } else {
                        HStack {
                            Text("粗细")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("该字体仅支持常规粗细")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("字号")
                            Spacer()
                            Text("\(Int(settingsManager.settings.fontSize))")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.settings.fontSize, in: 14...48, step: 1)
                    }
                }
                
                Section("排版") {
                    Picker("对齐方式", selection: $settingsManager.settings.textAlignment) {
                        ForEach(ReadingSettings.TextAlignmentOption.allCases, id: \.self) { alignment in
                            Text(alignment.rawValue).tag(alignment)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("间距") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("行间距")
                            Spacer()
                            Text("\(Int(settingsManager.settings.lineSpacing))")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.settings.lineSpacing, in: 5...20, step: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("段落间距")
                            Spacer()
                            Text("\(Int(settingsManager.settings.paragraphSpacing))")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.settings.paragraphSpacing, in: 10...30, step: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("页边距")
                            Spacer()
                            Text("\(Int(settingsManager.settings.horizontalPadding))")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.settings.horizontalPadding, in: 10...40, step: 2)
                    }
                }
                
                Section("预览") {
                    VStack(alignment: settingsManager.settings.textAlignment.alignment == .center ? .center : .leading, spacing: settingsManager.settings.paragraphSpacing) {
                        Text("示例标题")
                            .font(customFont(size: settingsManager.settings.fontSize + 4))
                            .fontWeight(isSystemFont(settingsManager.settings.fontName) ? settingsManager.settings.fontWeight.weight : .regular)
                            .bold()
                            .multilineTextAlignment(settingsManager.settings.textAlignment.alignment)
                        
                        Text("　　这是一段示例文字，用于预览当前的阅读设置效果。您可以调整字号、行间距、段落间距、字体粗细等参数，找到最舒适的阅读体验。")
                            .font(customFont(size: settingsManager.settings.fontSize))
                            .fontWeight(isSystemFont(settingsManager.settings.fontName) ? settingsManager.settings.fontWeight.weight : .regular)
                            .lineSpacing(settingsManager.settings.lineSpacing)
                            .multilineTextAlignment(settingsManager.settings.textAlignment.alignment)
                        
                        Text("　　第二段示例文字，展示段落间距的效果。合适的间距可以让长时间阅读更加舒适，减少视觉疲劳。")
                            .font(customFont(size: settingsManager.settings.fontSize))
                            .fontWeight(isSystemFont(settingsManager.settings.fontName) ? settingsManager.settings.fontWeight.weight : .regular)
                            .lineSpacing(settingsManager.settings.lineSpacing)
                            .multilineTextAlignment(settingsManager.settings.textAlignment.alignment)
                    }
                    .padding(.horizontal, settingsManager.settings.horizontalPadding)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: settingsManager.settings.textAlignment.alignment == .center ? .center : .leading)
                    .background(settingsManager.settings.theme.backgroundColor)
                    .foregroundColor(settingsManager.settings.theme.textColor)
                    .cornerRadius(8)
                }
                
                Section {
                    Button("恢复默认设置") {
                        settingsManager.resetToDefault()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("阅读设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func customFont(size: CGFloat) -> Font {
        let fontName = settingsManager.settings.fontName
        
        if fontName == "System" {
            return .system(size: size)
        } else if fontName == "PingFang SC" {
            return .system(size: size, design: .default)
        } else {
            // 尝试加载自定义字体
            if let _ = UIFont(name: fontName, size: size) {
                return .custom(fontName, size: size)
            } else {
                // 如果字体加载失败，回退到系统字体
                return .system(size: size)
            }
        }
    }
    
    private func isSystemFont(_ fontName: String) -> Bool {
        // 系统字体列表
        let systemFonts = [
            "System",
            "PingFang SC",
            "Songti SC",
            "Heiti SC",
            "Kaiti SC",
            "Yuanti SC"
        ]
        return systemFonts.contains(fontName)
    }
}
