import SwiftUI

struct CatalogView: View {
    let catalogURL: String
    let currentChapterURL: String?
    let onSelectChapter: (Chapter) -> Void
    let cachedChapters: [Chapter]?  // 缓存的章节列表
    
    @StateObject private var viewModel = CatalogViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var refreshID = UUID()
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView("加载目录中...")
                } else if let error = viewModel.errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            viewModel.loadCatalog(url: catalogURL)
                        }
                    }
                    .padding()
                } else {
                    List {
                        // 书籍信息区域
                        if let bookInfo = viewModel.bookInfo {
                            Section {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(bookInfo.title)
                                        .font(.title2)
                                        .bold()
                                    
                                    if let author = bookInfo.author {
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(.secondary)
                                            Text(author)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .foregroundColor(.secondary)
                                        Text("共 \(viewModel.chapters.count) 章")
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                        
                                        // 缓存统计
                                        HStack(spacing: 5) {
                                            Image(systemName: "arrow.down.circle.fill")
                                                .foregroundColor(.green)
                                            Text("\(getCachedCount()) 章已缓存")
                                                .foregroundColor(.secondary)
                                        }
                                        .font(.caption)
                                    }
                                }
                                .padding(.vertical, 5)
                            }
                        }
                        
                        // 章节列表
                        Section(header: Text("章节列表")) {
                            ForEach(viewModel.chapters) { chapter in
                                ChapterRowView(
                                    chapter: chapter,
                                    isCurrent: chapter.url == currentChapterURL
                                )
                                .id("\(chapter.id)-\(refreshID)")
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    onSelectChapter(chapter)
                                    dismiss()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("目录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        refreshCacheStatus()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // 如果有缓存的章节列表，直接使用
                if let cached = cachedChapters, !cached.isEmpty {
                    viewModel.chapters = cached
                } else if viewModel.chapters.isEmpty {
                    viewModel.loadCatalog(url: catalogURL)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func getCachedCount() -> Int {
        viewModel.chapters.filter { ChapterCacheManager.shared.isCached(url: $0.url) }.count
    }
    
    private func refreshCacheStatus() {
        refreshID = UUID()
    }
}

struct ChapterRowView: View {
    let chapter: Chapter
    let isCurrent: Bool
    @State private var isCached: Bool = false
    
    var body: some View {
        HStack {
            Text(chapter.title)
                .foregroundColor(isCurrent ? .blue : .primary)
                .font(isCurrent ? .body.bold() : .body)
            
            Spacer()
            
            HStack(spacing: 8) {
                // 缓存状态图标
                if isCached {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
                
                // 当前阅读标记
                if isCurrent {
                    Image(systemName: "book.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
        }
        .padding(.vertical, 2)
        .onAppear {
            checkCacheStatus()
        }
    }
    
    private func checkCacheStatus() {
        isCached = ChapterCacheManager.shared.isCached(url: chapter.url)
    }
}
