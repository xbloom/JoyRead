import SwiftUI
import UIKit

@main
struct NovelReaderApp: App {
    init() {
        registerCustomFonts()
    }
    
    var body: some Scene {
        WindowGroup {
            BookshelfView()
        }
    }
    
    private func registerCustomFonts() {
        let fonts = [
            ("NotoSansSC-Regular", "otf"),
            ("NotoSerifSC-Regular", "otf"),
            ("ZCOOLKuaiLe-Regular", "ttf"),
            ("ZCOOLQingKeHuangYou-Regular", "ttf"),
            ("ZCOOLXiaoWei-Regular", "ttf"),
            ("MaShanZheng-Regular", "ttf"),
            ("LiuJianMaoCao-Regular", "ttf"),
            ("LongCang-Regular", "ttf"),
            ("ZhiMangXing-Regular", "ttf")
        ]
        
        for (fontName, ext) in fonts {
            // 尝试从 Fonts 子目录加载
            if let fontURL = Bundle.main.url(forResource: fontName, withExtension: ext, subdirectory: "Fonts") {
                registerFont(url: fontURL, name: fontName)
            }
            // 如果失败，尝试从根目录加载
            else if let fontURL = Bundle.main.url(forResource: fontName, withExtension: ext) {
                registerFont(url: fontURL, name: fontName)
            }
            else {
                print("⚠️ 找不到字体文件: \(fontName).\(ext)")
            }
        }
        
        // 打印所有可用字体
        print("\n=== 已注册的自定义字体 ===")
        for family in UIFont.familyNames.sorted() {
            if family.contains("Noto") || family.contains("ZCOOL") || family.contains("Ma Shan") || 
               family.contains("Liu") || family.contains("Long") || family.contains("Zhi") ||
               family.contains("站酷") || family.contains("钟齐") || family.contains("有字库") {
                print("\n字体家族: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("  PostScript名: \(name)")
                }
            }
        }
    }
    
    private func registerFont(url: URL, name: String) {
        guard let fontDataProvider = CGDataProvider(url: url as CFURL) else {
            print("⚠️ 无法创建字体数据提供者: \(name)")
            return
        }
        
        guard let font = CGFont(fontDataProvider) else {
            print("⚠️ 无法创建字体: \(name)")
            return
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(font, &error) {
            let errorDescription = error?.takeRetainedValue()
            print("⚠️ 注册字体失败: \(name)")
            if let errorDescription = errorDescription {
                print("   错误: \(errorDescription)")
            }
        } else {
            if let postScriptName = font.postScriptName {
                print("✅ 成功注册字体: \(postScriptName)")
            }
        }
    }
}
