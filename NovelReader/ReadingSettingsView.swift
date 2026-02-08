import SwiftUI

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
                        Text("系统默认").tag("System")
                        Text("宋体").tag("Songti SC")
                        Text("黑体").tag("Heiti SC")
                        Text("楷体").tag("Kaiti SC")
                        Text("圆体").tag("Yuanti SC")
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("字号")
                            Spacer()
                            Text("\(Int(settingsManager.settings.fontSize))")
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $settingsManager.settings.fontSize, in: 14...28, step: 1)
                    }
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
                    VStack(alignment: .leading, spacing: settingsManager.settings.paragraphSpacing) {
                        Text("示例标题")
                            .font(customFont(size: settingsManager.settings.fontSize + 4))
                            .bold()
                        
                        Text("　　这是一段示例文字，用于预览当前的阅读设置效果。您可以调整字号、行间距、段落间距等参数，找到最舒适的阅读体验。")
                            .font(customFont(size: settingsManager.settings.fontSize))
                            .lineSpacing(settingsManager.settings.lineSpacing)
                        
                        Text("　　第二段示例文字，展示段落间距的效果。合适的间距可以让长时间阅读更加舒适，减少视觉疲劳。")
                            .font(customFont(size: settingsManager.settings.fontSize))
                            .lineSpacing(settingsManager.settings.lineSpacing)
                    }
                    .padding(.horizontal, settingsManager.settings.horizontalPadding)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
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
        if settingsManager.settings.fontName == "System" {
            return .system(size: size)
        } else {
            return .custom(settingsManager.settings.fontName, size: size)
        }
    }
}
