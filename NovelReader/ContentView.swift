import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var viewModel = NovelReaderViewModel()
    
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
            .navigationTitle("小说阅读器")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.showURLInput = true
                    }) {
                        Image(systemName: "link")
                    }
                }
            }
            .sheet(isPresented: $viewModel.showURLInput) {
                URLInputView(viewModel: viewModel)
            }
            .onAppear {
                viewModel.showURLInput = true
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct URLInputView: View {
    @ObservedObject var viewModel: NovelReaderViewModel
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("输入小说章节URL")) {
                    TextField("输入章节URL", text: $viewModel.currentURL)
                        .autocapitalization(.none)
                        .keyboardType(.URL)
                }
                
                Section(header: Text("CSS选择器配置")) {
                    TextField("标题选择器", text: $viewModel.titleSelector)
                    TextField("内容选择器", text: $viewModel.contentSelector)
                    TextField("下一章选择器", text: $viewModel.nextChapterSelector)
                }
                
                Section(header: Text("解析模式")) {
                    Picker("解析方式", selection: $viewModel.parseMode) {
                        Text("正则表达式（快速）").tag(ParseMode.regex)
                        Text("WebView（兼容性好）").tag(ParseMode.webView)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Button("开始阅读") {
                    viewModel.loadChapter()
                    viewModel.showURLInput = false
                }
                .disabled(viewModel.currentURL.isEmpty)
            }
            .navigationTitle("设置")
            .navigationBarItems(trailing: Button("取消") {
                viewModel.showURLInput = false
            })
        }
    }
}
