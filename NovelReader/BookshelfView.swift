import SwiftUI

struct NovelshelfView: View {
    @StateObject private var viewModel = NovelshelfViewModel()
    @State private var showAddNovel = false
    @State private var selectedNovel: Novel?
    
    let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 20)
    ]
    
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
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(viewModel.books) { book in
                                NovelCardView(book: book)
                                    .onTapGesture {
                                        selectedNovel = book
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            if let index = viewModel.books.firstIndex(where: { $0.id == book.id }) {
                                                viewModel.deleteNovels(at: IndexSet(integer: index))
                                            }
                                        } label: {
                                            Label("删除", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("书架")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showAddNovel = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddNovel) {
                AddNovelView(viewModel: viewModel)
            }
            .fullScreenCover(item: $selectedNovel) { book in
                ReaderView(book: book, bookshelfViewModel: viewModel)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct NovelCardView: View {
    let book: Novel
    @State private var coverImage: UIImage?
    @State private var isLoadingCover = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 封面
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(0.7, contentMode: .fit)
                
                if let coverImage = coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .aspectRatio(0.7, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else if isLoadingCover {
                    ProgressView()
                        .tint(.white)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white.opacity(0.8))
                        Text(book.title)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                            .padding(.horizontal, 8)
                    }
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // 书名
            Text(book.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 作者
            if let author = book.author {
                Text(author)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // 阅读进度
            if let chapterTitle = book.currentChapterTitle {
                Text(chapterTitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            // 最后阅读时间
            Text(formatDate(book.lastReadDate))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .onAppear {
            loadCoverImage()
        }
    }
    
    private func loadCoverImage() {
        guard let coverURLString = book.coverURL,
              let url = URL(string: coverURLString),
              coverImage == nil else {
            return
        }
        
        isLoadingCover = true
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.coverImage = image
                        self.isLoadingCover = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoadingCover = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingCover = false
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct AddNovelView: View {
    @ObservedObject var viewModel: NovelshelfViewModel
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
                        addNovel()
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
    
    private func addNovel() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let parser = HTMLParser()
                
                // 自动识别页面类型并获取完整信息
                let (bookInfo, chapters) = try await parser.parseBook(fromURL: chapterURL)
                
                await MainActor.run {
                    // 判断用户输入的URL是否是有效的章节URL
                    let isChapterURL = chapterURL.range(of: "/book/[a-f0-9-]+/[a-f0-9-]+\\.html", options: .regularExpression) != nil
                    
                    // 如果不是章节URL，使用第一章作为初始章节
                    let initialChapterURL = isChapterURL ? chapterURL : (chapters.first?.url ?? chapterURL)
                    
                    let novel = Novel(
                        id: bookInfo.id,
                        title: bookInfo.title,
                        author: bookInfo.author,
                        coverURL: bookInfo.coverURL,
                        introduction: bookInfo.introduction,
                        catalogURL: bookInfo.catalogURL,
                        chapters: bookInfo.chapters,
                        currentChapterURL: initialChapterURL,
                        parserConfig: ParserConfig(
                            titleSelector: titleSelector,
                            contentSelector: contentSelector,
                            nextChapterSelector: nextChapterSelector
                        )
                    )
                    
                    viewModel.addNovel(novel)
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
}
