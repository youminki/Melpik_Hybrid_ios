//
//  AppSettingsView.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI

struct AppSettingsView: View {
    @ObservedObject var privacyManager: PrivacyManager
    @ObservedObject var cacheManager: CacheManager
    @ObservedObject var performanceMonitor: PerformanceMonitor
    @ObservedObject var networkMonitor: NetworkMonitor
    @ObservedObject var appState: AppStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingCacheClearAlert = false
    @State private var showingPerformanceAnalysis = false
    @State private var showingPrivacyPolicy = false
    @State private var showingDataExport = false
    @State private var showingDataDeleteAlert = false
    
    var body: some View {
        NavigationView {
            List {
                // MARK: - 앱 정보 섹션
                Section("앱 정보") {
                    HStack {
                        Image("LoadingMelPick")
                            .resizable()
                            .frame(width: 60, height: 27)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Melpik")
                                .font(.custom("NanumSquareB", size: 18))
                                .foregroundColor(.primary)
                            
                            Text("버전 \(appState.appVersion) (\(appState.buildNumber))")
                                .font(.custom("NanumSquareR", size: 14))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    
                    InfoRow(title: "앱 실행 횟수", value: "\(appState.appLaunchCount)회")
                    if let lastLaunch = appState.lastAppLaunchDate {
                        InfoRow(title: "마지막 실행", value: formatDate(lastLaunch))
                    }
                }
                
                // MARK: - 개인정보 설정 섹션
                Section("개인정보") {
                    NavigationLink(destination: PrivacySettingsView(privacyManager: privacyManager)) {
                        SettingsRow(
                            icon: "hand.raised.fill",
                            title: "개인정보 처리방침",
                            subtitle: "데이터 수집 및 이용 동의"
                        )
                    }
                    
                    Button(action: { showingDataExport = true }) {
                        SettingsRow(
                            icon: "square.and.arrow.up",
                            title: "데이터 내보내기",
                            subtitle: "내 개인정보 다운로드"
                        )
                    }
                    
                    Button(action: { showingDataDeleteAlert = true }) {
                        SettingsRow(
                            icon: "trash.fill",
                            title: "데이터 삭제",
                            subtitle: "모든 개인정보 영구 삭제",
                            color: .red
                        )
                    }
                }
                
                // MARK: - 성능 모니터링 섹션
                Section("성능") {
                    Button(action: { showingPerformanceAnalysis = true }) {
                        SettingsRow(
                            icon: "speedometer",
                            title: "성능 분석",
                            subtitle: "앱 성능 상태 확인"
                        )
                    }
                    
                    HStack {
                        SettingsRow(
                            icon: "memorychip",
                            title: "메모리 사용량",
                            subtitle: "\(Int(performanceMonitor.currentMemoryUsage * 100))%"
                        )
                        
                        Spacer()
                        
                        Circle()
                            .fill(memoryUsageColor)
                            .frame(width: 12, height: 12)
                    }
                    
                    HStack {
                        SettingsRow(
                            icon: "cpu",
                            title: "CPU 사용량",
                            subtitle: "\(Int(performanceMonitor.cpuUsage * 100))%"
                        )
                        
                        Spacer()
                        
                        Circle()
                            .fill(cpuUsageColor)
                            .frame(width: 12, height: 12)
                    }
                    
                    HStack {
                        SettingsRow(
                            icon: "battery.100",
                            title: "배터리 레벨",
                            subtitle: "\(Int(performanceMonitor.batteryLevel * 100))%"
                        )
                        
                        Spacer()
                        
                        Circle()
                            .fill(batteryLevelColor)
                            .frame(width: 12, height: 12)
                    }
                }
                
                // MARK: - 네트워크 상태 섹션
                Section("네트워크") {
                    HStack {
                        SettingsRow(
                            icon: networkMonitor.isConnected ? "wifi" : "wifi.slash",
                            title: "연결 상태",
                            subtitle: networkMonitor.isConnected ? "연결됨" : "연결 안됨"
                        )
                        
                        Spacer()
                        
                        Circle()
                            .fill(networkMonitor.isConnected ? .green : .red)
                            .frame(width: 12, height: 12)
                    }
                    
                    if networkMonitor.isConnected {
                        InfoRow(title: "연결 타입", value: networkMonitor.connectionType.rawValue)
                        InfoRow(title: "연결 품질", value: networkMonitor.connectionQuality.rawValue)
                        if networkMonitor.isExpensive {
                            InfoRow(title: "데이터 사용량", value: "고비용 네트워크", color: .orange)
                        }
                    }
                }
                
                // MARK: - 캐시 관리 섹션
                Section("캐시") {
                    HStack {
                        SettingsRow(
                            icon: "externaldrive.fill",
                            title: "캐시 크기",
                            subtitle: formatFileSize(cacheManager.cacheSize)
                        )
                        
                        Spacer()
                        
                        Button("정리") {
                            showingCacheClearAlert = true
                        }
                        .font(.custom("NanumSquareB", size: 14))
                        .foregroundColor(.blue)
                    }
                    
                    InfoRow(title: "캐시 항목 수", value: "\(cacheManager.cacheItemCount)개")
                    
                    if cacheManager.isClearingCache {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("캐시 정리 중...")
                                .font(.custom("NanumSquareR", size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - 앱 설정 섹션
                Section("앱 설정") {
                    Toggle(isOn: .constant(appState.isBiometricEnabled)) {
                        SettingsRow(
                            icon: "faceid",
                            title: "생체 인증",
                            subtitle: "Face ID / Touch ID 사용"
                        )
                    }
                    .disabled(true)
                    
                    Toggle(isOn: .constant(appState.isPushNotificationEnabled)) {
                        SettingsRow(
                            icon: "bell.fill",
                            title: "푸시 알림",
                            subtitle: "앱 알림 수신"
                        )
                    }
                    .disabled(true)
                }
                
                // MARK: - 지원 섹션
                Section("지원") {
                    Button(action: { openURL("https://me1pik.com/support") }) {
                        SettingsRow(
                            icon: "questionmark.circle.fill",
                            title: "고객 지원",
                            subtitle: "도움말 및 문의"
                        )
                    }
                    
                    Button(action: { openURL("https://me1pik.com/terms") }) {
                        SettingsRow(
                            icon: "doc.text.fill",
                            title: "이용약관",
                            subtitle: "서비스 이용 조건"
                        )
                    }
                    
                    Button(action: { showingPrivacyPolicy = true }) {
                        SettingsRow(
                            icon: "hand.raised.fill",
                            title: "개인정보처리방침",
                            subtitle: "개인정보 보호 정책"
                        )
                    }
                }
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
        .alert("캐시 정리", isPresented: $showingCacheClearAlert) {
            Button("정리", role: .destructive) {
                cacheManager.clearAllCache()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("모든 캐시 데이터가 삭제됩니다. 계속하시겠습니까?")
        }
        .alert("데이터 삭제", isPresented: $showingDataDeleteAlert) {
            Button("삭제", role: .destructive) {
                privacyManager.deleteUserData()
                cacheManager.clearAllCache()
            }
            Button("취소", role: .cancel) { }
        } message: {
            Text("모든 개인정보가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다.")
        }
        .sheet(isPresented: $showingPerformanceAnalysis) {
            PerformanceAnalysisView(performanceMonitor: performanceMonitor)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingDataExport) {
            DataExportView(privacyManager: privacyManager, appState: appState)
        }
    }
    
    // MARK: - Computed Properties
    private var memoryUsageColor: Color {
        if performanceMonitor.currentMemoryUsage < 0.5 {
            return .green
        } else if performanceMonitor.currentMemoryUsage < 0.7 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var cpuUsageColor: Color {
        if performanceMonitor.cpuUsage < 0.3 {
            return .green
        } else if performanceMonitor.cpuUsage < 0.5 {
            return .yellow
        } else {
            return .red
        }
    }
    
    private var batteryLevelColor: Color {
        if performanceMonitor.batteryLevel > 0.5 {
            return .green
        } else if performanceMonitor.batteryLevel > 0.2 {
            return .yellow
        } else {
            return .red
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Supporting Views
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    var color: Color = .blue
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("NanumSquareB", size: 16))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.custom("NanumSquareR", size: 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    var color: Color = .secondary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.custom("NanumSquareR", size: 16))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.custom("NanumSquareR", size: 16))
                .foregroundColor(color)
        }
    }
}

struct PrivacySettingsView: View {
    @ObservedObject var privacyManager: PrivacyManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section("동의 설정") {
                Toggle(isOn: $privacyManager.hasAcceptedPrivacyPolicy) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("개인정보처리방침")
                            .font(.custom("NanumSquareB", size: 16))
                        Text("개인정보 수집 및 이용에 동의")
                            .font(.custom("NanumSquareR", size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $privacyManager.hasAcceptedDataCollection) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("데이터 수집")
                            .font(.custom("NanumSquareB", size: 16))
                        Text("서비스 개선을 위한 데이터 수집")
                            .font(.custom("NanumSquareR", size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $privacyManager.hasAcceptedPushNotifications) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("푸시 알림")
                            .font(.custom("NanumSquareB", size: 16))
                        Text("앱 내 알림 수신")
                            .font(.custom("NanumSquareR", size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $privacyManager.hasAcceptedLocationServices) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("위치 서비스")
                            .font(.custom("NanumSquareB", size: 16))
                        Text("위치 기반 서비스 이용")
                            .font(.custom("NanumSquareR", size: 14))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("개인정보 설정")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PerformanceAnalysisView: View {
    @ObservedObject var performanceMonitor: PerformanceMonitor
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    let analysis = performanceMonitor.analyzePerformance()
                    
                    // 전체 성능 상태
                    VStack(spacing: 16) {
                        Text("성능 분석 결과")
                            .font(.custom("NanumSquareB", size: 24))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 20) {
                            PerformanceCard(
                                title: "메모리",
                                value: "\(Int(analysis.memoryAnalysis.averageUsage * 100))%",
                                status: analysis.memoryAnalysis.status
                            )
                            
                            PerformanceCard(
                                title: "CPU",
                                value: "\(Int(analysis.cpuAnalysis.averageUsage * 100))%",
                                status: analysis.cpuAnalysis.status
                            )
                        }
                        
                        HStack(spacing: 20) {
                            PerformanceCard(
                                title: "배터리",
                                value: "\(Int(analysis.batteryAnalysis.currentLevel * 100))%",
                                status: analysis.batteryAnalysis.status
                            )
                            
                            PerformanceCard(
                                title: "열 상태",
                                value: thermalStateText(analysis.thermalAnalysis.currentState),
                                status: analysis.thermalAnalysis.status
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // 권장사항
                    if !analysis.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("권장사항")
                                .font(.custom("NanumSquareB", size: 20))
                                .foregroundColor(.primary)
                            
                            ForEach(analysis.recommendations, id: \.title) { recommendation in
                                RecommendationCard(recommendation: recommendation)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationTitle("성능 분석")
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
    
    private func thermalStateText(_ state: ProcessInfo.ThermalState) -> String {
        switch state {
        case .nominal: return "정상"
        case .fair: return "양호"
        case .serious: return "주의"
        case .critical: return "위험"
        @unknown default: return "알 수 없음"
        }
    }
}

struct PerformanceCard: View {
    let title: String
    let value: String
    let status: PerformanceStatus
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.custom("NanumSquareR", size: 14))
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.custom("NanumSquareB", size: 20))
                .foregroundColor(.primary)
            
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .red
        case .unknown: return .gray
        }
    }
}

struct RecommendationCard: View {
    let recommendation: PerformanceRecommendation
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: iconName)
                .foregroundColor(priorityColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.custom("NanumSquareB", size: 16))
                    .foregroundColor(.primary)
                
                Text(recommendation.description)
                    .font(.custom("NanumSquareR", size: 14))
                    .foregroundColor(.secondary)
                
                Button(recommendation.action) {
                    // 권장사항 실행
                }
                .font(.custom("NanumSquareB", size: 14))
                .foregroundColor(priorityColor)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch recommendation.type {
        case .memory: return "memorychip"
        case .cpu: return "cpu"
        case .battery: return "battery.100"
        case .thermal: return "thermometer"
        }
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        case .critical: return .purple
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("개인정보처리방침")
                        .font(.custom("NanumSquareB", size: 24))
                        .foregroundColor(.primary)
                    
                    Text("Melpik은 사용자의 개인정보 보호를 최우선으로 합니다.")
                        .font(.custom("NanumSquareR", size: 16))
                        .foregroundColor(.secondary)
                    
                    // 개인정보처리방침 내용 (간략화)
                    Group {
                        Text("1. 수집하는 개인정보")
                            .font(.custom("NanumSquareB", size: 18))
                        
                        Text("• 이메일 주소: 로그인 및 서비스 제공\n• 사용자 이름: 개인화된 서비스 제공\n• 디바이스 토큰: 푸시 알림 전송\n• 위치 정보: 위치 기반 서비스 (선택적)")
                            .font(.custom("NanumSquareR", size: 14))
                        
                        Text("2. 개인정보의 처리 및 보유기간")
                            .font(.custom("NanumSquareB", size: 18))
                        
                        Text("• 로그인 정보: 서비스 이용 기간 동안 보유\n• 디바이스 토큰: 앱 삭제 또는 로그아웃 시까지 보유\n• 위치 정보: 서비스 이용 시에만 임시 저장")
                            .font(.custom("NanumSquareR", size: 14))
                        
                        Text("3. 개인정보의 안전성 확보 조치")
                            .font(.custom("NanumSquareB", size: 18))
                        
                        Text("• 개인정보 암호화 저장 및 전송\n• 해킹 등에 대비한 기술적 대책\n• 개인정보 접근 권한의 제한")
                            .font(.custom("NanumSquareR", size: 14))
                    }
                }
                .padding()
            }
            .navigationTitle("개인정보처리방침")
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

struct DataExportView: View {
    @ObservedObject var privacyManager: PrivacyManager
    @ObservedObject var appState: AppStateManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportData: String = ""
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if isExporting {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("데이터 내보내기 중...")
                            .font(.custom("NanumSquareR", size: 16))
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("개인정보 내보내기")
                            .font(.custom("NanumSquareB", size: 24))
                            .foregroundColor(.primary)
                        
                        Text("내 개인정보를 JSON 형태로 다운로드할 수 있습니다.")
                            .font(.custom("NanumSquareR", size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("내보내기 시작") {
                            exportUserData()
                        }
                        .font(.custom("NanumSquareB", size: 16))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .cornerRadius(8)
                    }
                }
                
                if !exportData.isEmpty {
                    ScrollView {
                        Text(exportData)
                            .font(.custom("NanumSquareR", size: 12))
                            .foregroundColor(.secondary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("데이터 내보내기")
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
    
    private func exportUserData() {
        isExporting = true
        
        // 실제 구현에서는 더 상세한 데이터 내보내기
        let exportInfo: [String: Any] = [
            "exportDate": Date().ISO8601String(),
            "appInfo": [
                "version": appState.appVersion,
                "buildNumber": appState.buildNumber,
                "launchCount": appState.appLaunchCount
            ],
            "privacySettings": [
                "privacyPolicyAccepted": privacyManager.hasAcceptedPrivacyPolicy,
                "dataCollectionAccepted": privacyManager.hasAcceptedDataCollection,
                "pushNotificationsAccepted": privacyManager.hasAcceptedPushNotifications,
                "locationServicesAccepted": privacyManager.hasAcceptedLocationServices
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: exportInfo, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            exportData = jsonString
        }
        
        isExporting = false
    }
} 