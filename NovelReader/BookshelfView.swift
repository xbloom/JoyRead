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
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(role: .destructive, action: {
                            viewModel.clearAllData()
                        }) {
                            Label("清理所有数据", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                
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
        VStack(alignment: .leading, spacing: 6) {
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
                    }
                }
            }
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            
            // 文字信息 - 紧凑布局
            VStack(alignment: .leading, spacing: 3) {
                // 书名
                Text(book.title)
                    .font(.system(size: 14, weight: .semibold))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 34, alignment: .top)
                
                // 作者
                Text(book.author ?? "未知作者")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(height: 42)
        }
        .onAppear {
            loadCoverImage()
        }
    }
    
    private func loadCoverImage() {
        guard let coverURLString = book.coverURL else {
            print("❌ 封面URL为空: \(book.title)")
            return
        }
        
        print("📷 开始加载封面: \(book.title)")
        print("   URL: \(coverURLString)")
        
        guard let url = URL(string: coverURLString) else {
            print("❌ 无效的URL: \(coverURLString)")
            return
        }
        
        guard coverImage == nil else {
            print("✅ 封面已缓存")
            return
        }
        
        isLoadingCover = true
        
        Task {
            do {
                print("🌐 正在下载封面...")
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("📡 HTTP状态: \(httpResponse.statusCode)")
                }
                
                print("📦 下载完成，数据大小: \(data.count) bytes")
                
                if let image = UIImage(data: data) {
                    await MainActor.run {
                        self.coverImage = image
                        self.isLoadingCover = false
                        print("✅ 封面加载成功")
                    }
                } else {
                    await MainActor.run {
                        self.isLoadingCover = false
                        print("❌ 无法解析图片数据")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingCover = false
                    print("❌ 下载失败: \(error)")
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
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("章节URL")) {
                    TextField("粘贴任意章节URL", text: $chapterURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                    
                    Text("支持错层网、零点看书等网站，自动识别并配置")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // CSS 选择器配置已自动处理，不再需要手动输入
                
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
                let repository = NovelRepository()
                
                // 使用 Repository 自动识别网站并获取完整信息（包含正确的 parserConfig）
                let novel = try await repository.addNovel(fromURL: chapterURL)
                
                await MainActor.run {
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
