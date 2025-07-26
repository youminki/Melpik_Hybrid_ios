//
//  AppStateManager.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI
import LocalAuthentication
import UserNotifications
import Foundation

@MainActor
class AppStateManager: ObservableObject {
    @Published var isBiometricEnabled = false
    @Published var isPushNotificationEnabled = false
    @Published var appLaunchCount = 0
    @Published var lastAppLaunchDate: Date?
    @Published var appVersion = ""
    @Published var buildNumber = ""
    @Published var deviceInfo = DeviceInfo()
    @Published var appUsageStats = AppUsageStats()
    
    private let userDefaults = UserDefaults.standard
    private let biometricContext = LAContext()
    
    init() {
        loadAppState()
        setupAppInfo()
        incrementLaunchCount()
        updateLastLaunchDate()
    }
    
    // MARK: - App State Management
    private func loadAppState() {
        isBiometricEnabled = userDefaults.bool(forKey: "isBiometricEnabled")
        isPushNotificationEnabled = userDefaults.bool(forKey: "isPushNotificationEnabled")
        appLaunchCount = userDefaults.integer(forKey: "appLaunchCount")
        
        if let lastLaunch = userDefaults.object(forKey: "lastAppLaunchDate") as? Date {
            lastAppLaunchDate = lastLaunch
        }
    }
    
    private func setupAppInfo() {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            appVersion = version
        }
        
        if let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            buildNumber = build
        }
        
        deviceInfo = DeviceInfo()
    }
    
    private func incrementLaunchCount() {
        appLaunchCount += 1
        userDefaults.set(appLaunchCount, forKey: "appLaunchCount")
    }
    
    private func updateLastLaunchDate() {
        lastAppLaunchDate = Date()
        userDefaults.set(lastAppLaunchDate, forKey: "lastAppLaunchDate")
    }
    
    // MARK: - Biometric Authentication
    func setupBiometricAuth() {
        var error: NSError?
        
        if biometricContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            isBiometricEnabled = true
            userDefaults.set(true, forKey: "isBiometricEnabled")
        } else {
            isBiometricEnabled = false
            userDefaults.set(false, forKey: "isBiometricEnabled")
            
            if let error = error {
                print("Biometric authentication not available: \(error.localizedDescription)")
            }
        }
    }
    
    func authenticateWithBiometrics(completion: @escaping (Bool, String?) -> Void) {
        guard isBiometricEnabled else {
            completion(false, "생체 인증이 활성화되지 않았습니다.")
            return
        }
        
        let reason = "Melpik 앱에 로그인하기 위해 생체 인증이 필요합니다."
        
        biometricContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(true, nil)
                } else {
                    let errorMessage = error?.localizedDescription ?? "생체 인증에 실패했습니다."
                    completion(false, errorMessage)
                }
            }
        }
    }
    
    // MARK: - Push Notification Management
    func requestPushNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.isPushNotificationEnabled = granted
                self.userDefaults.set(granted, forKey: "isPushNotificationEnabled")
                
                if granted {
                    print("Push notification permission granted")
                    self.registerForRemoteNotifications()
                } else {
                    print("Push notification permission denied")
                    if let error = error {
                        print("Error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func registerForRemoteNotifications() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    // MARK: - App Analytics & Usage Tracking
    func trackAppEvent(_ event: AppEvent) {
        appUsageStats.addEvent(event)
        saveUsageStats()
        
        // 서버에 이벤트 전송 (선택적)
        sendAnalyticsToServer(event)
    }
    
    private func saveUsageStats() {
        if let encoded = try? JSONEncoder().encode(appUsageStats) {
            userDefaults.set(encoded, forKey: "appUsageStats")
        }
    }
    
    private func sendAnalyticsToServer(_ event: AppEvent) {
        // 실제 구현에서는 서버 API 호출
        // 여기서는 로그만 출력
        print("Analytics Event: \(event.name) - \(event.properties)")
    }
    
    // MARK: - App Performance Monitoring
    func startPerformanceMonitoring() {
        // 앱 성능 모니터링 시작
        trackAppEvent(AppEvent(name: "app_launch", properties: [
            "version": appVersion,
            "build": buildNumber,
            "device_model": deviceInfo.model,
            "os_version": deviceInfo.osVersion
        ]))
    }
    
    func trackScreenView(_ screenName: String) {
        trackAppEvent(AppEvent(name: "screen_view", properties: [
            "screen_name": screenName,
            "timestamp": Date().timeIntervalSince1970
        ]))
    }
    
    func trackUserAction(_ action: String, properties: [String: Any] = [:]) {
        var eventProperties = properties
        eventProperties["action"] = action
        eventProperties["timestamp"] = Date().timeIntervalSince1970
        
        trackAppEvent(AppEvent(name: "user_action", properties: eventProperties))
    }
    
    // MARK: - Error Tracking
    func trackError(_ error: Error, context: String = "") {
        let errorEvent = AppEvent(name: "app_error", properties: [
            "error_description": error.localizedDescription,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code,
            "context": context,
            "timestamp": Date().timeIntervalSince1970
        ])
        
        trackAppEvent(errorEvent)
    }
    
    // MARK: - App Health Check
    func performHealthCheck() -> AppHealthStatus {
        var issues: [String] = []
        
        // 네트워크 연결 확인
        if !NetworkMonitor.shared.isConnected {
            issues.append("네트워크 연결 없음")
        }
        
        // 저장 공간 확인
        if let availableSpace = getAvailableDiskSpace(), availableSpace < 100 * 1024 * 1024 { // 100MB
            issues.append("저장 공간 부족")
        }
        
        // 메모리 사용량 확인
        let memoryUsage = getMemoryUsage()
        if memoryUsage > 0.8 { // 80% 이상 사용
            issues.append("메모리 사용량 높음")
        }
        
        return AppHealthStatus(
            isHealthy: issues.isEmpty,
            issues: issues,
            timestamp: Date()
        )
    }
    
    private func getAvailableDiskSpace() -> Int64? {
        let fileManager = FileManager.default
        guard let path = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        do {
            let attributes = try fileManager.attributesOfFileSystem(forPath: path.path)
            return attributes[.systemFreeSize] as? Int64
        } catch {
            return nil
        }
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(info.resident_size) / Double(ProcessInfo.processInfo.physicalMemory)
        }
        
        return 0.0
    }
    
    // MARK: - App Settings
    func resetAppSettings() {
        userDefaults.removeObject(forKey: "isBiometricEnabled")
        userDefaults.removeObject(forKey: "isPushNotificationEnabled")
        userDefaults.removeObject(forKey: "appLaunchCount")
        userDefaults.removeObject(forKey: "lastAppLaunchDate")
        userDefaults.removeObject(forKey: "appUsageStats")
        
        loadAppState()
    }
    
    func exportAppData() -> AppDataExport {
        return AppDataExport(
            appInfo: AppInfo(
                version: appVersion,
                buildNumber: buildNumber,
                launchCount: appLaunchCount,
                lastLaunchDate: lastAppLaunchDate
            ),
            deviceInfo: deviceInfo,
            usageStats: appUsageStats,
            settings: AppSettings(
                isBiometricEnabled: isBiometricEnabled,
                isPushNotificationEnabled: isPushNotificationEnabled
            ),
            exportDate: Date()
        )
    }
}

// MARK: - Supporting Models
struct DeviceInfo {
    let model: String
    let osVersion: String
    let deviceIdentifier: String
    
    init() {
        self.model = UIDevice.current.model
        self.osVersion = UIDevice.current.systemVersion
        self.deviceIdentifier = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
}

struct AppUsageStats: Codable {
    var events: [AppEvent] = []
    var sessionCount = 0
    var totalUsageTime: TimeInterval = 0
    var lastSessionStart: Date?
    
    mutating func addEvent(_ event: AppEvent) {
        events.append(event)
        
        // 세션 관리
        if event.name == "app_launch" {
            sessionCount += 1
            lastSessionStart = Date()
        } else if event.name == "app_background" {
            if let start = lastSessionStart {
                totalUsageTime += Date().timeIntervalSince(start)
            }
        }
    }
}

struct AppEvent: Codable {
    let name: String
    let properties: [String: String]
    let timestamp: Date
    
    init(name: String, properties: [String: Any] = [:]) {
        self.name = name
        // Convert Any to String for Codable support
        self.properties = properties.mapValues { String(describing: $0) }
        self.timestamp = Date()
    }
}

struct AppHealthStatus {
    let isHealthy: Bool
    let issues: [String]
    let timestamp: Date
}

struct AppInfo {
    let version: String
    let buildNumber: String
    let launchCount: Int
    let lastLaunchDate: Date?
}

struct AppSettings {
    let isBiometricEnabled: Bool
    let isPushNotificationEnabled: Bool
}

struct AppDataExport {
    let appInfo: AppInfo
    let deviceInfo: DeviceInfo
    let usageStats: AppUsageStats
    let settings: AppSettings
    let exportDate: Date
}

 
