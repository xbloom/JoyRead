import Foundation
import SwiftUI

class NovelshelfViewModel: ObservableObject {
    @Published var books: [Novel] = []
    
    private let repository = NovelRepository()
    
    init() {
        loadNovels()
    }
    
    func loadNovels() {
        books = repository.getAllNovels()
        print("📚 加载了 \(books.count) 本书")
    }
    
    func addNovel(_ book: Novel) {
        // Repository.addNovel 已经保存了，这里只需重新加载
        loadNovels()
    }
    
    func updateNovel(_ book: Novel) {
        do {
            try repository.updateNovel(book)
            loadNovels()
        } catch {
            print("更新小说失败: \(error)")
        }
    }
    
    func deleteNovel(_ book: Novel) {
        do {
            try repository.deleteNovel(book)
            loadNovels()
        } catch {
            print("删除小说失败: \(error)")
        }
    }
    
    func deleteNovels(at offsets: IndexSet) {
        let booksToDelete = offsets.map { books[$0] }
        for book in booksToDelete {
            deleteNovel(book)
        }
    }
    
    /// 清理所有数据（用于重置）
    func clearAllData() {
        // 删除所有书籍
        for book in books {
            try? repository.deleteNovel(book)
        }
        
        // 清理旧的存储key
        UserDefaults.standard.removeObject(forKey: "saved_books")
        
        // 重新加载
        loadNovels()
        
        print("🗑️ 已清理所有数据")
    }
}
