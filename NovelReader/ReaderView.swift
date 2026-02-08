import SwiftUI

struct ReaderView: View {
    let book: Book
    let bookshelfViewModel: BookshelfViewModel
    
    @StateObject private var viewModel: NovelReaderViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showCatalog = false
    @State private var showDownload = false
    
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
                        VStack(alignment: .leading, spacing: 20) {
                            if let title = viewModel.chapterTitle {
                                Text(title)
                                    .font(.title)
                                    .bold()
                                    .padding(.horizontal)
                            }
                            
                            Text(viewModel.chapterContent)
                                .font(.body)
                                .lineSpacing(8)
                                .padding()
                        }
                    }
                    
                    HStack {
                        Button(action: {
                            viewModel.loadPreviousChapter()
                        }) {
                            Label("上一章", systemImage: "chevron.left")
                        }
                        .disabled(!viewModel.hasPreviousChapter)
                        
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
    
    private func saveProgress() {
        var updatedBook = book
        updatedBook.currentChapterURL = viewModel.currentURL
        updatedBook.currentChapterTitle = viewModel.chapterTitle
        updatedBook.lastReadDate = Date()
        bookshelfViewModel.updateBook(updatedBook)
    }
}
