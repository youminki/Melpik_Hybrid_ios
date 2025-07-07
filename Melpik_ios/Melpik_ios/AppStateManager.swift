//
//  AppStateManager.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI
import UserNotifications
import LocalAuthentication
import Security
import Foundation
import WebKit

@MainActor
class AppStateManager: ObservableObject {
    @Published var pushToken: String?
    @Published var isBiometricAvailable = false
    
    let userDefaults = UserDefaults.standard
    let loginManager = LoginManager()
    
    deinit {
        print("AppStateManager deinit")
    }
    
    func requestPushNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                    print("Push notification permission granted")
                } else {
                    print("Push notification permission denied")
                }
                
                if let error = error {
                    print("Push notification permission error: \(error)")
                }
            }
        }
    }
    
    func setupBiometricAuth() {
        // 생체 인증 비활성화
        isBiometricAvailable = false
        print("Biometric authentication disabled")
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        // 생체 인증 비활성화 - 항상 실패 반환
        DispatchQueue.main.async {
            print("Biometric authentication disabled - always returns false")
            completion(false)
        }
    }
    
    func getAppInfo() -> String {
        let bundle = Bundle.main
        let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = bundle.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        
        return """
        {
            "version": "\(version)",
            "build": "\(build)",
            "platform": "iOS",
            "deviceModel": "\(UIDevice.current.model)",
            "systemVersion": "\(UIDevice.current.systemVersion)"
        }
        """
    }
    
    private func loadLoginState() {
        print("loadLoginState called")
        let autoLoginEnabled = userDefaults.bool(forKey: "autoLoginEnabled")
        let userId = userDefaults.string(forKey: "userId") ?? "nil"
        let userEmail = userDefaults.string(forKey: "userEmail") ?? "nil"
        let userName = userDefaults.string(forKey: "userName") ?? "nil"
        let expiresAt = userDefaults.object(forKey: "tokenExpiresAt")
        let accessToken = loadFromKeychain(key: "accessToken") ?? "nil"
        let refreshToken = loadFromKeychain(key: "refreshToken") ?? "nil"
        print("autoLoginEnabled:", autoLoginEnabled)
        print("userId:", userId)
        print("userEmail:", userEmail)
        print("userName:", userName)
        print("expiresAt:", expiresAt ?? "nil")
        print("accessToken:", accessToken)
        print("refreshToken:", refreshToken)
    }
    
    func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.melpik.app.login",
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
    
    func saveLoginState(userInfo: UserInfo) {
        print("saveLoginState called, userInfo: \(userInfo)")
        print("[saveLoginState] userId: \(userInfo.id)")
        print("[saveLoginState] accessToken: \(userInfo.token)")
        print("[saveLoginState] isTokenExpired: \(userInfo.isTokenExpired)")
    }
}

// WKScriptMessageHandler는 WebView의 Coordinator에서 구현하는 것이 좋습니다.
class WebViewCoordinator: NSObject, WKScriptMessageHandler {
    let loginManager: LoginManager

    init(loginManager: LoginManager) {
        self.loginManager = loginManager
        super.init()
    }
    
    deinit {
        print("WebViewCoordinator deinit")
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("WKScriptMessageHandler didReceive: \(message.body)")
        guard let body = message.body as? [String: Any],
              let action = body["action"] as? String else { return }
        
        if action == "saveLoginInfo" {
            if let loginData = body["loginData"] as? [String: Any] {
                loginManager.saveLoginInfo(loginData)
            }
        }
    }
} 
