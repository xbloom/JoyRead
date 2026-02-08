import SwiftUI

struct CatalogView: View {
    let catalogURL: String
    let currentChapterURL: String?
    let onSelectChapter: (ChapterListItem) -> Void
    
    @StateObject private var viewModel = CatalogViewModel()
    @Environment(\.dismiss) var dismiss
    
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if viewModel.chapters.isEmpty {
                    viewModel.loadCatalog(url: catalogURL)
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ChapterRowView: View {
    let chapter: ChapterListItem
    let isCurrent: Bool
    
    var body: some View {
        HStack {
            Text(chapter.title)
                .foregroundColor(isCurrent ? .blue : .primary)
                .font(isCurrent ? .body.bold() : .body)
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "book.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.vertical, 2)
    }
}
