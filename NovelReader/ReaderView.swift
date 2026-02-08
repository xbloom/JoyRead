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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .background(settingsManager.settings.theme.backgroundColor)
                    
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
                        if let catalogURL = book.catalogURL {
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
                }
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
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
            }
            .onChange(of: viewModel.currentURL) { _ in
                saveProgress()
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
}
