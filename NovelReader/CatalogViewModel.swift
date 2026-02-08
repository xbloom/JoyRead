import SwiftUI

class CatalogViewModel: ObservableObject {
    @Published var bookInfo: BookInfo?
    @Published var chapters: [ChapterListItem] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func loadCatalog(url: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let parser = HTMLParser()
                let (info, chapterList) = try await parser.parseCatalog(url: url)
                
                await MainActor.run {
                    self.bookInfo = info
                    self.chapters = chapterList
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载目录失败: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}
