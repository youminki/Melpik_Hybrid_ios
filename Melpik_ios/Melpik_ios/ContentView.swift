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
    @StateObject private var loginManager = LoginManager()
    
    @State private var isLoading = true
    @State private var canGoBack = false
    @State private var canGoForward = false
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingShareSheet = false
    @State private var showingSafari = false
    @State private var selectedImage: UIImage?
    @State private var shareURL: URL?
    @State private var showingAlert = false
    @State private var showingCardAddView = false
    @State private var cardAddCompletion: ((Bool, String?) -> Void)?
    
    var body: some View {
        ZStack {
            // 전체 배경색 설정
            Color(.systemBackground)
                .ignoresSafeArea(.all, edges: .all)
            
            VStack(spacing: 0) {
                // 상단 헤더 영역
                Color(.systemBackground)
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
                    loginManager: loginManager,
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
        }
        .statusBarHidden(true)
        .navigationBarHidden(true)
        .preferredColorScheme(.light) // 라이트 모드 강제 설정
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
        .sheet(isPresented: $showingCardAddView) {
            if let completion = cardAddCompletion {
                CardAddView { success, error in
                    completion(success, error)
                    showingCardAddView = false
                }
            }
        }
        .alert("제목", isPresented: $showingAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("메시지")
        }
        .onAppear {
            setupApp()
            
            // 앱 시작 시 로그인 상태 확인
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                loginManager.checkLoginStatus(webView: webViewStore.webView)
            }
            
            // 카드 추가 화면 표시 알림 수신
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("ShowCardAddView"),
                object: nil,
                queue: .main
            ) { notification in
                if let completion = notification.userInfo?["completion"] as? (Bool, String?) -> Void {
                    self.cardAddCompletion = completion
                    self.showingCardAddView = true
                }
            }
            
            // 디버깅 도구 실행 (개발 중에만 사용)
            #if DEBUG
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                DebugHelper.shared.runFullDebug(loginManager: loginManager, webView: webViewStore.webView)
            }
            #endif
        }
        .onReceive(appState.$pushToken) { token in
            if let token = token {
                sendPushTokenToWeb(token: token)
            }
        }
        .onReceive(loginManager.$isLoggedIn) { isLoggedIn in
            print("isLoggedIn changed: \(isLoggedIn)")
            if isLoggedIn {
                sendLoginInfoToWeb()
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
    
    private func sendLoginInfoToWeb() {
        print("sendLoginInfoToWeb called")
        loginManager.sendLoginInfoToWeb(webView: webViewStore.webView)
    }
}

// MARK: - WebView
struct WebView: UIViewRepresentable {
    let webView: WKWebView
    @Binding var isLoading: Bool
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    
    let appState: AppStateManager
    let locationManager: LocationManager
    let networkMonitor: NetworkMonitor
    let loginManager: LoginManager
    let onImagePicker: () -> Void
    let onCamera: () -> Void
    let onShare: (URL) -> Void
    let onSafari: (URL) -> Void
    
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
            
            // 로그인 관련
            saveLoginInfo: function(loginData) {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'saveLoginInfo',
                    loginData: loginData
                });
            },
            
            getLoginInfo: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'getLoginInfo'
                });
            },
            
            logout: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'logout'
                });
            },
            
            setAutoLogin: function(enabled) {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'setAutoLogin',
                    enabled: enabled
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
            },
            
            // 카드 추가
            addCard: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'addCard'
                });
            },
            
            // 카드 목록 새로고침
            refreshCardList: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'refreshCardList'
                });
            },
            
            // 디버깅 도구
            debugLoginState: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'debugLoginState'
                });
            },
            
            forceSendLoginInfo: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'forceSendLoginInfo'
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
            print("LoginManager init")
            parent.loginManager.loadLoginState()
        }
        
        // MARK: - WKNavigationDelegate
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
            parent.canGoBack = webView.canGoBack
            parent.canGoForward = webView.canGoForward
            
            print("=== WebView didFinish loading ===")
            print("Current URL: \(webView.url?.absoluteString ?? "nil")")
            
            // 웹뷰 로딩 완료 시 로그인 상태 확인 및 전달
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("Checking login status after webview load...")
                self.parent.loginManager.checkLoginStatus(webView: self.parent.webView)
            }
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
                
            case "saveLoginInfo":
                if let loginData = body["loginData"] as? [String: Any] {
                    parent.loginManager.saveLoginInfo(loginData)
                    
                    // 웹뷰에 로그인 정보 전달
                    let loginInfo = [
                        "type": "loginInfoReceived",
                        "detail": [
                            "isLoggedIn": true,
                            "userInfo": loginData
                        ]
                    ] as [String : Any]
                    
                    if let jsonData = try? JSONSerialization.data(withJSONObject: loginInfo),
                       let jsonString = String(data: jsonData, encoding: .utf8) {
                        
                        let script = """
                            window.dispatchEvent(new CustomEvent('loginInfoReceived', {
                                detail: \(jsonString)
                            }));
                        """
                        
                        parent.webView.evaluateJavaScript(script) { result, error in
                            if let error = error {
                                print("Error sending login info to web: \(error)")
                            } else {
                                print("Login info sent to web successfully")
                            }
                        }
                    }
                }
                
            case "getLoginInfo":
                let loginInfo = parent.loginManager.getLoginInfo()
                let script = "window.dispatchEvent(new CustomEvent('loginInfoReceived', { detail: \(loginInfo) }));"
                parent.webView.evaluateJavaScript(script)
                
            case "logout":
                parent.loginManager.logout()
                
            case "setAutoLogin":
                if let enabled = body["enabled"] as? Bool {
                    parent.loginManager.setAutoLogin(enabled: enabled)
                }
                
            case "goBack":
                if parent.webView.canGoBack {
                    parent.webView.goBack()
                }
                
            case "reload":
                parent.webView.reload()
                
            case "addCard":
                parent.loginManager.handleCardAddRequest(webView: parent.webView) { [weak self] success, errorMessage in
                    guard let self = self else { return }
                    
                    DispatchQueue.main.async {
                        if success {
                            // 카드 추가 성공 시 웹뷰에 알림
                            self.parent.loginManager.notifyCardAddComplete(webView: self.parent.webView, success: true)
                            
                            // 카드 목록 새로고침 이벤트 발생
                            let script = "window.dispatchEvent(new CustomEvent('cardListRefresh'));"
                            self.parent.webView.evaluateJavaScript(script)
                        } else {
                            // 카드 추가 실패 시 웹뷰에 에러 알림
                            self.parent.loginManager.notifyCardAddComplete(webView: self.parent.webView, success: false, errorMessage: errorMessage)
                        }
                    }
                }
                
            case "refreshCardList":
                // 카드 목록 새로고침 이벤트 발생
                let script = "window.dispatchEvent(new CustomEvent('cardListRefresh'));"
                parent.webView.evaluateJavaScript(script)
                
            case "debugLoginState":
                // 로그인 상태 디버깅
                DebugHelper.shared.debugLoginState(loginManager: parent.loginManager, webView: parent.webView)
                
            case "forceSendLoginInfo":
                // 강제 로그인 정보 전송
                DebugHelper.shared.forceSendLoginInfo(loginManager: parent.loginManager, webView: parent.webView)
                
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
        // 메모리 정리 (Swift 6에서는 self 캡처 불가, 별도 정리 불필요)
        // webView.stopLoading()
        // webView.loadHTMLString("", baseURL: nil)
    }
}

// MARK: - Preview
#Preview {
    ContentView()
} 