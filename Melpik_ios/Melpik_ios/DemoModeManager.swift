//
//  DemoModeManager.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI
import Foundation

@MainActor
class DemoModeManager: ObservableObject {
    @Published var isDemoMode = false
    @Published var showingDemoLogin = false
    @Published var demoLoginError = ""
    @Published var isDemoLoggedIn = false
    
    private let userDefaults = UserDefaults.standard
    
    // Demo account credentials for App Store review
    private let demoCredentials = DemoCredentials(
        username: "dbalsrl7647@naver.com",
        password: "qwer1234!",
        email: "dbalsrl7647@naver.com",
        name: "Demo User"
    )
    
    init() {
        setupDemoMode()
    }
    
    // MARK: - Demo Mode Setup
    private func setupDemoMode() {
        #if DEBUG
        isDemoMode = true
        #else
        // Check if demo mode is enabled for App Store review
        isDemoMode = userDefaults.bool(forKey: "demo_mode_enabled")
        #endif
    }
    
    // MARK: - Demo Mode Control
    func enableDemoMode() {
        isDemoMode = true
        userDefaults.set(true, forKey: "demo_mode_enabled")
    }
    
    func disableDemoMode() {
        isDemoMode = false
        userDefaults.set(false, forKey: "demo_mode_enabled")
        isDemoLoggedIn = false
    }
    
    func showDemoLogin() {
        showingDemoLogin = true
    }
    
    // MARK: - Demo Login
    func attemptDemoLogin(username: String, password: String) -> Bool {
        print("Demo 로그인 시도: username=\(username), password=\(password)")
        if username == demoCredentials.username && password == demoCredentials.password {
            isDemoLoggedIn = true
            demoLoginError = ""
            showingDemoLogin = false
            // 데모 계정 정보 UserDefaults/Keychain에 저장
            let demoUser = getDemoUserData()
            let userInfo = UserInfo(
                id: demoUser.id,
                email: demoUser.email,
                name: demoUser.name,
                token: "demo_access_token_12345",
                refreshToken: "demo_refresh_token_67890",
                expiresAt: Date().addingTimeInterval(60*60*24*30) // 30일 후 만료
            )
            print("Demo 로그인: saveLoginState 호출")
            LoginManager.shared.saveLoginState(userInfo: userInfo)
            return true
        } else {
            demoLoginError = "잘못된 사용자명 또는 비밀번호입니다."
            return false
        }
    }
    
    func logoutFromDemo() {
        isDemoLoggedIn = false
    }
    
    // MARK: - Demo Account Info
    func getDemoAccountInfo() -> String {
        return """
        데모 계정 정보:
        
        사용자명: \(demoCredentials.username)
        비밀번호: \(demoCredentials.password)
        이메일: \(demoCredentials.email)
        이름: \(demoCredentials.name)
        
        이 계정으로 앱의 모든 기능을 테스트할 수 있습니다.
        """
    }
    
    func getDemoCredentials() -> DemoCredentials {
        return demoCredentials
    }
    
    // MARK: - Demo Data
    func getDemoUserData() -> DemoUserData {
        return DemoUserData(
            id: "demo_user_id",
            email: demoCredentials.email,
            name: demoCredentials.name,
            profileImage: nil,
            joinDate: Date(),
            lastLoginDate: Date(),
            preferences: DemoUserPreferences(
                pushNotifications: true,
                locationServices: true,
                dataCollection: true,
                theme: "light"
            )
        )
    }
    
    // MARK: - Demo Features
    func getDemoFeatures() -> [DemoFeature] {
        return [
            DemoFeature(
                name: "웹뷰 로딩",
                description: "메인 웹사이트 로딩 및 표시",
                isAvailable: true
            ),
            DemoFeature(
                name: "로그인/회원가입",
                description: "사용자 인증 및 계정 관리",
                isAvailable: true
            ),
            DemoFeature(
                name: "푸시 알림",
                description: "앱 내 알림 수신",
                isAvailable: true
            ),
            DemoFeature(
                name: "위치 서비스",
                description: "위치 기반 서비스 이용",
                isAvailable: true
            ),
            DemoFeature(
                name: "카드 추가",
                description: "결제 카드 등록 및 관리",
                isAvailable: true
            ),
            DemoFeature(
                name: "이미지 업로드",
                description: "사진 촬영 및 갤러리 접근",
                isAvailable: true
            ),
            DemoFeature(
                name: "공유 기능",
                description: "콘텐츠 공유 및 Safari 뷰",
                isAvailable: true
            ),
            DemoFeature(
                name: "오프라인 모드",
                description: "네트워크 없이도 기본 기능 이용",
                isAvailable: true
            ),
            DemoFeature(
                name: "성능 모니터링",
                description: "앱 성능 상태 실시간 모니터링",
                isAvailable: true
            ),
            DemoFeature(
                name: "캐시 관리",
                description: "앱 데이터 캐시 관리 및 정리",
                isAvailable: true
            ),
            DemoFeature(
                name: "개인정보 관리",
                description: "개인정보 설정 및 데이터 관리",
                isAvailable: true
            )
        ]
    }
    
    // MARK: - Demo Mode Detection
    func isInAppStoreReviewEnvironment() -> Bool {
        // Check if we're in App Store review environment
        // This can be determined by various factors
        return isDemoMode || userDefaults.bool(forKey: "app_store_review_mode")
    }
    
    func setAppStoreReviewMode(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: "app_store_review_mode")
        if enabled {
            enableDemoMode()
        }
    }
}

// MARK: - Supporting Models
struct DemoCredentials {
    let username: String
    let password: String
    let email: String
    let name: String
}

struct DemoUserData {
    let id: String
    let email: String
    let name: String
    let profileImage: String?
    let joinDate: Date
    let lastLoginDate: Date
    let preferences: DemoUserPreferences
}

struct DemoUserPreferences {
    let pushNotifications: Bool
    let locationServices: Bool
    let dataCollection: Bool
    let theme: String
}

struct DemoFeature {
    let name: String
    let description: String
    let isAvailable: Bool
}

// MARK: - Demo Login View
struct DemoLoginView: View {
    @ObservedObject var demoManager: DemoModeManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var showingCredentials = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Image("LoadingMelPick")
                        .resizable()
                        .frame(width: 120, height: 54)
                        .cornerRadius(12)
                    
                    Text("데모 모드 로그인")
                        .font(.custom("NanumSquareB", size: 24))
                        .foregroundColor(.primary)
                    
                    Text("App Store 심사를 위한 데모 계정으로 로그인하세요.")
                        .font(.custom("NanumSquareR", size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Login Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("사용자명")
                            .font(.custom("NanumSquareB", size: 16))
                            .foregroundColor(.primary)
                        
                        TextField("사용자명을 입력하세요", text: $username)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("비밀번호")
                            .font(.custom("NanumSquareB", size: 16))
                            .foregroundColor(.primary)
                        
                        SecureField("비밀번호를 입력하세요", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    if !demoManager.demoLoginError.isEmpty {
                        Text(demoManager.demoLoginError)
                            .font(.custom("NanumSquareR", size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button("데모 로그인") {
                        print("Demo 로그인 버튼 클릭됨: username=\(username), password=\(password)")
                        _ = demoManager.attemptDemoLogin(username: username, password: password)
                    }
                    .font(.custom("NanumSquareB", size: 16))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                    .disabled(username.isEmpty || password.isEmpty)
                    
                    Button("데모 계정 정보 보기") {
                        showingCredentials = true
                    }
                    .font(.custom("NanumSquareR", size: 14))
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("데모 로그인")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
        .alert("데모 계정 정보", isPresented: $showingCredentials) {
            Button("확인") { }
        } message: {
            Text(demoManager.getDemoAccountInfo())
        }
    }
}

// MARK: - Demo Features View
struct DemoFeaturesView: View {
    @ObservedObject var demoManager: DemoModeManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("데모 모드 기능") {
                    ForEach(demoManager.getDemoFeatures(), id: \.name) { feature in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(feature.name)
                                    .font(.custom("NanumSquareB", size: 16))
                                    .foregroundColor(.primary)
                                
                                Text(feature.description)
                                    .font(.custom("NanumSquareR", size: 14))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: feature.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(feature.isAvailable ? .green : .red)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section("데모 계정 정보") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("사용자명: \(demoManager.getDemoCredentials().username)")
                        Text("비밀번호: \(demoManager.getDemoCredentials().password)")
                        Text("이메일: \(demoManager.getDemoCredentials().email)")
                        Text("이름: \(demoManager.getDemoCredentials().name)")
                    }
                    .font(.custom("NanumSquareR", size: 14))
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("데모 기능")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("닫기") {
                        dismiss()
                    }
                }
            }
        }
    }
} 