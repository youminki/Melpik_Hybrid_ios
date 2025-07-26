//
//  PrivacyManager.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI
import Foundation

@MainActor
class PrivacyManager: ObservableObject {
    @Published var hasAcceptedPrivacyPolicy = false
    @Published var hasAcceptedDataCollection = false
    @Published var hasAcceptedPushNotifications = false
    @Published var hasAcceptedLocationServices = false
    
    // Optional personal information (not required for core functionality)
    @Published var birthYear: String = ""
    @Published var gender: String = ""
    @Published var region: String = ""
    

    @Published var showingDataCollectionSummary = false
    
    private let userDefaults = UserDefaults.standard
    
    // Demo mode for App Store review
    @Published var isDemoMode = false
    @Published var demoAccountCredentials = DemoAccountCredentials(
        username: "dbalsrl7647@naver.com",
        password: "qwer1234!",
        email: "dbalsrl7647@naver.com",
        name: "Demo User"
    )
    
    init() {
        loadConsentStates()
        setupDemoMode()
    }
    
    // MARK: - Consent Management
    private func loadConsentStates() {
        hasAcceptedPrivacyPolicy = userDefaults.bool(forKey: "privacy_policy_accepted")
        hasAcceptedDataCollection = userDefaults.bool(forKey: "data_collection_accepted")
        hasAcceptedPushNotifications = userDefaults.bool(forKey: "push_notifications_accepted")
        hasAcceptedLocationServices = userDefaults.bool(forKey: "location_services_accepted")
        
        // Load optional personal information
        birthYear = userDefaults.string(forKey: "user_birth_year") ?? ""
        gender = userDefaults.string(forKey: "user_gender") ?? ""
        region = userDefaults.string(forKey: "user_region") ?? ""
    }
    
    func saveConsentStates() {
        userDefaults.set(hasAcceptedPrivacyPolicy, forKey: "privacy_policy_accepted")
        userDefaults.set(hasAcceptedDataCollection, forKey: "data_collection_accepted")
        userDefaults.set(hasAcceptedPushNotifications, forKey: "push_notifications_accepted")
        userDefaults.set(hasAcceptedLocationServices, forKey: "location_services_accepted")
        
        // Save optional personal information
        userDefaults.set(birthYear, forKey: "user_birth_year")
        userDefaults.set(gender, forKey: "user_gender")
        userDefaults.set(region, forKey: "user_region")
    }
    
    // MARK: - Demo Mode Setup
    private func setupDemoMode() {
        // Check if we're in App Store review environment
        #if DEBUG
        isDemoMode = true
        #else
        // In production, check for demo mode flag
        isDemoMode = userDefaults.bool(forKey: "demo_mode_enabled")
        #endif
        
        if isDemoMode {
            setupDemoAccount()
        }
    }
    
    private func setupDemoAccount() {
        demoAccountCredentials = DemoAccountCredentials(
            username: "dbalsrl7647@naver.com",
            password: "qwer1234!",
            email: "dbalsrl7647@naver.com",
            name: "Demo User"
        )
    }
    
    func enableDemoMode() {
        isDemoMode = true
        userDefaults.set(true, forKey: "demo_mode_enabled")
        setupDemoAccount()
    }
    
    func disableDemoMode() {
        isDemoMode = false
        userDefaults.set(false, forKey: "demo_mode_enabled")
    }
    
    // MARK: - Privacy Consent
    func requiresPrivacyConsent() -> Bool {
        return !hasAcceptedPrivacyPolicy
    }
    

    
    func revokePrivacyPolicy() {
        hasAcceptedPrivacyPolicy = false
        saveConsentStates()
    }
    
    // MARK: - Data Collection Consent
    func acceptDataCollection() {
        hasAcceptedDataCollection = true
        saveConsentStates()
    }
    
    func revokeDataCollection() {
        hasAcceptedDataCollection = false
        saveConsentStates()
    }
    
    func canSendPushNotifications() -> Bool {
        return hasAcceptedPrivacyPolicy && hasAcceptedDataCollection && hasAcceptedPushNotifications
    }
    
    func canUseLocationServices() -> Bool {
        return hasAcceptedPrivacyPolicy && hasAcceptedDataCollection && hasAcceptedLocationServices
    }
    
    // MARK: - Optional Personal Information
    func updateOptionalPersonalInfo(birthYear: String, gender: String, region: String) {
        self.birthYear = birthYear
        self.gender = gender
        self.region = region
        saveConsentStates()
    }
    
    func clearOptionalPersonalInfo() {
        birthYear = ""
        gender = ""
        region = ""
        saveConsentStates()
    }
    
    // MARK: - Data Collection Summary
    func getDataCollectionSummary() -> DataCollectionSummary {
        return DataCollectionSummary(
            requiredData: [
                DataItem(name: "이메일 주소", purpose: "로그인 및 서비스 제공", required: true),
                DataItem(name: "사용자 이름", purpose: "개인화된 서비스 제공", required: true),
                DataItem(name: "디바이스 토큰", purpose: "푸시 알림 전송", required: false),
                DataItem(name: "위치 정보", purpose: "위치 기반 서비스", required: false)
            ],
            optionalData: [
                DataItem(name: "생년월일", purpose: "개인화된 콘텐츠 제공", required: false),
                DataItem(name: "성별", purpose: "서비스 개선 및 통계", required: false),
                DataItem(name: "지역", purpose: "지역별 서비스 제공", required: false)
            ],
            dataRetention: "서비스 이용 기간 동안 보유",
            dataSecurity: "암호화 저장 및 안전한 전송"
        )
    }
    
    func showDataCollectionSummary() {
        showingDataCollectionSummary = true
    }
    
    // MARK: - GDPR Compliance
    func exportUserData() -> UserDataExport {
        return UserDataExport(
            consentData: ConsentData(
                privacyPolicyAccepted: hasAcceptedPrivacyPolicy,
                dataCollectionAccepted: hasAcceptedDataCollection,
                pushNotificationsAccepted: hasAcceptedPushNotifications,
                locationServicesAccepted: hasAcceptedLocationServices
            ),
            optionalPersonalData: OptionalPersonalData(
                birthYear: birthYear,
                gender: gender,
                region: region
            ),
            exportDate: Date()
        )
    }
    
    func deleteUserData() {
        // Clear all user data
        hasAcceptedPrivacyPolicy = false
        hasAcceptedDataCollection = false
        hasAcceptedPushNotifications = false
        hasAcceptedLocationServices = false
        
        // Clear optional personal information
        clearOptionalPersonalInfo()
        
        // Clear demo mode
        disableDemoMode()
        
        // Save cleared states
        saveConsentStates()
        
        // Clear other app data
        userDefaults.removeObject(forKey: "user_id")
        userDefaults.removeObject(forKey: "user_email")
        userDefaults.removeObject(forKey: "user_name")
        userDefaults.removeObject(forKey: "access_token")
        userDefaults.removeObject(forKey: "refresh_token")
        userDefaults.removeObject(forKey: "token_expires_at")
    }
    
    // MARK: - Demo Account Management
    func getDemoAccountInfo() -> String {
        return """
        데모 계정 정보:
        사용자명: \(demoAccountCredentials.username)
        비밀번호: \(demoAccountCredentials.password)
        이메일: \(demoAccountCredentials.email)
        이름: \(demoAccountCredentials.name)
        
        이 계정으로 앱의 모든 기능을 테스트할 수 있습니다.
        """
    }
    
    func validateDemoCredentials(username: String, password: String) -> Bool {
        return username == demoAccountCredentials.username && 
               password == demoAccountCredentials.password
    }
}

// MARK: - Supporting Models
struct DataItem {
    let name: String
    let purpose: String
    let required: Bool
}

struct DataCollectionSummary {
    let requiredData: [DataItem]
    let optionalData: [DataItem]
    let dataRetention: String
    let dataSecurity: String
}

struct ConsentData {
    let privacyPolicyAccepted: Bool
    let dataCollectionAccepted: Bool
    let pushNotificationsAccepted: Bool
    let locationServicesAccepted: Bool
}

struct OptionalPersonalData {
    let birthYear: String
    let gender: String
    let region: String
}

struct UserDataExport {
    let consentData: ConsentData
    let optionalPersonalData: OptionalPersonalData
    let exportDate: Date
}

struct DemoAccountCredentials {
    let username: String
    let password: String
    let email: String
    let name: String
}

 