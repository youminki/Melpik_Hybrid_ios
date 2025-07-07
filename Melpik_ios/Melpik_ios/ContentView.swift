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
    static let headerHeight: CGFloat = 1 // 노치 영역까지 포함하도록 높이 증가
    static let loadingSpinnerScale: CGFloat = 1.2
    static let loadingTextSize: CGFloat = 16
    static let initialURL = "https://me1pik.com"
}

// MARK: - ContentView
struct ContentView: View {
    var body: some View {
        TypingLoadingView()
    }
}

struct TypingLoadingView: View {
    let slogan1 = "이젠 "
    let slogan2 = "멜픽"
    let slogan3 = "을 통해"
    let slogan4 = "브랜드를 골라보세요"
    let sloganSub = "사고, 팔고, 빌리는 것을 한번에!"

    @State private var displayed1 = ""
    @State private var displayed2 = ""
    @State private var displayed3 = ""
    @State private var displayed4 = ""
    @State private var displayedSub = ""
    @State private var showWebView = false
    @State private var webViewOpacity: Double = 0
    @State private var loadingOpacity: Double = 1

    // 웹뷰를 미리 생성해두기
    @State private var webViewContainer = MainWebViewContainer()

    var body: some View {
        ZStack {
            // 웹뷰는 항상 존재, opacity로만 제어
            webViewContainer
                .opacity(webViewOpacity)
                .animation(.easeInOut(duration: 0.7), value: webViewOpacity)

            // 로딩뷰도 opacity로만 제어
            loadingBody
                .opacity(loadingOpacity)
                .animation(.easeInOut(duration: 0.7), value: loadingOpacity)
        }
        .onAppear {
            startTyping()
        }
    }

    var loadingBody: some View {
        VStack {
            Spacer().frame(height: 135) // 로그인 박스 margin-top과 동일하게
            VStack(alignment: .center, spacing: 0) {
                // 로고
                Image("LoadingMelPick")
                    .resizable()
                    .frame(width: 184, height: 83)
                    .padding(.bottom, 24) // 로그인 박스와 동일
                // 슬로건 (웹과 동일한 구조)
                VStack(spacing: 0) {
                    // 첫 번째 줄: "이젠 멜픽을 통해"
                    HStack(spacing: 0) {
                        Text(displayed1)
                            .font(.custom("NanumSquareEB", size: 18)) // 나눔스퀘어 ExtraBold
                            .foregroundColor(Color(hex: "#222"))
                        Text(displayed2)
                            .font(.custom("NanumSquareEB", size: 18)) // 나눔스퀘어 ExtraBold
                            .foregroundColor(Color(hex: "#F6AE24"))
                        Text(displayed3)
                            .font(.custom("NanumSquareEB", size: 18)) // 나눔스퀘어 ExtraBold
                            .foregroundColor(Color(hex: "#222"))
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                    
                    // 두 번째 줄: "브랜드를 골라보세요"
                    Text(displayed4)
                        .font(.custom("NanumSquareEB", size: 18)) // 나눔스퀘어 ExtraBold
                        .foregroundColor(Color(hex: "#222"))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .lineSpacing(1.5) // 웹의 line-height: 1.5와 동일
                        .padding(.bottom, 18) // 웹의 margin-bottom: 18px와 동일
                    
                    // 서브슬로건: "사고, 팔고, 빌리는 것을 한번에!"
                    if !displayedSub.isEmpty {
                        Text(displayedSub)
                            .font(.custom("NanumSquareB", size: 15)) // 나눔스퀘어 Bold
                            .foregroundColor(Color(hex: "#888")) // 웹의 color: #888
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .padding(.top, 4) // 웹의 margin-top: 4px
                    }
                }
            }
            Spacer()
        }
        .background(Color.white.ignoresSafeArea())
    }

    func startTyping() {
        displayed1 = ""; displayed2 = ""; displayed3 = ""; displayed4 = ""; displayedSub = ""
        typeLine(slogan1, into: $displayed1) {
            typeLine(slogan2, into: $displayed2) {
                typeLine(slogan3, into: $displayed3) {
                    typeLine(slogan4, into: $displayed4) {
                        typeLine(sloganSub, into: $displayedSub) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                // opacity만 부드럽게 전환
                                withAnimation {
                                    loadingOpacity = 0
                                    webViewOpacity = 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func typeLine(_ text: String, into binding: Binding<String>, completion: @escaping () -> Void) {
        binding.wrappedValue = ""
        var idx = 0
        Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { timer in
            if idx < text.count {
                let i = text.index(text.startIndex, offsetBy: idx+1)
                binding.wrappedValue = String(text[..<i])
                idx += 1
            } else {
                timer.invalidate()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: completion)
            }
        }
    }
}

// HEX 컬러 지원 익스텐션
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct MainWebViewContainer: View {
    var body: some View {
        ContentViewMain()
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
        // 페이지 로드 시 로그인 상태 확인
        window.addEventListener('load', function() {
            if (window.nativeApp && window.nativeApp.checkLoginStatus) {
                setTimeout(function() {
                    window.nativeApp.checkLoginStatus();
                }, 1000);
            }
        });
        
        // 페이지 이동 시 로그인 상태 유지
        window.addEventListener('beforeunload', function() {
            // 로그인 정보를 sessionStorage에 백업
            if (localStorage.getItem('accessToken')) {
                sessionStorage.setItem('accessToken', localStorage.getItem('accessToken'));
                sessionStorage.setItem('userId', localStorage.getItem('userId'));
                sessionStorage.setItem('userEmail', localStorage.getItem('userEmail'));
                sessionStorage.setItem('userName', localStorage.getItem('userName'));
                sessionStorage.setItem('isLoggedIn', 'true');
            }
        });
        
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
            
            // 생체 인증 (비활성화)
            authenticateWithBiometrics: function() {
                console.log('Biometric authentication disabled');
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
                console.log('Auto login disabled - setting ignored');
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'setAutoLogin',
                    enabled: false
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
            },
            
            // 로그인 상태 강제 확인
            checkLoginStatus: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'checkLoginStatus'
                });
            },
            
            // 로그인 정보 강제 전송
            forceLoginInfo: function() {
                window.webkit.messageHandlers.nativeBridge.postMessage({
                    action: 'forceLoginInfo'
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
            let currentURL = webView.url?.absoluteString ?? "nil"
            print("Current URL: \(currentURL)")

            // 로그인 페이지 진입 시 자동 인증 비활성화
            if currentURL.starts(with: "https://me1pik.com/login") {
                print("Login page detected - auto authentication disabled")
            }

            // 웹뷰 로딩 완료 시 로그인 상태 확인 및 전달 (지연 시간 단축)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                print("Checking login status after webview load...")
                self.parent.loginManager.checkLoginStatus(webView: self.parent.webView)
                
                // 추가로 2초 후 한 번 더 확인 (웹사이트가 완전히 로드된 후)
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    if self.parent.loginManager.isLoggedIn {
                        print("Re-checking login status after 2 seconds...")
                        self.parent.loginManager.sendLoginInfoToWeb(webView: self.parent.webView)
                    }
                }
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
                // 생체 인증 비활성화 - 항상 실패 반환
                let script = "window.dispatchEvent(new CustomEvent('biometricAuthResult', { detail: { success: false } }));"
                parent.webView.evaluateJavaScript(script)
                
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
                // 자동 로그인 비활성화 - 설정 무시
                parent.loginManager.setAutoLogin(enabled: false)
                
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
                
            case "checkLoginStatus":
                // 로그인 상태 확인
                parent.loginManager.checkLoginStatus(webView: parent.webView)
                
            case "forceLoginInfo":
                // 로그인 정보 강제 전송
                if parent.loginManager.isLoggedIn {
                    parent.loginManager.sendLoginInfoToWeb(webView: parent.webView)
                }
                
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

// 아래에 기존 ContentView의 웹뷰 관련 전체 코드를 ContentViewMain으로 옮깁니다.

struct ContentViewMain: View {
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
            
            // 웹뷰 (상단 헤더 제거, 하단 safe area 무시)
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
            .ignoresSafeArea(.all, edges: .bottom)
        }
        .statusBarHidden(false)
        .navigationBarHidden(true)
        .preferredColorScheme(.light)
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
