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
    func saveLoginState(userInfo: UserInfo) {
        print("saveLoginState called, userInfo: \(userInfo)")
        self.userInfo = userInfo
        self.isLoggedIn = true
        
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
        print("[saveLoginState] userId:", userDefaults.string(forKey: "userId"))
        print("[saveLoginState] userEmail:", userDefaults.string(forKey: "userEmail"))
        print("[saveLoginState] userName:", userDefaults.string(forKey: "userName"))
        print("[saveLoginState] expiresAt:", userDefaults.object(forKey: "tokenExpiresAt"))
        print("[saveLoginState] accessToken:", loadFromKeychain(key: "accessToken"))
        print("[saveLoginState] refreshToken:", loadFromKeychain(key: "refreshToken"))
    }
    
    // MARK: - 로그인 상태 복원
    func loadLoginState() {
        print("loadLoginState called")
        isLoading = true
        
        // 자동 로그인이 활성화되어 있는지 확인
        let autoLoginEnabled = userDefaults.bool(forKey: "autoLoginEnabled")
        let userId = userDefaults.string(forKey: "userId")
        let userEmail = userDefaults.string(forKey: "userEmail")
        let userName = userDefaults.string(forKey: "userName")
        let expiresAt = userDefaults.object(forKey: "tokenExpiresAt")
        let accessToken = loadFromKeychain(key: "accessToken")
        let refreshToken = loadFromKeychain(key: "refreshToken")
        print("[loadLoginState] autoLoginEnabled:", autoLoginEnabled)
        print("[loadLoginState] userId:", userId)
        print("[loadLoginState] userEmail:", userEmail)
        print("[loadLoginState] userName:", userName)
        print("[loadLoginState] expiresAt:", expiresAt)
        print("[loadLoginState] accessToken:", accessToken)
        print("[loadLoginState] refreshToken:", refreshToken)
        
        if autoLoginEnabled {
            // Keychain에서 토큰 복원
            if let accessToken = loadFromKeychain(key: "accessToken") {
                let userId = userDefaults.string(forKey: "userId") ?? ""
                let userEmail = userDefaults.string(forKey: "userEmail") ?? ""
                let userName = userDefaults.string(forKey: "userName") ?? ""
                let refreshToken = loadFromKeychain(key: "refreshToken")
                let expiresAt = userDefaults.object(forKey: "tokenExpiresAt") as? Date
                
                let userInfo = UserInfo(
                    id: userId,
                    email: userEmail,
                    name: userName,
                    token: accessToken,
                    refreshToken: refreshToken,
                    expiresAt: expiresAt
                )
                
                // 토큰이 만료되지 않았는지 확인
                if !userInfo.isTokenExpired {
                    self.userInfo = userInfo
                    self.isLoggedIn = true
                } else if let refreshToken = refreshToken {
                    // 토큰이 만료되었지만 refresh token이 있으면 갱신 시도
                    refreshAccessToken(refreshToken: refreshToken)
                } else {
                    // 토큰이 만료되고 refresh token도 없으면 로그아웃
                    logout()
                }
            } else {
                logout()
            }
        } else {
            logout()
        }
        
        isLoading = false
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
        isLoggedIn = false
        userInfo = nil
        
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
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    // 생체 인증 성공 시 저장된 로그인 정보 복원
                    self.loadLoginState()
                }
                completion(success)
            }
        }
    }
    
    // MARK: - 웹에서 받은 로그인 데이터 처리
    func saveLoginInfo(_ loginData: [String: Any]) {
        print("saveLoginInfo called with data: \(loginData)")
        
        // UserDefaults를 사용하여 토큰 저장
        if let token = loginData["token"] as? String {
            userDefaults.set(token, forKey: "accessToken")
        }
        if let refreshToken = loginData["refreshToken"] as? String {
            userDefaults.set(refreshToken, forKey: "refreshToken")
        }
        if let email = loginData["email"] as? String {
            userDefaults.set(email, forKey: "userEmail")
        }
        if let id = loginData["id"] as? String {
            userDefaults.set(id, forKey: "userId")
        }
        if let name = loginData["name"] as? String {
            userDefaults.set(name, forKey: "userName")
        }
        
        // 자동 로그인 활성화
        userDefaults.set(true, forKey: "autoLoginEnabled")
        userDefaults.synchronize()
        
        // UserInfo 객체 생성 및 저장
        guard let id = loginData["id"] as? String,
              let email = loginData["email"] as? String,
              let name = loginData["name"] as? String,
              let token = loginData["token"] as? String else {
            print("Invalid login data received")
            return
        }
        
        let refreshToken = loginData["refreshToken"] as? String
        let expiresAtString = loginData["expiresAt"] as? String
        
        var expiresAt: Date?
        if let expiresAtString = expiresAtString {
            let formatter = ISO8601DateFormatter()
            expiresAt = formatter.date(from: expiresAtString)
        }
        
        let userInfo = UserInfo(
            id: id,
            email: email,
            name: name,
            token: token,
            refreshToken: refreshToken,
            expiresAt: expiresAt
        )
        
        saveLoginState(userInfo: userInfo)
        
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
            
            let script = """
                window.dispatchEvent(new CustomEvent('loginInfoReceived', {
                    detail: \(jsonString)
                }));
            """
            
            // ContentView에서 웹뷰 참조를 받아서 실행하도록 수정 필요
            print("Login info ready to send to web: \(jsonString)")
        }
        
        print("Login info saved successfully")
        print("UserDefaults - accessToken: \(userDefaults.string(forKey: "accessToken") ?? "nil")")
        print("UserDefaults - refreshToken: \(userDefaults.string(forKey: "refreshToken") ?? "nil")")
        print("UserDefaults - userEmail: \(userDefaults.string(forKey: "userEmail") ?? "nil")")
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
    
    // MARK: - 앱 시작 시 토큰 확인
    func checkLoginStatus(webView: WKWebView? = nil) {
        print("checkLoginStatus called")
        
        if let token = userDefaults.string(forKey: "accessToken") {
            print("Found saved token: \(token)")
            
            let loginInfo = [
                "type": "loginInfoReceived",
                "detail": [
                    "isLoggedIn": true,
                    "userInfo": [
                        "token": token,
                        "refreshToken": userDefaults.string(forKey: "refreshToken") ?? "",
                        "email": userDefaults.string(forKey: "userEmail") ?? "",
                        "id": userDefaults.string(forKey: "userId") ?? "",
                        "name": userDefaults.string(forKey: "userName") ?? ""
                    ]
                ]
            ] as [String : Any]
            
            // JSON으로 변환
            if let jsonData = try? JSONSerialization.data(withJSONObject: loginInfo),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                
                let script = """
                    window.dispatchEvent(new CustomEvent('loginInfoReceived', {
                        detail: \(jsonString)
                    }));
                """
                
                if let webView = webView {
                    webView.evaluateJavaScript(script) { result, error in
                        if let error = error {
                            print("Error sending login info to web: \(error)")
                        } else {
                            print("Login info sent to web successfully")
                        }
                    }
                } else {
                    print("Login info ready to send: \(jsonString)")
                }
            }
        } else {
            print("No saved token found")
        }
    }
    
    // MARK: - 웹뷰에서 로그인 정보 전달 (기존 메서드 수정)
    func sendLoginInfoToWeb(webView: WKWebView? = nil) {
        let loginInfo = getLoginInfo()
        let script = "window.dispatchEvent(new CustomEvent('loginInfoReceived', { detail: \(loginInfo) }));"
        
        if let webView = webView {
            webView.evaluateJavaScript(script)
        } else {
            print("Login info: \(loginInfo)")
        }
    }
} 
