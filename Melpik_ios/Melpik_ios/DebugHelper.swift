//
//  DebugHelper.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import Foundation
import WebKit

@MainActor
class DebugHelper {
    static let shared = DebugHelper()
    
    private init() {}
    
    // MARK: - 로그인 상태 디버깅
    func debugLoginState(loginManager: LoginManager, webView: WKWebView) {
        print("=== DEBUG LOGIN STATE ===")
        
        // UserDefaults 확인
        let userDefaults = UserDefaults.standard
        print("UserDefaults values:")
        print("- isLoggedIn: \(userDefaults.bool(forKey: "isLoggedIn"))")
        print("- autoLoginEnabled: \(userDefaults.bool(forKey: "autoLoginEnabled"))")
        print("- accessToken: \(userDefaults.string(forKey: "accessToken") ?? "nil")")
        print("- userId: \(userDefaults.string(forKey: "userId") ?? "nil")")
        print("- userEmail: \(userDefaults.string(forKey: "userEmail") ?? "nil")")
        print("- userName: \(userDefaults.string(forKey: "userName") ?? "nil")")
        
        // LoginManager 상태 확인
        print("LoginManager values:")
        print("- isLoggedIn: \(loginManager.isLoggedIn)")
        if let userInfo = loginManager.userInfo {
            print("- userInfo: id=\(userInfo.id), email=\(userInfo.email), name=\(userInfo.name)")
        } else {
            print("- userInfo: nil")
        }
        
        // 웹뷰에서 localStorage 확인
        let localStorageScript = """
        (function() {
            console.log('=== DEBUG LOCALSTORAGE ===');
            console.log('accessToken:', localStorage.getItem('accessToken'));
            console.log('userId:', localStorage.getItem('userId'));
            console.log('userEmail:', localStorage.getItem('userEmail'));
            console.log('userName:', localStorage.getItem('userName'));
            console.log('refreshToken:', localStorage.getItem('refreshToken'));
            console.log('tokenExpiresAt:', localStorage.getItem('tokenExpiresAt'));
            
            return {
                accessToken: localStorage.getItem('accessToken'),
                userId: localStorage.getItem('userId'),
                userEmail: localStorage.getItem('userEmail'),
                userName: localStorage.getItem('userName'),
                refreshToken: localStorage.getItem('refreshToken'),
                tokenExpiresAt: localStorage.getItem('tokenExpiresAt')
            };
        })();
        """
        
        webView.evaluateJavaScript(localStorageScript) { result, error in
            if let error = error {
                print("❌ Error checking localStorage: \(error)")
            } else {
                print("✅ localStorage check completed")
                if let result = result {
                    print("localStorage result: \(result)")
                }
            }
        }
    }
    
    // MARK: - 강제 로그인 정보 전송
    func forceSendLoginInfo(loginManager: LoginManager, webView: WKWebView) {
        print("=== FORCE SEND LOGIN INFO ===")
        
        // 테스트용 로그인 정보 생성
        let testUserInfo = UserInfo(
            id: "test_user_123",
            email: "test@example.com",
            name: "테스트 사용자",
            token: "test_access_token_12345",
            refreshToken: "test_refresh_token_67890",
            expiresAt: Date().addingTimeInterval(3600) // 1시간 후 만료
        )
        
        // LoginManager에 테스트 정보 설정
        loginManager.userInfo = testUserInfo
        loginManager.isLoggedIn = true
        
        // 웹뷰로 전송
        loginManager.sendLoginInfoToWeb(webView: webView)
        
        print("✅ Test login info sent to web")
    }
    
    // MARK: - 웹뷰 콘솔 로그 확인
    func checkWebViewConsole(webView: WKWebView) {
        print("=== CHECK WEBVIEW CONSOLE ===")
        
        let consoleScript = """
        (function() {
            console.log('=== WEBVIEW CONSOLE CHECK ===');
            console.log('Current URL:', window.location.href);
            console.log('User Agent:', navigator.userAgent);
            console.log('localStorage keys:', Object.keys(localStorage));
            console.log('sessionStorage keys:', Object.keys(sessionStorage));
            console.log('Cookies:', document.cookie);
            
            return {
                url: window.location.href,
                userAgent: navigator.userAgent,
                localStorageKeys: Object.keys(localStorage),
                sessionStorageKeys: Object.keys(sessionStorage),
                cookies: document.cookie
            };
        })();
        """
        
        webView.evaluateJavaScript(consoleScript) { result, error in
            if let error = error {
                print("❌ Error checking webview console: \(error)")
            } else {
                print("✅ WebView console check completed")
                if let result = result {
                    print("WebView console result: \(result)")
                }
            }
        }
    }
    
    // MARK: - 네이티브 브릿지 확인
    func checkNativeBridge(webView: WKWebView) {
        print("=== CHECK NATIVE BRIDGE ===")
        
        let bridgeScript = """
        (function() {
            console.log('=== NATIVE BRIDGE CHECK ===');
            console.log('window.nativeApp exists:', typeof window.nativeApp !== 'undefined');
            
            if (typeof window.nativeApp !== 'undefined') {
                console.log('Available native methods:');
                for (let key in window.nativeApp) {
                    console.log('- ' + key + ':', typeof window.nativeApp[key]);
                }
            }
            
            return {
                nativeAppExists: typeof window.nativeApp !== 'undefined',
                nativeAppType: typeof window.nativeApp
            };
        })();
        """
        
        webView.evaluateJavaScript(bridgeScript) { result, error in
            if let error = error {
                print("❌ Error checking native bridge: \(error)")
            } else {
                print("✅ Native bridge check completed")
                if let result = result {
                    print("Native bridge result: \(result)")
                }
            }
        }
    }
    
    // MARK: - 전체 디버깅 실행
    func runFullDebug(loginManager: LoginManager, webView: WKWebView) {
        print("=== RUNNING FULL DEBUG ===")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.debugLoginState(loginManager: loginManager, webView: webView)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.checkWebViewConsole(webView: webView)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.checkNativeBridge(webView: webView)
        }
    }
} 