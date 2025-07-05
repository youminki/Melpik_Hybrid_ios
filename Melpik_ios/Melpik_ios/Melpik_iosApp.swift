//
//  Melpik_iosApp.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI
import UserNotifications

@main
struct Melpik_iosApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// MARK: - AppDelegate
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // 푸시 알림 델리게이트 설정
        UNUserNotificationCenter.current().delegate = self
        
        // 상태바 스타일 설정
        if let windowScene = application.connectedScenes.first as? UIWindowScene {
            windowScene.statusBarManager?.statusBarStyle = .default
        }
        
        return true
    }
    
    // MARK: - 푸시 알림 토큰 등록
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // 토큰을 서버에 전송하는 로직을 여기에 구현
        // sendTokenToServer(token: token)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 앱이 포그라운드에 있을 때 알림 표시
        completionHandler([.alert, .badge, .sound])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // 알림을 탭했을 때의 처리
        let userInfo = response.notification.request.content.userInfo
        print("Notification tapped: \(userInfo)")
        
        // 웹뷰에 알림 데이터 전달
        NotificationCenter.default.post(name: .didReceiveNotification, object: nil, userInfo: userInfo)
        
        completionHandler()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didReceiveNotification = Notification.Name("didReceiveNotification")
}
