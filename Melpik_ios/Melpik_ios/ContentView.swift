//
//  ContentView.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI
import WebKit

// MARK: - Constants
private enum Constants {
    static let headerHeight: CGFloat = 60
    static let loadingSpinnerScale: CGFloat = 1.2
    static let loadingTextSize: CGFloat = 16
    static let initialURL = "https://me1pik.com/landing"
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var webViewStore = WebViewStore()
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    
    var body: some View {
        VStack(spacing: 0) {
            // 빈 헤더 영역
            Color.clear
                .frame(height: Constants.headerHeight)
            
            // 웹뷰
            WebView(
                webView: webViewStore.webView,
                isLoading: $isLoading,
                canGoBack: $canGoBack,
                canGoForward: $canGoForward
            )
            .overlay(loadingOverlay)
        }
        .ignoresSafeArea(.all, edges: .all)
        .statusBarHidden(true)
        .navigationBarHidden(true)
    }
    
    // MARK: - Loading Overlay
    @ViewBuilder
    private var loadingOverlay: some View {
        if isLoading {
            VStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(Constants.loadingSpinnerScale)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                
                Text("로딩 중...")
                    .font(.system(size: Constants.loadingTextSize, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
    }
}

// MARK: - WebView
struct WebView: UIViewRepresentable {
    let webView: WKWebView
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        // 웹뷰 설정
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // 웹뷰 상단 여백 제거
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.contentInset = .zero
        webView.scrollView.scrollIndicatorInsets = .zero
        
        // 초기 URL 로드
        guard let url = URL(string: Constants.initialURL) else { return webView }
        webView.load(URLRequest(url: url))
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // UI 업데이트가 필요한 경우에만 구현
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate {
        private var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
            super.init()
        }
        
        // MARK: - WKNavigationDelegate
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

// MARK: - WebViewStore
@MainActor
class WebViewStore: ObservableObject {
    let webView: WKWebView
    
    init() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        // 성능 최적화 설정
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        configuration.processPool = WKProcessPool()
        
        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.scrollView.bounces = false
        
        // 추가 성능 최적화
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
    }
    
    deinit {
        // 메모리 정리
        webView.stopLoading()
        webView.loadHTMLString("", baseURL: nil)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
