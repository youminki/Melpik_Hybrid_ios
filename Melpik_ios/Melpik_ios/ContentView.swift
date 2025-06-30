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
    static let headerHeight: CGFloat = 50
    static let loadingSpinnerScale: CGFloat = 1.2
    static let loadingTextSize: CGFloat = 16
    static let initialURL = "https://me1pik.com"
}

// MARK: - ContentView
struct ContentView: View {
    @StateObject private var webViewStore = WebViewStore()
    @StateObject private var appState = AppStateManager()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingShareSheet = false
    @State private var showingSafari = false
    @State private var selectedImage: UIImage?
    @State private var shareURL: URL?
    
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
                canGoForward: $canGoForward,
                appState: appState,
                locationManager: locationManager,
                networkMonitor: networkMonitor,
                onImagePicker: { showingImagePicker = true },
                onCamera: { showingCamera = true },
                onShare: { url in
                    shareURL = url
                    showingShareSheet = true
                },
                onSafari: { url in
                    shareURL = url
                    showingSafari = true
                }
            )
            .overlay(loadingOverlay)
        }
        .ignoresSafeArea(.all, edges: .all)
        .statusBarHidden(true)
        .navigationBarHidden(true)
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .sheet(isPresented: $showingSafari) {
            if let url = shareURL {
                SafariView(url: url)
            }
        }
        .onAppear {
            setupApp()
        }
        .onReceive(appState.$pushToken) { token in
            if let token = token {
                sendPushTokenToWeb(token: token)
            }
        }
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
    
    // MARK: - Private Methods
    private func setupApp() {
        // 푸시 알림 권한 요청
        appState.requestPushNotificationPermission()
        
        // 위치 서비스 권한 요청
        locationManager.requestLocationPermission()
        
        // 생체 인증 설정
        appState.setupBiometricAuth()
        
        // 네트워크 모니터링 시작
        networkMonitor.startMonitoring()
    }
    
    private func sendPushTokenToWeb(token: String) {
        let script = "window.dispatchEvent(new CustomEvent('pushTokenReceived', { detail: '\(token)' }));"
        webViewStore.webView.evaluateJavaScript(script)
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
        
        // JavaScript 인터페이스 추가
        setupJavaScriptInterface(context: context)
        
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
    
    // MARK: - Private Methods
    private func setupJavaScriptInterface(context: Context) {
        let contentController = webView.configuration.userContentController
        
        // 네이티브 기능들을 JavaScript에 노출
        contentController.add(context.coordinator, name: "nativeBridge")
        
        // JavaScript 함수들 추가
        let script = """
        window.nativeApp = {
            // 푸시 알림
            requestPushPermission: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'requestPushPermission'
                });
            },
            
            // 위치 서비스
            getLocation: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'getLocation'
                });
            },
            
            // 생체 인증
            authenticateWithBiometrics: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'authenticateWithBiometrics'
                });
            },
            
            // 카메라/갤러리
            openImagePicker: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'openImagePicker'
                });
            },
            
            openCamera: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'openCamera'
                });
            },
            
            // 공유 기능
            share: function(url) {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'share',
                    url: url
                });
            },
            
            // Safari에서 열기
            openInSafari: function(url) {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'openInSafari',
                    url: url
                });
            },
            
            // 네트워크 상태
            getNetworkStatus: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'getNetworkStatus'
                });
            },
            
            // 앱 정보
            getAppInfo: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'getAppInfo'
                });
            },
            
            // 하이브백
            goBack: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'goBack'
                });
            },
            
            // 새로고침
            reload: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'reload'
                });
            }
        };
        """
        
        let userScript = WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        contentController.addUserScript(userScript)
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
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
        
        // MARK: - WKScriptMessageHandler
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: Any],
                  let action = body["action"] as? String else { return }
            
            DispatchQueue.main.async {
                self.handleJavaScriptMessage(action: action, body: body)
            }
        }
        
        private func handleJavaScriptMessage(action: String, body: [String: Any]) {
            switch action {
            case "requestPushPermission":
                parent.appState.requestPushNotificationPermission()
                
            case "getLocation":
                parent.locationManager.requestLocation { [weak self] location in
                    guard let self = self else { return }
                    if let location = location {
                        let script = "window.dispatchEvent(new CustomEvent('locationReceived', { detail: { latitude: \(location.coordinate.latitude), longitude: \(location.coordinate.longitude) } }));"
                        self.parent.webView.evaluateJavaScript(script)
                    }
                }
                
            case "authenticateWithBiometrics":
                parent.appState.authenticateWithBiometrics { [weak self] success in
                    guard let self = self else { return }
                    let script = "window.dispatchEvent(new CustomEvent('biometricAuthResult', { detail: { success: \(success) } }));"
                    self.parent.webView.evaluateJavaScript(script)
                }
                
            case "openImagePicker":
                parent.onImagePicker()
                
            case "openCamera":
                parent.onCamera()
                
            case "share":
                if let urlString = body["url"] as? String,
                   let url = URL(string: urlString) {
                    parent.onShare(url)
                }
                
            case "openInSafari":
                if let urlString = body["url"] as? String,
                   let url = URL(string: urlString) {
                    parent.onSafari(url)
                }
                
            case "getNetworkStatus":
                let isConnected = parent.networkMonitor.isConnected
                let script = "window.dispatchEvent(new CustomEvent('networkStatusReceived', { detail: { isConnected: \(isConnected) } }));"
                parent.webView.evaluateJavaScript(script)
                
            case "getAppInfo":
                let appInfo = parent.appState.getAppInfo()
                let script = "window.dispatchEvent(new CustomEvent('appInfoReceived', { detail: \(appInfo) }));"
                parent.webView.evaluateJavaScript(script)
                
            case "goBack":
                if parent.webView.canGoBack {
                    parent.webView.goBack()
                }
                
            case "reload":
                parent.webView.reload()
                
            default:
                break
            }
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