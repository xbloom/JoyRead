import SwiftUI

struct ReadingSettings: Codable {
    var fontSize: CGFloat = 18
    var lineSpacing: CGFloat = 10
    var paragraphSpacing: CGFloat = 15
    var horizontalPadding: CGFloat = 20
    var fontName: String = "System"
    var theme: ReadingTheme = .light
    var fontWeight: FontWeightOption = .regular
    var textAlignment: TextAlignmentOption = .leading
    
    enum ReadingTheme: String, Codable, CaseIterable {
        case light = "白天"
        case sepia = "护眼"
        case dark = "夜间"
        
        var backgroundColor: Color {
            switch self {
            case .light: return Color.white
            case .sepia: return Color(red: 0.96, green: 0.93, blue: 0.82)
            case .dark: return Color(red: 0.15, green: 0.15, blue: 0.15)
            }
        }
        
        var textColor: Color {
            switch self {
            case .light: return Color.black
            case .sepia: return Color(red: 0.3, green: 0.25, blue: 0.2)
            case .dark: return Color(red: 0.85, green: 0.85, blue: 0.85)
            }
        }
    }
    
    enum FontWeightOption: String, Codable, CaseIterable {
        case ultraLight = "极细"
        case light = "细"
        case regular = "常规"
        case medium = "中等"
        case semibold = "半粗"
        case bold = "粗"
        case heavy = "特粗"
        
        var weight: Font.Weight {
            switch self {
            case .ultraLight: return .ultraLight
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semibold: return .semibold
            case .bold: return .bold
            case .heavy: return .heavy
            }
        }
    }
    
    enum TextAlignmentOption: String, Codable, CaseIterable {
        case leading = "左对齐"
        case center = "居中"
        case justified = "两端对齐"
        
        var alignment: TextAlignment {
            switch self {
            case .leading: return .leading
            case .center: return .center
            case .justified: return .leading  // SwiftUI 没有直接的两端对齐
            }
        }
    }
}

struct FontOption: Identifiable {
    let id: String
    let name: String
    let displayName: String
    
    static let allFonts: [FontOption] = [
        FontOption(id: "System", name: "System", displayName: "系统默认"),
        FontOption(id: "PingFang SC", name: "PingFang SC", displayName: "苹果苹方"),
        FontOption(id: "Songti SC", name: "Songti SC", displayName: "华文宋体"),
        FontOption(id: "Heiti SC", name: "Heiti SC", displayName: "华文黑体"),
        FontOption(id: "Kaiti SC", name: "Kaiti SC", displayName: "华文楷体"),
        FontOption(id: "Yuanti SC", name: "Yuanti SC", displayName: "华文圆体"),
        FontOption(id: "NotoSansCJKsc-Regular", name: "NotoSansCJKsc-Regular", displayName: "思源黑体"),
        FontOption(id: "NotoSerifCJKsc-Regular", name: "NotoSerifCJKsc-Regular", displayName: "思源宋体"),
        FontOption(id: "ZCOOLKuaiLe-Regular", name: "ZCOOLKuaiLe-Regular", displayName: "站酷快乐体"),
        FontOption(id: "ZCOOLQingKeHuangYou-Regular", name: "ZCOOLQingKeHuangYou-Regular", displayName: "站酷黄油体"),
        FontOption(id: "ZCOOLXiaoWei-Regular", name: "ZCOOLXiaoWei-Regular", displayName: "站酷小薇体"),
        FontOption(id: "MaShanZheng-Regular", name: "MaShanZheng-Regular", displayName: "马善政楷书"),
        FontOption(id: "LiuJianMaoCao-Regular", name: "LiuJianMaoCao-Regular", displayName: "刘建毛草书"),
        FontOption(id: "LongCang-Regular", name: "LongCang-Regular", displayName: "龙藏体"),
        FontOption(id: "ZhiMangXing-Regular", name: "ZhiMangXing-Regular", displayName: "志莽行书")
    ]
}

class ReadingSettingsManager: ObservableObject {
    @Published var settings: ReadingSettings {
        didSet {
            save()
        }
    }
    
    private let key = "reading_settings"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(ReadingSettings.self, from: data) {
            settings = decoded
        } else {
            settings = ReadingSettings()
        }
    }
    
    private func save() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    func resetToDefault() {
        settings = ReadingSettings()
    }
}
