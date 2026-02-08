import Foundation
import SwiftUI

class BookshelfViewModel: ObservableObject {
    @Published var books: [Book] = []
    
    private let booksKey = "saved_books"
    
    init() {
        loadBooks()
    }
    
    func loadBooks() {
        guard let data = UserDefaults.standard.data(forKey: booksKey),
              let decoded = try? JSONDecoder().decode([Book].self, from: data) else {
            books = []
            return
        }
        books = decoded.sorted { $0.lastReadDate > $1.lastReadDate }
    }
    
    func saveBooks() {
        guard let encoded = try? JSONEncoder().encode(books) else { return }
        UserDefaults.standard.set(encoded, forKey: booksKey)
    }
    
    func addBook(_ book: Book) {
        books.append(book)
        saveBooks()
    }
    
    func updateBook(_ book: Book) {
        if let index = books.firstIndex(where: { $0.id == book.id }) {
            books[index] = book
            saveBooks()
        }
    }
    
    func deleteBook(_ book: Book) {
        books.removeAll { $0.id == book.id }
        saveBooks()
    }
    
    func deleteBooks(at offsets: IndexSet) {
        books.remove(atOffsets: offsets)
        saveBooks()
    }
}
