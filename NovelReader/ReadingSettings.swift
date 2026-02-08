import SwiftUI

struct ReadingSettings: Codable {
    var fontSize: CGFloat = 18
    var lineSpacing: CGFloat = 10
    var paragraphSpacing: CGFloat = 15
    var horizontalPadding: CGFloat = 20
    var fontName: String = "System"
    var theme: ReadingTheme = .light
    
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
