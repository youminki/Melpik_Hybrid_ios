//
//  LoginManager.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI
import Security
import LocalAuthentication
import WebKit
import Foundation

@MainActor
class LoginManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var isLoading = true
    @Published var userInfo: UserInfo?
    
    private let keychainService = "com.melpik.app.login"
    private let userDefaults = UserDefaults.standard
    private var isInitializing = false
    
    init() {
        loadLoginState()
    }
    
    deinit {
        print("LoginManager deinit")
    }
    
    // MARK: - 로그인 상태 저장
    @MainActor
    func saveLoginState(userInfo: UserInfo) {
        guard !isInitializing else { return }
        
        print("saveLoginState called, userInfo: \(userInfo)")
        
        // UserDefaults에 기본 정보 저장
        userDefaults.set(true, forKey: "isLoggedIn")
        userDefaults.set(userInfo.id, forKey: "userId")
        userDefaults.set(userInfo.email, forKey: "userEmail")
        userDefaults.set(userInfo.name, forKey: "userName")
        
        // Keychain에 민감한 정보 저장
        saveToKeychain(key: "accessToken", value: userInfo.token)
        if let refreshToken = userInfo.refreshToken {
            saveToKeychain(key: "refreshToken", value: refreshToken)
        }
        if let expiresAt = userInfo.expiresAt {
            userDefaults.set(expiresAt, forKey: "tokenExpiresAt")
        }
        
        // 자동 로그인 설정 저장
        userDefaults.set(true, forKey: "autoLoginEnabled")
        userDefaults.synchronize()
        
        // @Published 프로퍼티 업데이트를 메인 스레드에서 안전하게 처리
        Task { @MainActor in
            self.userInfo = userInfo
            self.isLoggedIn = true
        }
        
        print("[saveLoginState] isLoggedIn:", isLoggedIn)
        print("[saveLoginState] userId:", userDefaults.string(forKey: "userId") ?? "nil")
        print("[saveLoginState] userEmail:", userDefaults.string(forKey: "userEmail") ?? "nil")
        print("[saveLoginState] userName:", userDefaults.string(forKey: "userName") ?? "nil")
        print("[saveLoginState] expiresAt:", userDefaults.object(forKey: "tokenExpiresAt") ?? "nil")
        print("[saveLoginState] accessToken:", loadFromKeychain(key: "accessToken") ?? "nil")
        print("[saveLoginState] refreshToken:", loadFromKeychain(key: "refreshToken") ?? "nil")
    }
    
    // MARK: - 로그인 상태 복원
    @MainActor
    func loadLoginState() {
        guard !isInitializing else { return }
        isInitializing = true
        
        print("=== loadLoginState called ===")
        Task { @MainActor in
            self.isLoading = true
        }
        
        // 자동 로그인 비활성화 - 항상 로그아웃 상태로 시작
        print("=== Auto login disabled - starting with logout state ===")
        logout()
        
        Task { @MainActor in
            self.isLoading = false
        }
        isInitializing = false
    }
    
    // MARK: - 토큰 갱신
    private func refreshAccessToken(refreshToken: String) {
        // 실제 구현에서는 서버에 refresh token을 보내서 새로운 access token을 받아야 함
        // 여기서는 예시로 간단히 처리
        print("Refreshing access token...")
        
        // 서버 API 호출 예시 (실제 구현 필요)
        // refreshTokenAPI(refreshToken: refreshToken) { [weak self] result in
        //     switch result {
        //     case .success(let newToken):
        //         self?.updateToken(newToken: newToken)
        //     case .failure:
        //         self?.logout()
        //     }
        // }
    }
    
    // MARK: - 로그아웃
    func logout() {
        print("=== logout called ===")
        
        // UserDefaults에서 로그인 정보 제거
        userDefaults.removeObject(forKey: "isLoggedIn")
        userDefaults.removeObject(forKey: "userId")
        userDefaults.removeObject(forKey: "userEmail")
        userDefaults.removeObject(forKey: "userName")
        userDefaults.removeObject(forKey: "tokenExpiresAt")
        userDefaults.removeObject(forKey: "autoLoginEnabled")
        
        // Keychain에서 토큰 제거
        deleteFromKeychain(key: "accessToken")
        deleteFromKeychain(key: "refreshToken")
        
        // @Published 프로퍼티 업데이트를 메인 스레드에서 안전하게 처리
        Task { @MainActor in
            self.isLoggedIn = false
            self.userInfo = nil
        }
        
        print("✅ Logout completed")
    }
    
    // MARK: - 자동 로그인 설정 (비활성화)
    func setAutoLogin(enabled: Bool) {
        // 자동 로그인 기능 비활성화
        userDefaults.set(false, forKey: "autoLoginEnabled")
    }
    
    func isAutoLoginEnabled() -> Bool {
        // 항상 false 반환 (자동 로그인 비활성화)
        return false
    }
    
    // MARK: - Keychain 관리
    private func saveToKeychain(key: String, value: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // 기존 항목 삭제
        SecItemDelete(query as CFDictionary)
        
        // 새 항목 추가
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Keychain save error: \(status)")
        }
    }
    
    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return nil
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - 생체 인증을 통한 로그인 (비활성화)
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        // 생체 인증 기능 비활성화 - 항상 실패 반환
        DispatchQueue.main.async {
            completion(false)
        }
    }
    
    // MARK: - 웹에서 받은 로그인 데이터 처리
    func saveLoginInfo(_ loginData: [String: Any]) {
        print("=== saveLoginInfo called ===")
        print("Received login data: \(loginData)")
        
        // UserDefaults를 사용하여 토큰 저장
        if let token = loginData["token"] as? String {
            userDefaults.set(token, forKey: "accessToken")
            print("Saved accessToken to UserDefaults: \(token)")
        } else {
            print("❌ No token found in login data")
        }
        
        if let refreshToken = loginData["refreshToken"] as? String {
            userDefaults.set(refreshToken, forKey: "refreshToken")
            print("Saved refreshToken to UserDefaults: \(refreshToken)")
        }
        
        if let email = loginData["email"] as? String {
            userDefaults.set(email, forKey: "userEmail")
            print("Saved userEmail to UserDefaults: \(email)")
        }
        
        if let id = loginData["id"] as? String {
            userDefaults.set(id, forKey: "userId")
            print("Saved userId to UserDefaults: \(id)")
        }
        
        if let name = loginData["name"] as? String {
            userDefaults.set(name, forKey: "userName")
            print("Saved userName to UserDefaults: \(name)")
        }
        
        // 로그인 상태 저장 (자동 로그인 비활성화)
        userDefaults.set(false, forKey: "autoLoginEnabled")
        userDefaults.set(true, forKey: "isLoggedIn")
        userDefaults.synchronize()
        
        print("=== UserDefaults after saving ===")
        print("isLoggedIn: \(userDefaults.bool(forKey: "isLoggedIn"))")
        print("accessToken: \(userDefaults.string(forKey: "accessToken") ?? "nil")")
        print("userId: \(userDefaults.string(forKey: "userId") ?? "nil")")
        print("userEmail: \(userDefaults.string(forKey: "userEmail") ?? "nil")")
        print("userName: \(userDefaults.string(forKey: "userName") ?? "nil")")
        
        // UserInfo 객체 생성 및 저장
        guard let id = loginData["id"] as? String,
              let email = loginData["email"] as? String,
              let name = loginData["name"] as? String,
              let token = loginData["token"] as? String else {
            print("❌ Invalid login data - missing required fields")
            return
        }
        
        let refreshToken = loginData["refreshToken"] as? String
        let expiresAtString = loginData["expiresAt"] as? String
        
        var expiresAt: Date?
        if let expiresAtString = expiresAtString {
            let formatter = ISO8601DateFormatter()
            expiresAt = formatter.date(from: expiresAtString)
            print("Parsed expiresAt: \(expiresAt?.description ?? "nil")")
        }
        
        let userInfo = UserInfo(
            id: id,
            email: email,
            name: name,
            token: token,
            refreshToken: refreshToken,
            expiresAt: expiresAt
        )
        
        print("Created UserInfo: \(userInfo)")
        saveLoginState(userInfo: userInfo)
        
        // 웹뷰에 로그인 정보 전달
        NotificationCenter.default.post(
            name: NSNotification.Name("LoginInfoReceived"),
            object: nil,
            userInfo: [
                "isLoggedIn": true,
                "userInfo": userInfo
            ]
        )
    }
    
    // MARK: - 로그인 상태 확인
    func checkLoginStatus(webView: WKWebView?) {
        print("=== checkLoginStatus called ===")
        
        let isLoggedIn = userDefaults.bool(forKey: "isLoggedIn")
        let userId = userDefaults.string(forKey: "userId")
        let userEmail = userDefaults.string(forKey: "userEmail")
        let userName = userDefaults.string(forKey: "userName")
        let accessToken = userDefaults.string(forKey: "accessToken")
        
        print("Current login status:")
        print("- isLoggedIn: \(isLoggedIn)")
        print("- userId: \(userId ?? "nil")")
        print("- userEmail: \(userEmail ?? "nil")")
        print("- userName: \(userName ?? "nil")")
        print("- accessToken: \(accessToken ?? "nil")")
        
        if isLoggedIn, let accessToken = accessToken {
            let userInfo = UserInfo(
                id: userId ?? "",
                email: userEmail ?? "",
                name: userName ?? "",
                token: accessToken,
                refreshToken: userDefaults.string(forKey: "refreshToken"),
                expiresAt: userDefaults.object(forKey: "tokenExpiresAt") as? Date
            )
            
            // UserInfo 업데이트를 메인 스레드에서 안전하게 처리
            Task { @MainActor in
                self.userInfo = userInfo
                self.isLoggedIn = true
            }
            
            // 웹뷰에 로그인 정보 전달
            if let webView = webView {
                sendLoginInfoToWeb(webView: webView)
            }
        } else {
            // 로그아웃 상태를 웹뷰에 전달
            let logoutScript = """
            (function() {
                try {
                    // 모든 로그인 관련 데이터 제거
                    localStorage.removeItem('accessToken');
                    localStorage.removeItem('userId');
                    localStorage.removeItem('userEmail');
                    localStorage.removeItem('userName');
                    localStorage.removeItem('refreshToken');
                    localStorage.removeItem('tokenExpiresAt');
                    localStorage.removeItem('isLoggedIn');
                    
                    sessionStorage.removeItem('accessToken');
                    sessionStorage.removeItem('userId');
                    sessionStorage.removeItem('userEmail');
                    sessionStorage.removeItem('userName');
                    sessionStorage.removeItem('refreshToken');
                    sessionStorage.removeItem('tokenExpiresAt');
                    sessionStorage.removeItem('isLoggedIn');
                    
                    // 쿠키 제거
                    document.cookie = 'accessToken=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
                    document.cookie = 'userId=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
                    document.cookie = 'userEmail=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
                    document.cookie = 'isLoggedIn=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
                    
                    // 전역 변수 제거
                    delete window.accessToken;
                    delete window.userId;
                    delete window.userEmail;
                    delete window.userName;
                    delete window.isLoggedIn;
                    
                    // 로그아웃 이벤트 발생
                    window.dispatchEvent(new CustomEvent('logoutSuccess'));
                    
                    console.log('Logout completed - all login data removed');
                    
                } catch (error) {
                    console.error('Error during logout:', error);
                }
            })();
            """
            
            webView?.evaluateJavaScript(logoutScript) { result, error in
                if let error = error {
                    print("웹뷰에 로그아웃 정보 전달 실패: \(error)")
                } else {
                    print("✅ 웹뷰에 로그아웃 정보 전달 완료")
                }
            }
        }
    }
    
    // MARK: - WebView 연동 (로그인 정보 전달)
    func sendLoginInfoToWeb(webView: WKWebView) {
        guard let userInfo = self.userInfo else {
            print("No userInfo to send to web")
            return
        }
        
        let accessToken = userInfo.token.replacingOccurrences(of: "'", with: "\\'")
        let userId = userInfo.id.replacingOccurrences(of: "'", with: "\\'")
        let userEmail = userInfo.email.replacingOccurrences(of: "'", with: "\\'")
        let userName = userInfo.name.replacingOccurrences(of: "'", with: "\\'")
        let refreshToken = (userInfo.refreshToken ?? "").replacingOccurrences(of: "'", with: "\\'")
        let expiresAt = userInfo.expiresAt?.timeIntervalSince1970 ?? 0
        
        // 더 강력한 로그인 정보 전달 스크립트
        let js = """
        (function() {
            try {
                // localStorage에 저장
                localStorage.setItem('accessToken', '\(accessToken)');
                localStorage.setItem('userId', '\(userId)');
                localStorage.setItem('userEmail', '\(userEmail)');
                localStorage.setItem('userName', '\(userName)');
                localStorage.setItem('refreshToken', '\(refreshToken)');
                localStorage.setItem('tokenExpiresAt', '\(expiresAt)');
                localStorage.setItem('isLoggedIn', 'true');
                
                // sessionStorage에도 저장 (세션 유지)
                sessionStorage.setItem('accessToken', '\(accessToken)');
                sessionStorage.setItem('userId', '\(userId)');
                sessionStorage.setItem('userEmail', '\(userEmail)');
                sessionStorage.setItem('userName', '\(userName)');
                sessionStorage.setItem('refreshToken', '\(refreshToken)');
                sessionStorage.setItem('tokenExpiresAt', '\(expiresAt)');
                sessionStorage.setItem('isLoggedIn', 'true');
                
                // 쿠키에도 저장 (서버에서 인식)
                document.cookie = 'accessToken=\(accessToken); path=/; max-age=86400';
                document.cookie = 'userId=\(userId); path=/; max-age=86400';
                document.cookie = 'userEmail=\(userEmail); path=/; max-age=86400';
                document.cookie = 'isLoggedIn=true; path=/; max-age=86400';
                
                // 전역 변수로도 설정
                window.accessToken = '\(accessToken)';
                window.userId = '\(userId)';
                window.userEmail = '\(userEmail)';
                window.userName = '\(userName)';
                window.isLoggedIn = true;
                
                // 로그인 이벤트 발생
                window.dispatchEvent(new CustomEvent('loginSuccess', {
                    detail: {
                        isLoggedIn: true,
                        userInfo: {
                            id: '\(userId)',
                            email: '\(userEmail)',
                            name: '\(userName)',
                            token: '\(accessToken)',
                            refreshToken: '\(refreshToken)',
                            expiresAt: '\(expiresAt)'
                        }
                    }
                }));
                
                console.log('Login info saved to localStorage, sessionStorage, cookies, and global variables');
                
                // 페이지 새로고침 없이 로그인 상태 업데이트
                if (window.location.pathname === '/login') {
                    // 로그인 페이지에서 홈으로 리다이렉트
                    window.location.href = '/';
                }
                
            } catch (error) {
                console.error('Error saving login info:', error);
            }
        })();
        """
        
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                print("Error sending login info to web: \(error)")
            } else {
                print("✅ Login info sent to web successfully")
            }
        }
    }
}

// MARK: - Date Extension
extension Date {
    func ISO8601String() -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}



// MARK: - WebView 연동 (카드 및 로그인 정보)
extension LoginManager {
    // 로그인 정보 JSON 반환 (웹뷰로 전달)
    func getLoginInfo() -> String {
        guard let userInfo = self.userInfo else {
            return "{\"isLoggedIn\": false}"
        }
        let expiresAt = userInfo.expiresAt?.ISO8601String() ?? ""
        let refreshToken = userInfo.refreshToken ?? ""
        let json = """
        {
            "isLoggedIn": true,
            "userInfo": {
                "id": "\(userInfo.id)",
                "email": "\(userInfo.email)",
                "name": "\(userInfo.name)",
                "token": "\(userInfo.token)",
                "refreshToken": "\(refreshToken)",
                "expiresAt": "\(expiresAt)"
            }
        }
        """
        return json
    }

    // 카드 추가 요청 처리 (예시: 1초 후 성공 콜백)
    func handleCardAddRequest(webView: WKWebView, completion: @escaping (Bool, String?) -> Void) {
        // 실제 카드 추가 로직 대신 1초 후 성공 처리
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(true, nil) // 성공
        }
    }

    // 카드 추가 완료 알림 (웹뷰로 JS 이벤트 전달)
    func notifyCardAddComplete(webView: WKWebView, success: Bool, errorMessage: String? = nil) {
        let detail: String
        if success {
            detail = "{success: true}"
        } else {
            let error = errorMessage?.replacingOccurrences(of: "'", with: " ") ?? "Unknown error"
            detail = "{success: false, errorMessage: '\(error)'}"
        }
        let script = "window.dispatchEvent(new CustomEvent('cardAddComplete', { detail: \(detail) }));"
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("Error notifying card add complete: \(error)")
            } else {
                print("Card add complete notified to webView")
            }
        }
    }
} 
