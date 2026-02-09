import SwiftUI

class CatalogViewModel: ObservableObject {
    @Published var bookInfo: Novel?
    @Published var chapters: [Chapter] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let repository = NovelRepository()
    
    func loadCatalog(url: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 使用 Repository 重新获取书籍信息
                let novel = try await repository.addNovel(fromURL: url)
                
                await MainActor.run {
                    self.bookInfo = novel
                    self.chapters = novel.chapters
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
