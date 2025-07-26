//
//  PerformanceMonitor.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import Foundation
import UIKit
import os.log

@MainActor
class PerformanceMonitor: ObservableObject {
    @Published var currentMemoryUsage: Double = 0.0
    @Published var peakMemoryUsage: Double = 0.0
    @Published var cpuUsage: Double = 0.0
    @Published var batteryLevel: Float = 0.0
    @Published var thermalState: ProcessInfo.ThermalState = .nominal
    @Published var performanceMetrics: PerformanceMetrics
    @Published var isMonitoring = false
    
    private var memoryTimer: Timer?
    private var cpuTimer: Timer?
    private var batteryTimer: Timer?
    private let logger = Logger(subsystem: "com.melpik.app", category: "Performance")
    
    static let shared = PerformanceMonitor()
    
    init() {
        self.performanceMetrics = PerformanceMetrics()
        setupMonitoring()
    }
    
    deinit {
        // Swift 6 호환성을 위해 Timer만 정리
        memoryTimer?.invalidate()
        cpuTimer?.invalidate()
        batteryTimer?.invalidate()
        
        // NotificationCenter 옵저버 제거
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Monitoring Setup
    private func setupMonitoring() {
        // 배터리 모니터링 설정
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        // 열 상태 모니터링
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(thermalStateChanged),
            name: ProcessInfo.thermalStateDidChangeNotification,
            object: nil
        )
        
        // 앱 생명주기 모니터링
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillTerminate),
            name: UIApplication.willTerminateNotification,
            object: nil
        )
    }
    
    // MARK: - Monitoring Control
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // 메모리 사용량 모니터링 (1초마다)
        memoryTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
            }
        }
        
        // CPU 사용량 모니터링 (5초마다)
        cpuTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCPUUsage()
            }
        }
        
        // 배터리 레벨 모니터링 (5분마다로 변경하여 배터리 소모 최소화)
        batteryTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateBatteryLevel()
            }
        }
        
        // 초기 상태 업데이트
        updateMemoryUsage()
        updateCPUUsage()
        updateBatteryLevel()
        updateThermalState()
        
        logger.info("Performance monitoring started")
    }
    
    func stopMonitoring() {
        isMonitoring = false
        
        memoryTimer?.invalidate()
        memoryTimer = nil
        
        cpuTimer?.invalidate()
        cpuTimer = nil
        
        batteryTimer?.invalidate()
        batteryTimer = nil
        
        logger.info("Performance monitoring stopped")
    }
    
    // MARK: - Performance Metrics
    private func updateMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        currentMemoryUsage = memoryUsage
        
        if memoryUsage > peakMemoryUsage {
            peakMemoryUsage = memoryUsage
        }
        
        // 메모리 사용량 기록
        performanceMetrics.addMemoryUsage(memoryUsage)
        
        // 메모리 경고 체크
        if memoryUsage > 0.8 {
            logger.warning("High memory usage detected: \(memoryUsage * 100, privacy: .public)%")
            NotificationCenter.default.post(name: .highMemoryUsage, object: nil)
        }
    }
    
    private func updateCPUUsage() {
        let cpuUsage = getCPUUsage()
        self.cpuUsage = cpuUsage
        
        // CPU 사용량 기록
        performanceMetrics.addCPUUsage(cpuUsage)
        
        // CPU 경고 체크
        if cpuUsage > 0.7 {
            logger.warning("High CPU usage detected: \(cpuUsage * 100, privacy: .public)%")
            NotificationCenter.default.post(name: .highCPUUsage, object: nil)
        }
    }
    
    private func updateBatteryLevel() {
        batteryLevel = UIDevice.current.batteryLevel
        performanceMetrics.addBatteryLevel(batteryLevel)
        
        // 배터리 레벨 경고 체크
        if batteryLevel < 0.2 {
            logger.warning("Low battery level: \(self.batteryLevel * 100, privacy: .public)%")
            NotificationCenter.default.post(name: .lowBatteryLevel, object: nil)
            
            // 배터리가 낮을 때는 더 자주 체크 (1분마다)
            batteryTimer?.invalidate()
            batteryTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.updateBatteryLevel()
                }
            }
        } else if batteryLevel > 0.3 && batteryTimer?.timeInterval == 60.0 {
            // 배터리가 충분할 때는 다시 5분마다로 변경
            batteryTimer?.invalidate()
            batteryTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.updateBatteryLevel()
                }
            }
        }
    }
    
    private func updateThermalState() {
        thermalState = ProcessInfo.processInfo.thermalState
        performanceMetrics.addThermalState(thermalState)
        
        // 열 상태 경고 체크
        if thermalState == .serious || thermalState == .critical {
            logger.warning("High thermal state detected: \(self.thermalState.rawValue, privacy: .public)")
            NotificationCenter.default.post(name: .highThermalState, object: nil)
        }
    }
    
    // MARK: - System Information
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
    
    private func getCPUUsage() -> Double {
        // CPU 사용량 측정 (간단한 구현)
        // 실제 구현에서는 더 정확한 측정이 필요
        return Double.random(in: 0.1...0.3) // 임시 구현
    }
    
    // MARK: - Performance Analysis
    func analyzePerformance() -> PerformanceAnalysis {
        let memoryAnalysis = analyzeMemoryUsage()
        let cpuAnalysis = analyzeCPUUsage()
        let batteryAnalysis = analyzeBatteryUsage()
        let thermalAnalysis = analyzeThermalState()
        
        let recommendations = generateRecommendations(
            memoryAnalysis: memoryAnalysis,
            cpuAnalysis: cpuAnalysis,
            batteryAnalysis: batteryAnalysis,
            thermalAnalysis: thermalAnalysis
        )
        
        return PerformanceAnalysis(
            memoryAnalysis: memoryAnalysis,
            cpuAnalysis: cpuAnalysis,
            batteryAnalysis: batteryAnalysis,
            thermalAnalysis: thermalAnalysis,
            recommendations: recommendations,
            timestamp: Date()
        )
    }
    
    private func analyzeMemoryUsage() -> MemoryAnalysis {
        let averageUsage = performanceMetrics.averageMemoryUsage
        let peakUsage = performanceMetrics.peakMemoryUsage
        let trend = performanceMetrics.memoryUsageTrend
        
        let status: PerformanceStatus
        if averageUsage < 0.5 {
            status = .excellent
        } else if averageUsage < 0.7 {
            status = .good
        } else if averageUsage < 0.8 {
            status = .fair
        } else {
            status = .poor
        }
        
        return MemoryAnalysis(
            averageUsage: averageUsage,
            peakUsage: peakUsage,
            trend: trend,
            status: status
        )
    }
    
    private func analyzeCPUUsage() -> CPUAnalysis {
        let averageUsage = performanceMetrics.averageCPUUsage
        let peakUsage = performanceMetrics.peakCPUUsage
        let trend = performanceMetrics.cpuUsageTrend
        
        let status: PerformanceStatus
        if averageUsage < 0.3 {
            status = .excellent
        } else if averageUsage < 0.5 {
            status = .good
        } else if averageUsage < 0.7 {
            status = .fair
        } else {
            status = .poor
        }
        
        return CPUAnalysis(
            averageUsage: averageUsage,
            peakUsage: peakUsage,
            trend: trend,
            status: status
        )
    }
    
    private func analyzeBatteryUsage() -> BatteryAnalysis {
        let currentLevel = batteryLevel
        let averageLevel = performanceMetrics.averageBatteryLevel
        let trend = performanceMetrics.batteryLevelTrend
        
        let status: PerformanceStatus
        if currentLevel > 0.8 {
            status = .excellent
        } else if currentLevel > 0.5 {
            status = .good
        } else if currentLevel > 0.2 {
            status = .fair
        } else {
            status = .poor
        }
        
        return BatteryAnalysis(
            currentLevel: currentLevel,
            averageLevel: averageLevel,
            trend: trend,
            status: status
        )
    }
    
    private func analyzeThermalState() -> ThermalAnalysis {
        let currentState = thermalState
        let averageState = performanceMetrics.averageThermalState
        let trend = performanceMetrics.thermalStateTrend
        
        let status: PerformanceStatus
        switch currentState {
        case .nominal:
            status = .excellent
        case .fair:
            status = .good
        case .serious:
            status = .fair
        case .critical:
            status = .poor
        @unknown default:
            status = .unknown
        }
        
        return ThermalAnalysis(
            currentState: currentState,
            averageState: averageState,
            trend: trend,
            status: status
        )
    }
    
    private func generateRecommendations(
        memoryAnalysis: MemoryAnalysis,
        cpuAnalysis: CPUAnalysis,
        batteryAnalysis: BatteryAnalysis,
        thermalAnalysis: ThermalAnalysis
    ) -> [PerformanceRecommendation] {
        var recommendations: [PerformanceRecommendation] = []
        
        // 메모리 관련 권장사항
        if memoryAnalysis.status == .poor {
            recommendations.append(PerformanceRecommendation(
                type: .memory,
                priority: .high,
                title: "메모리 사용량 최적화",
                description: "앱의 메모리 사용량이 높습니다. 캐시를 정리하거나 불필요한 리소스를 해제하세요.",
                action: "캐시 정리"
            ))
        }
        
        // CPU 관련 권장사항
        if cpuAnalysis.status == .poor {
            recommendations.append(PerformanceRecommendation(
                type: .cpu,
                priority: .high,
                title: "CPU 사용량 최적화",
                description: "CPU 사용량이 높습니다. 백그라운드 작업을 줄이거나 앱을 재시작하세요.",
                action: "앱 재시작"
            ))
        }
        
        // 배터리 관련 권장사항
        if batteryAnalysis.status == .poor {
            recommendations.append(PerformanceRecommendation(
                type: .battery,
                priority: .medium,
                title: "배터리 절약",
                description: "배터리 레벨이 낮습니다. 불필요한 기능을 비활성화하세요.",
                action: "절약 모드 활성화"
            ))
        }
        
        // 열 상태 관련 권장사항
        if thermalAnalysis.status == .poor {
            recommendations.append(PerformanceRecommendation(
                type: .thermal,
                priority: .high,
                title: "열 상태 주의",
                description: "기기가 과열되었습니다. 앱 사용을 중단하고 기기를 식히세요.",
                action: "앱 일시 중지"
            ))
        }
        
        return recommendations
    }
    
    // MARK: - Notification Handlers
    @objc private func thermalStateChanged() {
        updateThermalState()
    }
    
    @objc private func appDidBecomeActive() {
        if isMonitoring {
            // 배터리 모니터링만 다시 시작
            batteryTimer = Timer.scheduledTimer(withTimeInterval: 300.0, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.updateBatteryLevel()
                }
            }
            logger.info("App became active - battery monitoring resumed")
        }
    }
    
    @objc private func appDidEnterBackground() {
        // 백그라운드에서는 배터리 모니터링 중지
        batteryTimer?.invalidate()
        batteryTimer = nil
        logger.info("App entered background - battery monitoring stopped")
    }
    
    @objc private func appWillTerminate() {
        stopMonitoring()
        performanceMetrics.saveToUserDefaults()
    }
}

// MARK: - Supporting Models
struct PerformanceMetrics {
    var memoryUsageHistory: [Double] = []
    var cpuUsageHistory: [Double] = []
    var batteryLevelHistory: [Float] = []
    var thermalStateHistory: [ProcessInfo.ThermalState] = []
    
    var averageMemoryUsage: Double {
        guard !memoryUsageHistory.isEmpty else { return 0.0 }
        return memoryUsageHistory.reduce(0, +) / Double(memoryUsageHistory.count)
    }
    
    var peakMemoryUsage: Double {
        return memoryUsageHistory.max() ?? 0.0
    }
    
    var averageCPUUsage: Double {
        guard !cpuUsageHistory.isEmpty else { return 0.0 }
        return cpuUsageHistory.reduce(0, +) / Double(cpuUsageHistory.count)
    }
    
    var peakCPUUsage: Double {
        return cpuUsageHistory.max() ?? 0.0
    }
    
    var averageBatteryLevel: Float {
        guard !batteryLevelHistory.isEmpty else { return 0.0 }
        return batteryLevelHistory.reduce(0, +) / Float(batteryLevelHistory.count)
    }
    
    var averageThermalState: ProcessInfo.ThermalState {
        guard !thermalStateHistory.isEmpty else { return .nominal }
        let averageValue = thermalStateHistory.map { $0.rawValue }.reduce(0, +) / thermalStateHistory.count
        return ProcessInfo.ThermalState(rawValue: averageValue) ?? .nominal
    }
    
    var memoryUsageTrend: Trend {
        return calculateTrend(memoryUsageHistory)
    }
    
    var cpuUsageTrend: Trend {
        return calculateTrend(cpuUsageHistory)
    }
    
    var batteryLevelTrend: Trend {
        return calculateTrend(batteryLevelHistory.map { Double($0) })
    }
    
    var thermalStateTrend: Trend {
        return calculateTrend(thermalStateHistory.map { Double($0.rawValue) })
    }
    
    mutating func addMemoryUsage(_ usage: Double) {
        memoryUsageHistory.append(usage)
        if memoryUsageHistory.count > 100 {
            memoryUsageHistory.removeFirst()
        }
    }
    
    mutating func addCPUUsage(_ usage: Double) {
        cpuUsageHistory.append(usage)
        if cpuUsageHistory.count > 100 {
            cpuUsageHistory.removeFirst()
        }
    }
    
    mutating func addBatteryLevel(_ level: Float) {
        batteryLevelHistory.append(level)
        if batteryLevelHistory.count > 100 {
            batteryLevelHistory.removeFirst()
        }
    }
    
    mutating func addThermalState(_ state: ProcessInfo.ThermalState) {
        thermalStateHistory.append(state)
        if thermalStateHistory.count > 100 {
            thermalStateHistory.removeFirst()
        }
    }
    
    private func calculateTrend<T: BinaryFloatingPoint>(_ values: [T]) -> Trend {
        guard values.count >= 2 else { return .stable }
        
        let recent = Array(values.suffix(10))
        let older = Array(values.prefix(max(1, values.count - 10)))
        
        let recentAverage = recent.reduce(0, +) / T(recent.count)
        let olderAverage = older.reduce(0, +) / T(older.count)
        
        let difference = recentAverage - olderAverage
        let threshold = T(0.05) // 5% 임계값
        
        if difference > threshold {
            return .increasing
        } else if difference < -threshold {
            return .decreasing
        } else {
            return .stable
        }
    }
    
    func saveToUserDefaults() {
        // 성능 메트릭을 UserDefaults에 저장
        let userDefaults = UserDefaults.standard
        userDefaults.set(memoryUsageHistory, forKey: "performance_memory_history")
        userDefaults.set(cpuUsageHistory, forKey: "performance_cpu_history")
        userDefaults.set(batteryLevelHistory, forKey: "performance_battery_history")
        userDefaults.set(thermalStateHistory.map { $0.rawValue }, forKey: "performance_thermal_history")
    }
}

enum Trend {
    case increasing
    case decreasing
    case stable
}

enum PerformanceStatus {
    case excellent
    case good
    case fair
    case poor
    case unknown
}

enum RecommendationType {
    case memory
    case cpu
    case battery
    case thermal
}

enum RecommendationPriority {
    case low
    case medium
    case high
    case critical
}

struct PerformanceRecommendation {
    let type: RecommendationType
    let priority: RecommendationPriority
    let title: String
    let description: String
    let action: String
}

struct MemoryAnalysis {
    let averageUsage: Double
    let peakUsage: Double
    let trend: Trend
    let status: PerformanceStatus
}

struct CPUAnalysis {
    let averageUsage: Double
    let peakUsage: Double
    let trend: Trend
    let status: PerformanceStatus
}

struct BatteryAnalysis {
    let currentLevel: Float
    let averageLevel: Float
    let trend: Trend
    let status: PerformanceStatus
}

struct ThermalAnalysis {
    let currentState: ProcessInfo.ThermalState
    let averageState: ProcessInfo.ThermalState
    let trend: Trend
    let status: PerformanceStatus
}

struct PerformanceAnalysis {
    let memoryAnalysis: MemoryAnalysis
    let cpuAnalysis: CPUAnalysis
    let batteryAnalysis: BatteryAnalysis
    let thermalAnalysis: ThermalAnalysis
    let recommendations: [PerformanceRecommendation]
    let timestamp: Date
}

// MARK: - Notification Names
extension Notification.Name {
    static let highMemoryUsage = Notification.Name("highMemoryUsage")
    static let highCPUUsage = Notification.Name("highCPUUsage")
    static let lowBatteryLevel = Notification.Name("lowBatteryLevel")
    static let highThermalState = Notification.Name("highThermalState")
} 