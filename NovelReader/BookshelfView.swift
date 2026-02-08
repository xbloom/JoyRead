import SwiftUI

struct BookshelfView: View {
    @StateObject private var viewModel = BookshelfViewModel()
    @State private var showAddBook = false
    @State private var selectedBook: Book?
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.books.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("书架是空的")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("点击右上角 + 添加小说")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(viewModel.books) { book in
                            BookRowView(book: book)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedBook = book
                                }
                        }
                        .onDelete(perform: viewModel.deleteBooks)
                    }
                }
            }
            .navigationTitle("书架")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddBook = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddBook) {
                AddBookView(viewModel: viewModel)
            }
            .fullScreenCover(item: $selectedBook) { book in
                ReaderView(book: book, bookshelfViewModel: viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct BookRowView: View {
    let book: Book
    
    var body: some View {
        HStack(spacing: 15) {
            // 封面占位符
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 60, height: 80)
                Image(systemName: "book.fill")
                    .font(.title)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(book.title)
                    .font(.headline)
                
                if let chapterTitle = book.currentChapterTitle {
                    Text(chapterTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Text(formatDate(book.lastReadDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 5)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AddBookView: View {
    @ObservedObject var viewModel: BookshelfViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var chapterURL: String = ""
    @State private var titleSelector: String = "h1"
    @State private var contentSelector: String = "#readcontent"
    @State private var nextChapterSelector: String = "a.next"
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("章节URL")) {
                    TextField("粘贴任意章节URL", text: $chapterURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    
                    Text("支持从任意章节开始，会自动获取书籍信息")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section(header: Text("CSS选择器配置（可选）")) {
                    TextField("标题选择器", text: $titleSelector)
                    TextField("内容选择器", text: $contentSelector)
                    TextField("下一章选择器", text: $nextChapterSelector)
                }
                
                if isLoading {
                    Section {
                        HStack {
                            ProgressView()
                            Text("正在获取书籍信息...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if let error = errorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                Section {
                    Button("添加到书架") {
                        addBook()
                    }
                    .disabled(chapterURL.isEmpty || isLoading)
                }
            }
            .navigationTitle("添加小说")
            .navigationBarItems(
                leading: Button("取消") {
                    dismiss()
                }
            )
        }
    }
    
    private func addBook() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let parser = HTMLParser()
                
                // 从章节URL提取bookId并构建目录URL
                guard let bookId = extractBookId(from: chapterURL) else {
                    await MainActor.run {
                        errorMessage = "无法从URL中提取书籍ID"
                        isLoading = false
                    }
                    return
                }
                
                let catalogURL = "https://www.cuoceng.com/book/chapter/\(bookId).html"
                
                // 获取书籍信息和目录
                let (bookInfo, chapters) = try await parser.parseCatalog(url: catalogURL)
                
                await MainActor.run {
                    let book = Book(
                        title: bookInfo.title,
                        author: bookInfo.author,
                        coverURL: bookInfo.coverURL,
                        currentChapterURL: chapterURL,
                        titleSelector: titleSelector,
                        contentSelector: contentSelector,
                        nextChapterSelector: nextChapterSelector,
                        catalogURL: catalogURL
                    )
                    
                    viewModel.addBook(book)
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "获取书籍信息失败: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func extractBookId(from urlString: String) -> String? {
        // 从 https://www.cuoceng.com/book/{bookId}/{chapterId}.html 提取 bookId
        let pattern = "/book/([a-f0-9-]+)/[a-f0-9-]+\\.html"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: urlString, range: NSRange(urlString.startIndex..., in: urlString)),
              let range = Range(match.range(at: 1), in: urlString) else {
            return nil
        }
        return String(urlString[range])
    }
}
