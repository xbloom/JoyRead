import SwiftUI

struct DownloadView: View {
    let catalogURL: String
    let titleSelector: String
    let contentSelector: String
    let nextChapterSelector: String
    
    @StateObject private var downloadManager = DownloadManager()
    @StateObject private var catalogViewModel = CatalogViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if catalogViewModel.isLoading {
                    ProgressView("加载目录中...")
                } else if let error = catalogViewModel.errorMessage {
                    VStack(spacing: 15) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        Text(error)
                            .foregroundColor(.secondary)
                        Button("重试") {
                            catalogViewModel.loadCatalog(url: catalogURL)
                        }
                    }
                } else {
                    // 缓存信息
                    VStack(spacing: 15) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("已缓存章节")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(ChapterCacheManager.shared.getCachedChapterCount()) / \(catalogViewModel.chapters.count)")
                                    .font(.title2)
                                    .bold()
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 5) {
                                Text("缓存大小")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatBytes(ChapterCacheManager.shared.getCacheSize()))
                                    .font(.title2)
                                    .bold()
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    // 下载进度
                    if downloadManager.isDownloading {
                        VStack(spacing: 10) {
                            ProgressView(value: downloadManager.downloadProgress) {
                                HStack {
                                    Text("下载中...")
                                    Spacer()
                                    Text("\(downloadManager.downloadedCount) / \(downloadManager.totalCount)")
                                }
                                .font(.caption)
                            }
                            
                            if let error = downloadManager.errorMessage {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                            
                            Button("取消下载") {
                                downloadManager.cancelDownload()
                            }
                            .foregroundColor(.red)
                        }
                        .padding()
                    } else {
                        VStack(spacing: 15) {
                            Button(action: {
                                downloadAll()
                            }) {
                                Label("下载全书", systemImage: "arrow.down.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                downloadNext50()
                            }) {
                                Label("下载后续50章", systemImage: "arrow.down.circle")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                            
                            Button(action: {
                                clearCache()
                            }) {
                                Label("清空缓存", systemImage: "trash")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.red.opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("下载管理")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("关闭") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                if catalogViewModel.chapters.isEmpty {
                    catalogViewModel.loadCatalog(url: catalogURL)
                }
            }
        }
    }
    
    private func downloadAll() {
        downloadManager.downloadChapters(
            chapters: catalogViewModel.chapters,
            titleSelector: titleSelector,
            contentSelector: contentSelector,
            nextChapterSelector: nextChapterSelector
        )
    }
    
    private func downloadNext50() {
        let chaptersToDownload = Array(catalogViewModel.chapters.prefix(50))
        downloadManager.downloadChapters(
            chapters: chaptersToDownload,
            titleSelector: titleSelector,
            contentSelector: contentSelector,
            nextChapterSelector: nextChapterSelector
        )
    }
    
    private func clearCache() {
        ChapterCacheManager.shared.clearAllCache()
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
