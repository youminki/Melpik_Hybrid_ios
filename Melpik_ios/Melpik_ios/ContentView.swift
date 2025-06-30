//
//  ContentView.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI
import WebKit

struct ContentView: View {
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 상단 네비게이션 바
                HStack {
                    Button(action: {
                        webViewStore.webView.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(canGoBack ? .blue : .gray)
                    }
                    .disabled(!canGoBack)
                    
                    Button(action: {
                        webViewStore.webView.goForward()
                    }) {
                        Image(systemName: "chevron.right")
                            .foregroundColor(canGoForward ? .blue : .gray)
                    }
                    .disabled(!canGoForward)
                    
                    Spacer()
                    
                    Button(action: {
                        webViewStore.webView.reload()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.blue)
                    }
                    
                    Button(action: {
                        webViewStore.webView.load(URLRequest(url: URL(string: "https://me1pik.com/landing")!))
                    }) {
                        Image(systemName: "house")
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                
                // 웹뷰
                WebView(webView: webViewStore.webView, isLoading: $isLoading, canGoBack: $canGoBack, canGoForward: $canGoForward)
                    .overlay(
                        Group {
                            if isLoading {
                                VStack {
                                    ProgressView()
                                        .scaleEffect(1.5)
                                    Text("로딩 중...")
                                        .foregroundColor(.gray)
                                        .padding(.top, 8)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color(.systemBackground))
                            }
                        }
                    )
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    @StateObject private var webViewStore = WebViewStore()
}

struct WebView: UIViewRepresentable {
    let webView: WKWebView
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // 초기 URL 로드
        if let url = URL(string: "https://me1pik.com/landing") {
            webView.load(URLRequest(url: url))
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 업데이트가 필요한 경우 여기에 구현
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

class WebViewStore: ObservableObject {
    let webView: WKWebView
    
    init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.bounces = false
    }
}

#Preview {
    ContentView()
}
