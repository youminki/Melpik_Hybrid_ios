//
//  NetworkMonitor.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import Foundation
import Network

@MainActor
class NetworkMonitor: ObservableObject {
    @Published var isConnected = false
    @Published var connectionType: ConnectionType = .unknown
    @Published var connectionQuality: ConnectionQuality = .unknown
    @Published var isExpensive = false
    @Published var isConstrained = false
    @Published var lastConnectionChange: Date?
    @Published var connectionHistory: [ConnectionEvent] = []
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    // iOS 17.4+에서는 Network Framework의 NWPathMonitor를 사용하므로
    // 기존 SCNetworkReachability는 더 이상 사용하지 않음
    
    static let shared = NetworkMonitor()
    
    init() {
        setupNetworkMonitoring()
    }
    
    deinit {
        monitor.cancel()
    }
    
    // MARK: - Network Monitoring Setup
    private func setupNetworkMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async { [weak self] in
                self?.handlePathUpdate(path)
            }
        }
        
        monitor.start(queue: queue)
    }
    

    
    // MARK: - Path Update Handling
    private func handlePathUpdate(_ path: NWPath) {
        let wasConnected = isConnected
        isConnected = path.status == .satisfied
        connectionType = determineConnectionType(path)
        isExpensive = path.isExpensive
        isConstrained = path.isConstrained
        
        if wasConnected != isConnected {
            lastConnectionChange = Date()
            addConnectionEvent(isConnected ? .connected : .disconnected)
            
            // 연결 품질 측정
            if isConnected {
                measureConnectionQuality()
            }
        }
        
        // 연결 상태 변경 알림
        NotificationCenter.default.post(
            name: .networkStatusChanged,
            object: nil,
            userInfo: [
                "isConnected": isConnected,
                "connectionType": connectionType.rawValue,
                "isExpensive": isExpensive
            ]
        )
    }
    
    // iOS 17.4+에서는 NWPathMonitor가 더 정확한 네트워크 상태를 제공하므로
    // 기존 SCNetworkReachability 기반 메서드는 제거
    
    // MARK: - Connection Type Detection
    private func determineConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        } else {
            return .unknown
        }
    }
    
    // MARK: - Connection Quality Measurement
    private func measureConnectionQuality() {
        guard isConnected else { return }
        
        // 연결 품질 측정을 위한 테스트 요청
        let testURL = URL(string: "https://me1pik.com")!
        let startTime = Date()
        
        URLSession.shared.dataTask(with: testURL) { _, response, error in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let responseTime = Date().timeIntervalSince(startTime)
                self.updateConnectionQuality(responseTime: responseTime, error: error)
            }
        }.resume()
    }
    
    private func updateConnectionQuality(responseTime: TimeInterval, error: Error?) {
        if error != nil {
            connectionQuality = .poor
        } else if responseTime < 0.5 {
            connectionQuality = .excellent
        } else if responseTime < 1.0 {
            connectionQuality = .good
        } else if responseTime < 2.0 {
            connectionQuality = .fair
        } else {
            connectionQuality = .poor
        }
    }
    
    // MARK: - Detailed Connection Check
    private func performDetailedConnectionCheck() {
        // 여러 엔드포인트로 연결 상태 확인
        let testURLs = [
            "https://me1pik.com",
            "https://www.apple.com",
            "https://www.google.com"
        ]
        
        var successfulConnections = 0
        let totalConnections = testURLs.count
        
        for urlString in testURLs {
            guard let url = URL(string: urlString) else { continue }
            
            URLSession.shared.dataTask(with: url) { _, response, error in
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    if error == nil && (response as? HTTPURLResponse)?.statusCode == 200 {
                        successfulConnections += 1
                    }
                    
                    // 모든 연결 테스트 완료 후 결과 처리
                    if successfulConnections + (totalConnections - successfulConnections) == totalConnections {
                        let isActuallyConnected = successfulConnections > 0
                        if self.isConnected != isActuallyConnected {
                            self.isConnected = isActuallyConnected
                            self.lastConnectionChange = Date()
                            self.addConnectionEvent(isActuallyConnected ? .connected : .disconnected)
                        }
                    }
                }
            }.resume()
        }
    }
    
    // MARK: - Connection History
    private func addConnectionEvent(_ event: ConnectionEventType) {
        let connectionEvent = ConnectionEvent(
            type: event,
            timestamp: Date(),
            connectionType: connectionType,
            connectionQuality: connectionQuality
        )
        
        connectionHistory.append(connectionEvent)
        
        // 최근 100개 이벤트만 유지
        if connectionHistory.count > 100 {
            connectionHistory.removeFirst()
        }
    }
    
    // MARK: - Public Methods
    func startMonitoring() {
        // 이미 시작된 경우 중복 시작 방지
        if monitor.queue == nil {
            monitor.start(queue: queue)
        }
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    func getConnectionStats() -> ConnectionStats {
        let totalEvents = connectionHistory.count
        let connectionEvents = connectionHistory.filter { $0.type == .connected }.count
        let disconnectionEvents = connectionHistory.filter { $0.type == .disconnected }.count
        
        let averageUptime: TimeInterval
        if let lastConnection = connectionHistory.last(where: { $0.type == .connected })?.timestamp {
            averageUptime = Date().timeIntervalSince(lastConnection)
        } else {
            averageUptime = 0
        }
        
        return ConnectionStats(
            totalEvents: totalEvents,
            connectionEvents: connectionEvents,
            disconnectionEvents: disconnectionEvents,
            averageUptime: averageUptime,
            currentConnectionType: connectionType,
            currentConnectionQuality: connectionQuality,
            isExpensive: isExpensive,
            isConstrained: isConstrained
        )
    }
    
    func isConnectionStable() -> Bool {
        // 최근 5분간 연결 상태 확인
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        let recentEvents = connectionHistory.filter { $0.timestamp > fiveMinutesAgo }
        
        let disconnectionCount = recentEvents.filter { $0.type == .disconnected }.count
        return disconnectionCount <= 1 // 1회 이하의 연결 끊김만 허용
    }
    
    func shouldRetryConnection() -> Bool {
        // 연결 재시도 조건 확인
        guard !isConnected else { return false }
        
        let lastDisconnection = connectionHistory.last(where: { $0.type == .disconnected })?.timestamp
        guard let lastDisconnection = lastDisconnection else { return true }
        
        // 마지막 연결 끊김 후 30초 경과 시 재시도
        return Date().timeIntervalSince(lastDisconnection) > 30
    }
}

// MARK: - Supporting Types
enum ConnectionType: String, CaseIterable {
    case wifi = "WiFi"
    case cellular = "Cellular"
    case ethernet = "Ethernet"
    case loopback = "Loopback"
    case unknown = "Unknown"
}

enum ConnectionQuality: String, CaseIterable {
    case excellent = "Excellent"
    case good = "Good"
    case fair = "Fair"
    case poor = "Poor"
    case unknown = "Unknown"
}

enum ConnectionEventType {
    case connected
    case disconnected
}

struct ConnectionEvent {
    let type: ConnectionEventType
    let timestamp: Date
    let connectionType: ConnectionType
    let connectionQuality: ConnectionQuality
}

struct ConnectionStats {
    let totalEvents: Int
    let connectionEvents: Int
    let disconnectionEvents: Int
    let averageUptime: TimeInterval
    let currentConnectionType: ConnectionType
    let currentConnectionQuality: ConnectionQuality
    let isExpensive: Bool
    let isConstrained: Bool
}

// MARK: - Notification Names
extension Notification.Name {
    static let networkStatusChanged = Notification.Name("networkStatusChanged")
} 
