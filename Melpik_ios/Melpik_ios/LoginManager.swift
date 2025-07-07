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
    
    init() {
        loadLoginState()
    }
    
    // MARK: - 로그인 상태 저장
    @MainActor
    func saveLoginState(userInfo: UserInfo) {
        print("saveLoginState called, userInfo: \(userInfo)")
        
        // @Published 프로퍼티 업데이트
        DispatchQueue.main.async { [weak self] in
            self?.userInfo = userInfo
            self?.isLoggedIn = true
        }
        
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
        print("=== loadLoginState called ===")
        DispatchQueue.main.async { [weak self] in self?.isLoading = true }
        
        // 자동 로그인이 활성화되어 있는지 확인
        let autoLoginEnabled = userDefaults.bool(forKey: "autoLoginEnabled")
        let isLoggedIn = userDefaults.bool(forKey: "isLoggedIn")
        let userId = userDefaults.string(forKey: "userId")
        let userEmail = userDefaults.string(forKey: "userEmail")
        let userName = userDefaults.string(forKey: "userName")
        let accessTokenFromDefaults = userDefaults.string(forKey: "accessToken")
        let refreshTokenFromDefaults = userDefaults.string(forKey: "refreshToken")
        let expiresAt = userDefaults.object(forKey: "tokenExpiresAt")
        let accessTokenFromKeychain = loadFromKeychain(key: "accessToken")
        let refreshTokenFromKeychain = loadFromKeychain(key: "refreshToken")
        
        print("=== UserDefaults values ===")
        print("autoLoginEnabled: \(autoLoginEnabled)")
        print("isLoggedIn: \(isLoggedIn)")
        print("userId: \(userId ?? "nil")")
        print("userEmail: \(userEmail ?? "nil")")
        print("userName: \(userName ?? "nil")")
        print("accessToken (UserDefaults): \(accessTokenFromDefaults ?? "nil")")
        print("refreshToken (UserDefaults): \(refreshTokenFromDefaults ?? "nil")")
        print("expiresAt: \(expiresAt != nil ? "\(expiresAt!)" : "nil")")
        
        print("=== Keychain values ===")
        print("accessToken (Keychain): \(accessTokenFromKeychain ?? "nil")")
        print("refreshToken (Keychain): \(refreshTokenFromKeychain ?? "nil")")
        
        if autoLoginEnabled && isLoggedIn {
            print("=== Attempting to restore login state ===")
            
            // UserDefaults에서 먼저 확인
            if let accessToken = accessTokenFromDefaults {
                print("✅ Found accessToken in UserDefaults")
                
                let userInfo = UserInfo(
                    id: userId ?? "",
                    email: userEmail ?? "",
                    name: userName ?? "",
                    token: accessToken,
                    refreshToken: refreshTokenFromDefaults,
                    expiresAt: expiresAt as? Date
                )
                
                print("Created UserInfo from UserDefaults: \(userInfo)")
                
                // 토큰이 만료되지 않았는지 확인
                if !userInfo.isTokenExpired {
                    DispatchQueue.main.async { [weak self] in
                        self?.userInfo = userInfo
                        self?.isLoggedIn = true
                    }
                    print("✅ Login state restored successfully")
                } else {
                    print("❌ Token is expired")
                    if let refreshToken = refreshTokenFromDefaults {
                        print("🔄 Attempting token refresh...")
                        refreshAccessToken(refreshToken: refreshToken)
                    } else {
                        print("❌ No refresh token available, logging out")
                        logout()
                    }
                }
            } else if let accessToken = accessTokenFromKeychain {
                print("✅ Found accessToken in Keychain")
                
                let userInfo = UserInfo(
                    id: userId ?? "",
                    email: userEmail ?? "",
                    name: userName ?? "",
                    token: accessToken,
                    refreshToken: refreshTokenFromKeychain,
                    expiresAt: expiresAt as? Date
                )
                
                print("Created UserInfo from Keychain: \(userInfo)")
                
                if !userInfo.isTokenExpired {
                    DispatchQueue.main.async { [weak self] in
                        self?.userInfo = userInfo
                        self?.isLoggedIn = true
                    }
                    print("✅ Login state restored successfully from Keychain")
                } else {
                    print("❌ Token is expired")
                    if let refreshToken = refreshTokenFromKeychain {
                        print("🔄 Attempting token refresh...")
                        refreshAccessToken(refreshToken: refreshToken)
                    } else {
                        print("❌ No refresh token available, logging out")
                        logout()
                    }
                }
            } else {
                print("❌ No access token found in UserDefaults or Keychain")
                logout()
            }
        } else {
            print("❌ Auto login not enabled or user not logged in")
            logout()
        }
        
        DispatchQueue.main.async { [weak self] in self?.isLoading = false }
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
        DispatchQueue.main.async { [weak self] in
            self?.isLoggedIn = false
            self?.userInfo = nil
        }
        
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
    }
    
    // MARK: - 자동 로그인 설정
    func setAutoLogin(enabled: Bool) {
        userDefaults.set(enabled, forKey: "autoLoginEnabled")
    }
    
    func isAutoLoginEnabled() -> Bool {
        return userDefaults.bool(forKey: "autoLoginEnabled")
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
    
    // MARK: - 생체 인증을 통한 로그인
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        let reason = "저장된 로그인 정보에 접근합니다"
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { [weak self] success, error in
            DispatchQueue.main.async {
                if success {
                    // 생체 인증 성공 시 저장된 로그인 정보 복원
                    self?.loadLoginState()
                }
                completion(success)
            }
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
        
        // 자동 로그인 활성화
        userDefaults.set(true, forKey: "autoLoginEnabled")
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
        DispatchQueue.main.async { [weak self] in
            self?.saveLoginState(userInfo: userInfo)
        }
        
        // 웹뷰에 로그인 정보 전달
        let loginInfo = [
            "type": "loginInfoReceived",
            "detail": [
                "isLoggedIn": true,
                "userInfo": loginData
            ]
        ] as [String : Any]
        
        // JSON으로 변환하여 웹뷰에 전달
        if let jsonData = try? JSONSerialization.data(withJSONObject: loginInfo),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            
            // ContentView에서 웹뷰 참조를 받아서 실행하도록 수정 필요
            print("Login info ready to send to web: \(jsonString)")
        }
        
        print("=== Login info saved successfully ===")
    }
    
    // MARK: - 웹뷰에 로그인 정보 전달
    func getLoginInfo() -> String {
        guard let userInfo = userInfo else {
            return """
            {
                "isLoggedIn": false,
                "userInfo": null
            }
            """
        }
        
        return """
        {
            "isLoggedIn": \(isLoggedIn),
            "userInfo": {
                "id": "\(userInfo.id)",
                "email": "\(userInfo.email)",
                "name": "\(userInfo.name)",
                "token": "\(userInfo.token)",
                "isTokenExpired": \(userInfo.isTokenExpired)
            }
        }
        """
    }
    
    // MARK: - 웹뷰로 로그인 정보 전달
    func sendLoginInfoToWeb(webView: WKWebView) {
        guard let userInfo = userInfo else {
            print("❌ sendLoginInfoToWeb: userInfo is nil")
            return
        }
        
        print("=== sendLoginInfoToWeb called ===")
        print("UserInfo to send: \(userInfo)")
        
        // 웹뷰에 로그인 정보를 JavaScript로 전달
        let script = """
        (function() {
            try {
                console.log('Native app sending login info to web...');
                
                // localStorage에 로그인 정보 저장
                localStorage.setItem('accessToken', '\(userInfo.token)');
                localStorage.setItem('userId', '\(userInfo.id)');
                localStorage.setItem('userEmail', '\(userInfo.email)');
                localStorage.setItem('userName', '\(userInfo.name)');
                
                if ('\(userInfo.refreshToken ?? "")' !== '') {
                    localStorage.setItem('refreshToken', '\(userInfo.refreshToken ?? "")');
                }
                
                if ('\(userInfo.expiresAt?.timeIntervalSince1970 ?? 0)' !== '0') {
                    localStorage.setItem('tokenExpiresAt', '\(userInfo.expiresAt?.timeIntervalSince1970 ?? 0)');
                }
                
                // 쿠키에도 토큰 설정
                document.cookie = 'accessToken=\(userInfo.token); path=/; secure; samesite=strict';
                document.cookie = 'userId=\(userInfo.id); path=/; secure; samesite=strict';
                
                // 로그인 상태 이벤트 발생
                window.dispatchEvent(new CustomEvent('nativeLoginSuccess', {
                    detail: {
                        userId: '\(userInfo.id)',
                        userEmail: '\(userInfo.email)',
                        userName: '\(userInfo.name)',
                        accessToken: '\(userInfo.token)'
                    }
                }));
                
                // 추가 이벤트도 발생
                window.dispatchEvent(new CustomEvent('loginInfoReceived', {
                    detail: {
                        isLoggedIn: true,
                        userInfo: {
                            id: '\(userInfo.id)',
                            email: '\(userInfo.email)',
                            name: '\(userInfo.name)',
                            token: '\(userInfo.token)',
                            refreshToken: '\(userInfo.refreshToken ?? "")'
                        }
                    }
                }));
                
                console.log('✅ Native login info sent to web successfully');
                console.log('localStorage accessToken:', localStorage.getItem('accessToken'));
                console.log('localStorage userId:', localStorage.getItem('userId'));
            } catch (error) {
                console.error('❌ Error in native login script:', error);
            }
        })();
        """
        
        print("Executing JavaScript script...")
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("❌ sendLoginInfoToWeb error: \(error)")
            } else {
                print("✅ sendLoginInfoToWeb success")
                if let result = result {
                    print("JavaScript result: \(result)")
                }
            }
        }
    }
    
    // MARK: - 앱 시작 시 로그인 상태 확인
    func checkLoginStatus(webView: WKWebView) {
        print("checkLoginStatus called")
        
        if isLoggedIn, let _ = userInfo {
            print("User is logged in, sending info to web")
            sendLoginInfoToWeb(webView: webView)
        } else {
            print("User is not logged in")
            // 웹뷰에 로그아웃 상태 알림
            let logoutScript = """
            (function() {
                // localStorage에서 로그인 정보 제거
                localStorage.removeItem('accessToken');
                localStorage.removeItem('userId');
                localStorage.removeItem('userEmail');
                localStorage.removeItem('userName');
                localStorage.removeItem('refreshToken');
                localStorage.removeItem('tokenExpiresAt');
                
                // 로그아웃 상태 이벤트 발생
                window.dispatchEvent(new CustomEvent('nativeLogout'));
                
                console.log('Native logout state sent to web');
            })();
            """
            
            webView.evaluateJavaScript(logoutScript) { result, error in
                if let error = error {
                    print("checkLoginStatus logout error: \(error)")
                }
            }
        }
    }
    
    // MARK: - 카드 추가 관련 메서드
    func handleCardAddRequest(webView: WKWebView, completion: @escaping (Bool, String?) -> Void) {
        print("handleCardAddRequest called")
        
        // 로그인 상태 확인
        guard isLoggedIn, let _ = userInfo else {
            print("User not logged in, cannot add card")
            completion(false, "로그인이 필요합니다.")
            return
        }
        
        // 카드 추가 화면을 네이티브로 표시
        DispatchQueue.main.async { [weak self] in
            // 여기서 카드 추가 화면을 표시하는 로직을 구현
            // 예: 카드 추가 모달 또는 새로운 화면으로 이동
            self?.showCardAddScreen { success, errorMessage in
                completion(success, errorMessage)
            }
        }
    }
    
    private func showCardAddScreen(completion: @escaping (Bool, String?) -> Void) {
        // 실제 카드 추가 화면을 표시하기 위해 NotificationCenter 사용
        // ContentView에서 이 알림을 받아서 CardAddView를 표시
        NotificationCenter.default.post(
            name: NSNotification.Name("ShowCardAddView"),
            object: nil,
            userInfo: ["completion": completion]
        )
    }
    
    // MARK: - 카드 추가 완료 후 웹뷰에 알림
    func notifyCardAddComplete(webView: WKWebView, success: Bool, errorMessage: String? = nil) {
        let script = """
        (function() {
            window.dispatchEvent(new CustomEvent('cardAddComplete', {
                detail: {
                    success: \(success),
                    errorMessage: '\(errorMessage ?? "")'
                }
            }));
            
            console.log('Card add complete notification sent to web');
        })();
        """
        
        webView.evaluateJavaScript(script) { result, error in
            if let error = error {
                print("notifyCardAddComplete error: \(error)")
            } else {
                print("notifyCardAddComplete success")
            }
        }
    }
} 
