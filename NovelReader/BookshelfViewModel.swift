import Foundation
import SwiftUI

class NovelshelfViewModel: ObservableObject {
    @Published var books: [Novel] = []
    
    private let booksKey = "saved_books"
    
    init() {
        loadNovels()
    }
    
    func loadNovels() {
        guard let data = UserDefaults.standard.data(forKey: booksKey),
              let decoded = try? JSONDecoder().decode([Novel].self, from: data) else {
            books = []
            return
        }
        books = decoded.sorted { $0.lastReadDate > $1.lastReadDate }
    }
    
    func saveNovels() {
        guard let encoded = try? JSONEncoder().encode(books) else { return }
        UserDefaults.standard.set(encoded, forKey: booksKey)
    }
    
    func addNovel(_ book: Novel) {
        books.append(book)
        saveNovels()
    }
    
    func updateNovel(_ book: Novel) {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
            saveNovels()
        }
    }
    
    func deleteNovel(_ book: Novel) {
        books.removeAll { $0.id == book.id }
        saveNovels()
    }
    
    func deleteNovels(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
        saveNovels()
    }
}
