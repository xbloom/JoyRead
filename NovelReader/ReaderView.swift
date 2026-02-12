import SwiftUI
import UIKit

struct ReaderView: View {
    let book: Novel
    let bookshelfViewModel: NovelshelfViewModel
    
    @StateObject private var viewModel: NovelReaderViewModel
    @StateObject private var settingsManager = ReadingSettingsManager()
    @Environment(\.dismiss) var dismiss
    @State private var showCatalog = false
    @State private var showDownload = false
    @State private var showSettings = false
    @State private var showToolbar = false
    @State private var dragOffset: CGFloat = 0
    @State private var pageChangeHint: String? = nil
    @State private var catalogChapters: [Chapter] = []
    @State private var isDragging = false
    @State private var dragDirection: DragDirection? = nil
    
    enum DragDirection {
        case left, right
    }
    
    init(book: Novel, bookshelfViewModel: NovelshelfViewModel) {
        self.book = book
        self.bookshelfViewModel = bookshelfViewModel
        
        // 使用书籍信息初始化阅读器
        let vm = NovelReaderViewModel()
        vm.currentURL = book.currentChapterURL ?? book.chapters.first?.url ?? ""
        vm.titleSelector = book.parserConfig.titleSelector
        vm.contentSelector = book.parserConfig.contentSelector
        vm.nextChapterSelector = book.parserConfig.nextChapterSelector
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
                            ScrollViewReader { proxy in
                                ScrollView {
                                    VStack(alignment: settingsManager.settings.textAlignment.alignment == .center ? .center : .leading, spacing: settingsManager.settings.paragraphSpacing) {
                                        if let title = viewModel.chapterTitle {
                                            Text(title)
                                                .font(customFont(size: settingsManager.settings.fontSize + 4))
                                                .fontWeight(isSystemFont(settingsManager.settings.fontName) ? settingsManager.settings.fontWeight.weight : .regular)
                                                .bold()
                                                .foregroundColor(settingsManager.settings.theme.textColor)
                                                .multilineTextAlignment(settingsManager.settings.textAlignment.alignment)
                                                .id("chapterTop")  // 添加ID用于滚动定位
                                        }
                                        
                                        // 将内容按段落分割并渲染
                                        ForEach(viewModel.chapterContent.components(separatedBy: "\n").filter { !$0.isEmpty }, id: \.self) { paragraph in
                                            Text("　　\(paragraph)")
                                                .font(customFont(size: settingsManager.settings.fontSize))
                                                .fontWeight(isSystemFont(settingsManager.settings.fontName) ? settingsManager.settings.fontWeight.weight : .regular)
                                                .lineSpacing(settingsManager.settings.lineSpacing)
                                                .foregroundColor(settingsManager.settings.theme.textColor)
                                                .multilineTextAlignment(settingsManager.settings.textAlignment.alignment)
                                        }
                                    }
                                    .padding(.horizontal, settingsManager.settings.horizontalPadding)
                                    .padding(.vertical, 20)
                                    .frame(maxWidth: .infinity, alignment: settingsManager.settings.textAlignment.alignment == .center ? .center : .leading)
                                }
                                .background(settingsManager.settings.theme.backgroundColor)
                                .ignoresSafeArea()  // 让内容占据全屏
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        showToolbar.toggle()
                                    }
                                }
                                .onChange(of: viewModel.currentURL) { _ in
                                    // 章节切换时滚动到顶部
                                    withAnimation {
                                        proxy.scrollTo("chapterTop", anchor: .top)
                                    }
                                }
                                .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        isDragging = true
                                        dragOffset = value.translation.width
                                        
                                        // 判断拖动方向
                                        if value.translation.width > 15 {
                                            dragDirection = .right
                                        } else if value.translation.width < -15 {
                                            dragDirection = .left
                                        }
                                    }
                                    .onEnded { value in
                                        isDragging = false
                                        dragDirection = nil
                                        
                                        let threshold: CGFloat = 60
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
                            }  // ScrollViewReader 结束
                            
                            // 左侧拖动指示器
                            if isDragging && dragDirection == .right {
                                let progress = min(abs(dragOffset) / 60, 1.0)
                                let canFlip = progress > 0.7
                                
                                HStack {
                                    VStack(spacing: 8) {
                                        let arrowSize: CGFloat = 30 + (progress * 10)
                                        
                                        Image(systemName: "chevron.left")
                                            .font(.system(size: arrowSize, weight: .semibold))
                                            .foregroundColor(canFlip ? .green : .primary.opacity(0.6 + progress * 0.4))
                                        
                                        if let prevIndex = catalogChapters.firstIndex(where: { $0.url == viewModel.currentURL }),
                                           prevIndex > 0 {
                                            Text(catalogChapters[prevIndex - 1].title)
                                                .font(.caption)
                                                .foregroundColor(canFlip ? .green : .secondary)
                                                .lineLimit(2)
                                                .frame(width: 80)
                                                .multilineTextAlignment(.center)
                                        } else {
                                            Text("第一章")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(canFlip ? Color.green.opacity(0.15) : Color.primary.opacity(0.05 + progress * 0.05))
                                    )
                                    .padding(.leading, 20)
                                    
                                    Spacer()
                                }
                                .transition(.opacity)
                            }
                            
                            // 右侧拖动指示器
                            if isDragging && dragDirection == .left {
                                let progress = min(abs(dragOffset) / 60, 1.0)
                                let canFlip = progress > 0.7
                                
                                HStack {
                                    Spacer()
                                    
                                    VStack(spacing: 8) {
                                        let arrowSize: CGFloat = 30 + (progress * 10)
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: arrowSize, weight: .semibold))
                                            .foregroundColor(canFlip ? .green : .primary.opacity(0.6 + progress * 0.4))
                                        
                                        if let nextIndex = catalogChapters.firstIndex(where: { $0.url == viewModel.currentURL }),
                                           nextIndex < catalogChapters.count - 1 {
                                            Text(catalogChapters[nextIndex + 1].title)
                                                .font(.caption)
                                                .foregroundColor(canFlip ? .green : .secondary)
                                                .lineLimit(2)
                                                .frame(width: 80)
                                                .multilineTextAlignment(.center)
                                        } else {
                                            Text("最后一章")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(canFlip ? Color.green.opacity(0.15) : Color.primary.opacity(0.05 + progress * 0.05))
                                    )
                                    .padding(.trailing, 20)
                                }
                                .transition(.opacity)
                            }
                            
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
                        
                        // 底部工具栏 - 浮动在内容之上
                        if showToolbar {
                            VStack {
                                Spacer()
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
                                .background(
                                    settingsManager.settings.theme.backgroundColor
                                        .opacity(0.95)
                                        .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
                                )
                            }
                            .transition(.move(edge: .bottom))
                        }
                    }
                }
            }
            .navigationTitle(book.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(!showToolbar)
            .onAppear {
                configureNavigationBarAppearance()
                viewModel.loadChapter()
                loadCatalogForNavigation()
            }
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
                let catalogURL = book.catalogURL
                CatalogView(
                    catalogURL: catalogURL,
                    currentChapterURL: viewModel.currentURL,
                    onSelectChapter: { chapter in
                        viewModel.currentURL = chapter.url
                        viewModel.loadChapter()
                    },
                    cachedChapters: book.chapters
                )
            }
            .sheet(isPresented: $showDownload) {
                let catalogURL = book.catalogURL
                DownloadView(
                    catalogURL: catalogURL,
                    parserConfig: book.parserConfig
                )
            }
            .onAppear {
                configureNavigationBarAppearance()
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
            .onChange(of: settingsManager.settings.theme) { _ in
                configureNavigationBarAppearance()
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    private func customFont(size: CGFloat) -> Font {
        let fontName = settingsManager.settings.fontName
        
        if fontName == "System" {
            return .system(size: size)
        } else if fontName == "PingFang SC" {
            return .system(size: size, design: .default)
        } else {
            // 尝试加载自定义字体
            if let _ = UIFont(name: fontName, size: size) {
                return .custom(fontName, size: size)
            } else {
                // 如果字体加载失败，回退到系统字体
                print("⚠️ 字体加载失败: \(fontName)")
                return .system(size: size)
            }
        }
    }
    
    private func isSystemFont(_ fontName: String) -> Bool {
        let systemFonts = [
            "System",
            "PingFang SC",
            "Songti SC",
            "Heiti SC",
            "Kaiti SC",
            "Yuanti SC"
        ]
        return systemFonts.contains(fontName)
    }
    
    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        
        // 设置背景色和透明度
        let backgroundColor = UIColor(settingsManager.settings.theme.backgroundColor)
        appearance.backgroundColor = backgroundColor.withAlphaComponent(0.95)
        
        // 设置标题颜色
        let textColor = UIColor(settingsManager.settings.theme.textColor)
        appearance.titleTextAttributes = [.foregroundColor: textColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: textColor]
        
        // 设置按钮颜色
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: textColor]
        
        // 添加阴影效果
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        // 应用外观
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    private func saveProgress() {
        var updatedNovel = book
        updatedNovel.currentChapterURL = viewModel.currentURL
        updatedNovel.currentChapterTitle = viewModel.chapterTitle
        updatedNovel.lastReadDate = Date()
        bookshelfViewModel.updateNovel(updatedNovel)
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
        // 直接使用书籍的章节列表
        self.catalogChapters = book.chapters
        updateNavigationFromCatalog()
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
