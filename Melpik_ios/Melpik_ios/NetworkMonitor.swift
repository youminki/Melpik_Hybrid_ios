//
//  NetworkMonitor.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import SwiftUI
import Network

@MainActor
class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    @Published var isConnected = false
    private var isMonitoring = false
    
    init() {
        startMonitoring()
    }
    
    deinit {
        print("NetworkMonitor deinit")
        monitor.cancel()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                print("Network status changed: \(path.status)")
            }
        }
        
        monitor.start(queue: DispatchQueue.global())
        print("Network monitoring started")
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false
        monitor.cancel()
        print("Network monitoring stopped")
    }
} 
