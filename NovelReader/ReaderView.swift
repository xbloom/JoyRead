import SwiftUI

struct ReaderView: View {
    let book: Book
    let bookshelfViewModel: BookshelfViewModel
    
    @StateObject private var viewModel: NovelReaderViewModel
    @StateObject private var settingsManager = ReadingSettingsManager()
    @Environment(\.dismiss) var dismiss
    @State private var showCatalog = false
    @State private var showDownload = false
    @State private var showSettings = false
    @State private var showToolbar = false
    @State private var dragOffset: CGFloat = 0
    @State private var pageChangeHint: String? = nil
    @State private var catalogChapters: [ChapterListItem] = []
    
    init(book: Book, bookshelfViewModel: BookshelfViewModel) {
        self.book = book
        self.bookshelfViewModel = bookshelfViewModel
        
        // 使用书籍信息初始化阅读器
        let vm = NovelReaderViewModel()
        vm.currentURL = book.currentChapterURL
        vm.titleSelector = book.titleSelector
        vm.contentSelector = book.contentSelector
        vm.nextChapterSelector = book.nextChapterSelector
        _viewModel = StateObject(wrappedValue: vm)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("加载中...")
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Text("错误")
                            .font(.headline)
                        Text(error)
                            .foregroundColor(.red)
                            .padding()
                        Button("重试") {
                            viewModel.loadChapter()
                        }
                    }
                } else {
                    ZStack(alignment: .bottom) {
                        ZStack {
                            ScrollView {
                                VStack(alignment: .leading, spacing: settingsManager.settings.paragraphSpacing) {
                                    if let title = viewModel.chapterTitle {
                                        Text(title)
                                            .font(customFont(size: settingsManager.settings.fontSize + 4))
                                            .bold()
                                            .foregroundColor(settingsManager.settings.theme.textColor)
                                    }
                                    
                                    // 将内容按段落分割并渲染
                                    ForEach(viewModel.chapterContent.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { paragraph in
                                        Text("　　\(paragraph)")
                                            .font(customFont(size: settingsManager.settings.fontSize))
                                            .lineSpacing(settingsManager.settings.lineSpacing)
                                            .foregroundColor(settingsManager.settings.theme.textColor)
                                    }
                                }
                                .padding(.horizontal, settingsManager.settings.horizontalPadding)
                                .padding(.vertical, 20)
                                .padding(.bottom, showToolbar ? 60 : 0)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(settingsManager.settings.theme.backgroundColor)
                            .offset(x: dragOffset)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showToolbar.toggle()
                                }
                            }
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        dragOffset = value.translation.width * 0.3
                                    }
                                    .onEnded { value in
                                        let threshold: CGFloat = 100
                                        if value.translation.width > threshold {
                                            // 右滑 - 上一章
                                            if viewModel.hasPreviousChapter {
                                                viewModel.loadPreviousChapter()
                                            } else {
                                                showPageChangeHint("已是第一章")
                                            }
                                        } else if value.translation.width < -threshold {
                                            // 左滑 - 下一章
                                            if viewModel.hasNextChapter {
                                                viewModel.loadNextChapter()
                                            } else {
                                                showPageChangeHint("已是最后一章")
                                            }
                                        }
                                        withAnimation(.spring()) {
                                            dragOffset = 0
                                        }
                                    }
                            )
                            
                            // 翻页提示
                            if let hint = pageChangeHint {
                                VStack {
                                    Spacer()
                                    Text(hint)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 30)
                                        .padding(.vertical, 15)
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(25)
                                        .transition(.scale.combined(with: .opacity))
                                    Spacer()
                                }
                            }
                        }
                        
                        // 底部工具栏
                        if showToolbar {
                            HStack {
                                Button(action: {
                                    viewModel.loadPreviousChapter()
                                }) {
                                    Label("上一章", systemImage: "chevron.left")
                                }
                                .disabled(!viewModel.hasPreviousChapter)
                                
                                Spacer()
                                
                                // 阅读设置按钮
                                Button(action: {
                                    showSettings = true
                                }) {
                                    Label("设置", systemImage: "textformat.size")
                                }
                                
                                Spacer()
                                
                                // 目录按钮
                                if book.catalogURL != nil {
                                    Button(action: {
                                        showCatalog = true
                                    }) {
                                        Label("目录", systemImage: "list.bullet")
                                    }
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    viewModel.loadNextChapter()
                                }) {
                                    Label("下一章", systemImage: "chevron.right")
                                }
                                .disabled(!viewModel.hasNextChapter)
                            }
                            .padding()
                            .background(settingsManager.settings.theme.backgroundColor.opacity(0.95))
                            .transition(.move(edge: .bottom))
                        }
                    }
                }
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(!showToolbar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("返回") {
                        saveProgress()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            viewModel.showURLInput = true
                        }) {
                            Label("设置", systemImage: "gearshape")
                        }
                        
                        if book.catalogURL != nil {
                            Button(action: {
                                showDownload = true
                            }) {
                                Label("下载管理", systemImage: "arrow.down.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showURLInput) {
                URLInputView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                ReadingSettingsView(settingsManager: settingsManager)
            }
            .sheet(isPresented: $showCatalog) {
                if let catalogURL = book.catalogURL {
                    CatalogView(
                        catalogURL: catalogURL,
                        currentChapterURL: viewModel.currentURL,
                        onSelectChapter: { chapter in
                            viewModel.currentURL = chapter.url
                            viewModel.loadChapter()
                        }
                    )
                }
            }
            .sheet(isPresented: $showDownload) {
                if let catalogURL = book.catalogURL {
                    DownloadView(
                        catalogURL: catalogURL,
                        titleSelector: book.titleSelector,
                        contentSelector: book.contentSelector,
                        nextChapterSelector: book.nextChapterSelector
                    )
                }
            }
            .onAppear {
                viewModel.loadChapter()
                loadCatalogForNavigation()
            }
            .onChange(of: viewModel.currentURL) { _ in
                saveProgress()
                updateNavigationFromCatalog()
            }
            .onChange(of: viewModel.chapterTitle) { newTitle in
                if let title = newTitle {
                    showPageChangeHint(title)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func customFont(size: CGFloat) -> Font {
        if settingsManager.settings.fontName == "System" {
            return .system(size: size)
        } else {
            return .custom(settingsManager.settings.fontName, size: size)
        }
    }
    
    private func saveProgress() {
        var updatedBook = book
        updatedBook.currentChapterURL = viewModel.currentURL
        updatedBook.currentChapterTitle = viewModel.chapterTitle
        updatedBook.lastReadDate = Date()
        bookshelfViewModel.updateBook(updatedBook)
    }
    
    private func showPageChangeHint(_ text: String) {
        withAnimation(.spring()) {
            pageChangeHint = text
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 0.3)) {
                pageChangeHint = nil
            }
        }
    }
    
    private func loadCatalogForNavigation() {
        guard let catalogURL = book.catalogURL else { return }
        
        Task {
            do {
                let parser = HTMLParser()
                let (_, chapters) = try await parser.parseCatalog(url: catalogURL)
                await MainActor.run {
                    self.catalogChapters = chapters
                    updateNavigationFromCatalog()
                }
            } catch {
                print("加载目录失败: \(error)")
            }
        }
    }
    
    private func updateNavigationFromCatalog() {
        guard !catalogChapters.isEmpty else { return }
        
        // 找到当前章节在目录中的位置
        if let currentIndex = catalogChapters.firstIndex(where: { $0.url == viewModel.currentURL }) {
            // 设置上一章
            if currentIndex > 0 {
                viewModel.previousChapterURL = catalogChapters[currentIndex - 1].url
            } else {
                viewModel.previousChapterURL = nil
            }
            
            // 设置下一章（如果 HTML 中没有解析到）
            if viewModel.nextChapterURL == nil && currentIndex < catalogChapters.count - 1 {
                viewModel.nextChapterURL = catalogChapters[currentIndex + 1].url
            }
        }
    }
}
