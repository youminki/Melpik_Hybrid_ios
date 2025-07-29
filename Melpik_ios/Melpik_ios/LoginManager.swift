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
    static let shared = LoginManager()
    @Published var isLoggedIn = false
    @Published var isLoading = true
    @Published var userInfo: UserInfo?
    
    private let keychainService = "com.melpik.app.login"
    private let userDefaults = UserDefaults.standard
    private var isInitializing = false
    private var tokenRefreshTimer: Timer?
    
    init() {
        loadLoginState()
        // 인스타그램 방식 로그인 상태 확인
        initializeInstagramLoginStatus()
    }
    
    deinit {
        print("LoginManager deinit")
        tokenRefreshTimer?.invalidate()
    }
    
    // MARK: - 토큰 자동 갱신 관리
    @MainActor
    private func setupTokenRefreshTimer() {
        tokenRefreshTimer?.invalidate()
        
        guard let userInfo = userInfo,
              let expiresAt = userInfo.expiresAt else { return }
        
        // 토큰 만료 5분 전에 갱신
        let refreshTime = expiresAt.addingTimeInterval(-300)
        let timeUntilRefresh = refreshTime.timeIntervalSinceNow
        
        if timeUntilRefresh > 0 {
            tokenRefreshTimer = Timer.scheduledTimer(withTimeInterval: timeUntilRefresh, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshAccessToken()
                }
            }
            print("Token refresh scheduled for: \(refreshTime)")
        } else {
            // 이미 만료되었거나 곧 만료될 예정이면 즉시 갱신
            Task { @MainActor in
                refreshAccessToken()
            }
        }
    }
    
    @MainActor
    private func refreshAccessToken() {
        guard let refreshToken = userDefaults.string(forKey: "refreshToken") else {
            print("❌ No refresh token available")
            logout()
            return
        }
        
        print("🔄 Refreshing access token...")
        
        // 실제 서버 API 호출 (예시)
        refreshTokenAPI(refreshToken: refreshToken) { [weak self] result in
            Task { @MainActor in
                switch result {
                case .success(let newTokenData):
                    self?.updateTokenWithNewData(newTokenData)
                case .failure(let error):
                    print("❌ Token refresh failed: \(error)")
                    self?.logout()
                }
            }
        }
    }
    
    private func refreshTokenAPI(refreshToken: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // 실제 구현에서는 서버 API 호출
        // 여기서는 예시로 성공 응답을 시뮬레이션
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let newTokenData: [String: Any] = [
                "token": "new_access_token_\(Date().timeIntervalSince1970)",
                "refreshToken": "new_refresh_token_\(Date().timeIntervalSince1970)",
                "expiresAt": Date().addingTimeInterval(3600).ISO8601String()
            ]
            completion(.success(newTokenData))
        }
    }
    
    @MainActor
    private func updateTokenWithNewData(_ tokenData: [String: Any]) {
        guard let newToken = tokenData["token"] as? String,
              let newRefreshToken = tokenData["refreshToken"] as? String,
              let expiresAtString = tokenData["expiresAt"] as? String else {
            print("❌ Invalid token data")
            logout()
            return
        }
        
        let formatter = ISO8601DateFormatter()
        let expiresAt = formatter.date(from: expiresAtString)
        
        // 토큰 업데이트
        userDefaults.set(newToken, forKey: "accessToken")
        userDefaults.set(newRefreshToken, forKey: "refreshToken")
        if let expiresAt = expiresAt {
            userDefaults.set(expiresAt, forKey: "tokenExpiresAt")
        }
        
        // UserInfo 업데이트
        if let userInfo = self.userInfo {
            let updatedUserInfo = UserInfo(
                id: userInfo.id,
                email: userInfo.email,
                name: userInfo.name,
                token: newToken,
                refreshToken: newRefreshToken,
                expiresAt: expiresAt
            )
            self.userInfo = updatedUserInfo
        }
        
        // 웹뷰에 새로운 토큰 전달
        NotificationCenter.default.post(
            name: NSNotification.Name("TokenRefreshed"),
            object: nil,
            userInfo: ["tokenData": tokenData]
        )
        
        // 다음 갱신 타이머 설정
        setupTokenRefreshTimer()
        
        print("✅ Token refreshed successfully")
    }
    
    // MARK: - 로그인 상태 저장
    @MainActor
    func saveLoginState(userInfo: UserInfo) {
        guard !isInitializing else { return }
        print("[saveLoginState] 호출됨 - userId: \(userInfo.id), accessToken: \(userInfo.token), refreshToken: \(userInfo.refreshToken ?? "nil")")
        
        print("saveLoginState called, userInfo: \(userInfo)")
        
        // UserDefaults에 기본 정보 저장
        userDefaults.set(true, forKey: "isLoggedIn")
        userDefaults.set(userInfo.id, forKey: "userId")
        userDefaults.set(userInfo.email, forKey: "userEmail")
        userDefaults.set(userInfo.name, forKey: "userName")
        userDefaults.set(userInfo.token, forKey: "accessToken")
        saveToKeychain(key: "accessToken", value: userInfo.token)
        if let refreshToken = userInfo.refreshToken {
            userDefaults.set(refreshToken, forKey: "refreshToken")
            saveToKeychain(key: "refreshToken", value: refreshToken)
        }
        if let expiresAt = userInfo.expiresAt {
            userDefaults.set(expiresAt, forKey: "tokenExpiresAt")
        }
        
        // 자동 로그인 설정 제거됨
        userDefaults.synchronize()
        
        // @Published 프로퍼티 업데이트를 메인 스레드에서 안전하게 처리
        Task { @MainActor in
            self.userInfo = userInfo
            self.isLoggedIn = true
        }
        
        // 토큰 자동 갱신 타이머 설정
        setupTokenRefreshTimer()
        
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
        
        // 1. 저장된 토큰 불러오기 (UserDefaults → Keychain 우선 순위)
        var accessToken = userDefaults.string(forKey: "accessToken")
        var refreshToken = userDefaults.string(forKey: "refreshToken")
        let expiresAt = userDefaults.object(forKey: "tokenExpiresAt") as? Date

        // UserDefaults에 없으면 Keychain에서 복원
        if accessToken == nil {
            accessToken = loadFromKeychain(key: "accessToken")
            if let token = accessToken {
                userDefaults.set(token, forKey: "accessToken")
            }
        }
        if refreshToken == nil {
            refreshToken = loadFromKeychain(key: "refreshToken")
            if let token = refreshToken {
                userDefaults.set(token, forKey: "refreshToken")
            }
        }

        // UserDefaults가 비어있으면 Keychain 값으로 동기화
        if userDefaults.string(forKey: "userId") == nil, let token = accessToken {
            userDefaults.set(true, forKey: "isLoggedIn")
            // 기타 정보도 Keychain에서 복원 가능하다면 복원 (여기선 id/email/name은 Keychain에 없으므로 생략)
            print("UserDefaults가 비어있어 Keychain 값으로 동기화")
        }
        // 2. accessToken 또는 refreshToken이 하나라도 있으면 로그아웃 호출 금지
        if let token = accessToken, !token.isEmpty {
            print("✅ accessToken 존재, 자동 로그인 상태로 시작")
            // UserDefaults에 사용자 정보가 없으면 기본값으로라도 UserInfo 생성
            let userId = userDefaults.string(forKey: "userId") ?? "unknown"
            let userEmail = userDefaults.string(forKey: "userEmail") ?? ""
            let userName = userDefaults.string(forKey: "userName") ?? ""
            let exp = expiresAt
            let userInfo = UserInfo(
                id: userId,
                email: userEmail,
                name: userName,
                token: token,
                refreshToken: refreshToken,
                expiresAt: exp
            )
            self.userInfo = userInfo
            self.isLoggedIn = true
            setupTokenRefreshTimer()
        } else if let refresh = refreshToken, !refresh.isEmpty {
            print("✅ refreshToken 존재, accessToken 갱신 시도")
            refreshAccessToken()
        } else {
            // accessToken, refreshToken 모두 없을 때만 로그아웃
            print("❌ 토큰 없음, 로그아웃 상태로 시작")
            logout()
        }

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
        print("[logout] 호출됨 - userId: \(userInfo?.id ?? "nil"), accessToken: \(loadFromKeychain(key: "accessToken") ?? "nil"), refreshToken: \(loadFromKeychain(key: "refreshToken") ?? "nil")")
        print("=== logout called ===")
        
        // 토큰 갱신 타이머 중지
        tokenRefreshTimer?.invalidate()
        tokenRefreshTimer = nil
        
        // UserDefaults에서 로그인 정보 제거
        userDefaults.removeObject(forKey: "isLoggedIn")
        userDefaults.removeObject(forKey: "userId")
        userDefaults.removeObject(forKey: "userEmail")
        userDefaults.removeObject(forKey: "userName")
        userDefaults.removeObject(forKey: "tokenExpiresAt")
        userDefaults.removeObject(forKey: "accessToken")
        userDefaults.removeObject(forKey: "refreshToken")
        // 자동 로그인 관련 설정 제거됨
        
        // Keychain에서 토큰 제거
        deleteFromKeychain(key: "accessToken")
        deleteFromKeychain(key: "refreshToken")
        
        // @Published 프로퍼티 업데이트를 메인 스레드에서 안전하게 처리
        Task { @MainActor in
            self.isLoggedIn = false
            self.userInfo = nil
        }
        
        // 웹뷰에 로그아웃 알림
        NotificationCenter.default.post(
            name: NSNotification.Name("LogoutRequested"),
            object: nil
        )
        
        print("✅ Logout completed")
    }
    
    // MARK: - 로그인 상태 유지 설정
    func setKeepLogin(enabled: Bool) {
        print("=== setKeepLogin called with enabled: \(enabled) ===")
        userDefaults.set(enabled, forKey: "keepLogin")
        userDefaults.synchronize()
        print("Keep login setting saved: \(enabled)")
    }
    
    // MARK: - 인스타그램 방식 로그인 상태 유지 기능
    
    /// 인스타그램 방식 로그인 상태 유지 설정 저장
    func saveKeepLoginSetting(_ keepLogin: Bool) {
        print("=== saveKeepLoginSetting called with keepLogin: \(keepLogin) ===")
        userDefaults.set(keepLogin, forKey: "keepLogin")
        userDefaults.synchronize()
        print("인스타그램 방식 로그인 상태 유지 설정 저장: \(keepLogin)")
    }
    
    /// 인스타그램 방식 로그인 상태 유지 설정 가져오기
    func getKeepLoginSetting() -> Bool {
        let setting = userDefaults.bool(forKey: "keepLogin")
        print("인스타그램 방식 로그인 상태 유지 설정 조회: \(setting)")
        return setting
    }
    
    /// 인스타그램 방식 로그인 상태 유지 설정 변경 시 웹뷰에 알림
    func updateKeepLoginSetting(_ keepLogin: Bool) {
        print("=== updateKeepLoginSetting called with keepLogin: \(keepLogin) ===")
        saveKeepLoginSetting(keepLogin)
        
        // 웹뷰에 설정 변경 알림
        NotificationCenter.default.post(
            name: NSNotification.Name("KeepLoginSettingChanged"),
            object: nil,
            userInfo: ["keepLogin": keepLogin]
        )
        
        print("인스타그램 방식 로그인 상태 유지 설정 변경 완료")
    }
    
    /// 인스타그램 방식 로그인 상태 유지 토큰 저장
    func saveTokensWithKeepLogin(accessToken: String, refreshToken: String? = nil, keepLogin: Bool = false) {
        print("=== saveTokensWithKeepLogin called ===")
        print("keepLogin: \(keepLogin)")
        
        // 로그인 상태 유지 설정 저장
        saveKeepLoginSetting(keepLogin)
        
        if keepLogin {
            // 로그인 상태 유지: UserDefaults에 저장 (영구 보관)
            userDefaults.set(accessToken, forKey: "accessToken")
            saveToKeychain(key: "accessToken", value: accessToken)
            if let refreshToken = refreshToken {
                userDefaults.set(refreshToken, forKey: "refreshToken")
                saveToKeychain(key: "refreshToken", value: refreshToken)
            }
            print("UserDefaults에 토큰 저장됨 (로그인 상태 유지)")
        } else {
            // 세션 유지: UserDefaults에 저장하되 앱 종료 시 삭제될 수 있음
            userDefaults.set(accessToken, forKey: "accessToken")
            saveToKeychain(key: "accessToken", value: accessToken)
            if let refreshToken = refreshToken {
                userDefaults.set(refreshToken, forKey: "refreshToken")
                saveToKeychain(key: "refreshToken", value: refreshToken)
            }
            print("UserDefaults에 토큰 저장됨 (세션 유지)")
        }
        
        // Keychain에도 저장 (보안 강화)
        saveToKeychain(key: "accessToken", value: accessToken)
        if let refreshToken = refreshToken {
            saveToKeychain(key: "refreshToken", value: refreshToken)
        }
        
        // 로그인 상태 설정
        userDefaults.set(true, forKey: "isLoggedIn")
        userDefaults.synchronize()
        
        print("인스타그램 방식 토큰 저장 완료")
    }
    
    /// 인스타그램 방식 로그인 상태 확인
    func checkInstagramLoginStatus() -> Bool {
        print("=== checkInstagramLoginStatus called ===")
        
        // UserDefaults에서 토큰 확인
        let accessToken = userDefaults.string(forKey: "accessToken")
        let isLoggedIn = userDefaults.bool(forKey: "isLoggedIn")
        
        print("UserDefaults 상태:")
        print("- isLoggedIn: \(isLoggedIn)")
        print("- accessToken: \(accessToken ?? "nil")")
        
        guard let token = accessToken, !token.isEmpty, isLoggedIn else {
            print("토큰이 없거나 로그인 상태가 아님")
            return false
        }
        
        // 토큰 유효성 검사 (JWT 토큰인 경우)
        if token.contains(".") {
            do {
                let parts = token.components(separatedBy: ".")
                if parts.count == 3 {
                    let payload = parts[1]
                    let data = Data(base64Encoded: payload + String(repeating: "=", count: (4 - payload.count % 4) % 4)) ?? Data()
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    if let exp = json?["exp"] as? TimeInterval {
                        let currentTime = Date().timeIntervalSince1970
                        
                        if exp < currentTime {
                            print("토큰이 만료되어 로그인 상태 유지 불가")
                            logout()
                            return false
                        }
                        
                        print("토큰 유효성 확인 완료")
                    }
                }
            } catch {
                print("토큰 파싱 오류: \(error)")
                // 파싱 오류가 있어도 토큰이 있으면 유효하다고 간주
            }
        }
        
        print("인스타그램 방식 로그인 상태 유지 가능")
        return true
    }
    
    /// 인스타그램 방식 로그인 상태 유지 초기화
    func initializeInstagramLoginStatus() {
        print("=== initializeInstagramLoginStatus called ===")
        
        let isLoggedIn = checkInstagramLoginStatus()
        
        if isLoggedIn {
            // 로그인 상태 복원
            let userId = userDefaults.string(forKey: "userId") ?? ""
            let userEmail = userDefaults.string(forKey: "userEmail") ?? ""
            let userName = userDefaults.string(forKey: "userName") ?? ""
            let accessToken = userDefaults.string(forKey: "accessToken") ?? ""
            let refreshToken = userDefaults.string(forKey: "refreshToken")
            let expiresAt = userDefaults.object(forKey: "tokenExpiresAt") as? Date
            
            let userInfo = UserInfo(
                id: userId,
                email: userEmail,
                name: userName,
                token: accessToken,
                refreshToken: refreshToken,
                expiresAt: expiresAt
            )
            
            Task { @MainActor in
                self.userInfo = userInfo
                self.isLoggedIn = true
            }
            
            // 토큰 갱신 타이머 설정
            setupTokenRefreshTimer()
            
            print("인스타그램 방식 로그인 상태 복원 완료")
        } else {
            print("인스타그램 방식 로그인 상태 없음")
        }
    }
    
    // MARK: - 자동 로그인 설정 (비활성화됨)
    func setAutoLogin(enabled: Bool) {
        print("=== setAutoLogin called with enabled: \(enabled) ===")
        print("Auto login is disabled - setting ignored")
        // 자동 로그인 기능이 비활성화되어 있으므로 설정을 무시
    }
    
    // MARK: - 자동 로그인 설정 (제거됨)
    // 자동 로그인 기능이 완전히 제거되었습니다.
    
    // MARK: - Keychain 관리
    private func saveToKeychain(key: String, value: String) {
        print("[saveToKeychain] key: \(key), value: \(value)")
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock // 영구 저장
        ]
        
        // 기존 항목 삭제
        SecItemDelete(query as CFDictionary)
        
        // 새 항목 추가
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            print("Keychain 저장 성공: \(key)")
        } else {
            print("Keychain 저장 실패: \(key), status: \(status)")
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
            print("Keychain 복원 성공: \(key), value: \(string)")
            return string
        } else {
            print("Keychain 복원 실패: \(key), status: \(status)")
            return nil
        }
    }
    
    private func deleteFromKeychain(key: String) {
        print("[deleteFromKeychain] key: \(key)")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - 생체 인증을 통한 로그인 (제거됨)
    // 생체 인증 기능이 완전히 제거되었습니다.
    
    // MARK: - 웹에서 받은 로그인 데이터 처리
    func saveLoginInfo(_ loginData: [String: Any]) {
        print("=== saveLoginInfo called ===")
        print("Received login data: \(loginData)")
        
        // keepLogin 설정 확인
        let keepLogin = loginData["keepLogin"] as? Bool ?? false
        print("Keep login setting from web: \(keepLogin)")
        
        // 인스타그램 방식 토큰 저장
        if let token = loginData["token"] as? String {
            let refreshToken = loginData["refreshToken"] as? String
            saveTokensWithKeepLogin(accessToken: token, refreshToken: refreshToken, keepLogin: keepLogin)
        }
        
        // UserDefaults를 사용하여 토큰 저장
        if let token = loginData["token"] as? String {
            userDefaults.set(token, forKey: "accessToken")
            saveToKeychain(key: "accessToken", value: token)
            print("Saved accessToken to UserDefaults: \(token)")
        } else {
            print("❌ No token found in login data")
        }
        
        if let refreshToken = loginData["refreshToken"] as? String {
            userDefaults.set(refreshToken, forKey: "refreshToken")
            saveToKeychain(key: "refreshToken", value: refreshToken)
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
        
        // 로그인 상태 유지 설정 처리
        if let keepLogin = loginData["keepLogin"] as? Bool {
            setKeepLogin(enabled: keepLogin)
            print("Keep login setting: \(keepLogin)")
        }
        
        // 로그인 상태 저장
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
        
        // 웹뷰에 로그인 정보 전달 (인스타그램 방식)
        NotificationCenter.default.post(
            name: NSNotification.Name("LoginInfoReceived"),
            object: nil,
            userInfo: [
                "isLoggedIn": true,
                "userInfo": userInfo,
                "keepLogin": keepLogin
            ]
        )
        
        // 앱에서 로그인 성공 시 웹뷰에 즉시 전달
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: NSNotification.Name("ForceSendLoginInfo"),
                object: nil
            )
        }
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
        let keepLogin = getKeepLoginSetting()
        
        print("=== sendLoginInfoToWeb called ===")
        print("keepLogin setting: \(keepLogin)")
        
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
                localStorage.setItem('keepLoginSetting', '\(keepLogin)');
                
                // sessionStorage에도 저장 (세션 유지)
                sessionStorage.setItem('accessToken', '\(accessToken)');
                sessionStorage.setItem('userId', '\(userId)');
                sessionStorage.setItem('userEmail', '\(userEmail)');
                sessionStorage.setItem('userName', '\(userName)');
                sessionStorage.setItem('refreshToken', '\(refreshToken)');
                sessionStorage.setItem('tokenExpiresAt', '\(expiresAt)');
                sessionStorage.setItem('isLoggedIn', 'true');
                sessionStorage.setItem('keepLoginSetting', '\(keepLogin)');
                
                // 쿠키에도 저장 (서버에서 인식)
                document.cookie = 'accessToken=\(accessToken); path=/; max-age=86400';
                document.cookie = 'userId=\(userId); path=/; max-age=86400';
                document.cookie = 'userEmail=\(userEmail); path=/; max-age=86400';
                document.cookie = 'isLoggedIn=true; path=/; max-age=86400';
                document.cookie = 'keepLoginSetting=\(keepLogin); path=/; max-age=86400';
                
                // 전역 변수로도 설정
                window.accessToken = '\(accessToken)';
                window.userId = '\(userId)';
                window.userEmail = '\(userEmail)';
                window.userName = '\(userName)';
                window.isLoggedIn = true;
                window.keepLogin = \(keepLogin);
                
                // 로그인 이벤트 발생
                window.dispatchEvent(new CustomEvent('loginSuccess', {
                    detail: {
                        isLoggedIn: true,
                        keepLogin: \(keepLogin),
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
                console.log('Keep login setting: \(keepLogin)');
                
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
                print("✅ Keep login setting sent: \(keepLogin)")
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
