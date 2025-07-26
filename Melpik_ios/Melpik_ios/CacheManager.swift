//
//  CacheManager.swift
//  Melpik_ios
//
//  Created by 유민기 on 6/30/25.
//

import Foundation
import UIKit

@MainActor
class CacheManager: ObservableObject {
    @Published var cacheSize: Int64 = 0
    @Published var cacheItemCount = 0
    @Published var isClearingCache = false
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 100 * 1024 * 1024 // 100MB
    private let maxCacheAge: TimeInterval = 7 * 24 * 60 * 60 // 7일
    
    static let shared = CacheManager()
    
    init() {
        // 캐시 디렉토리 설정
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("MelpikCache")
        
        // 캐시 디렉토리 생성
        createCacheDirectoryIfNeeded()
        
        // 캐시 상태 업데이트
        updateCacheStats()
    }
    
    // MARK: - Cache Directory Management
    private func createCacheDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            do {
                try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
                print("Cache directory created at: \(cacheDirectory.path)")
            } catch {
                print("Failed to create cache directory: \(error)")
            }
        }
    }
    
    // MARK: - Cache Operations
    func cacheData(_ data: Data, for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        do {
            try data.write(to: fileURL)
            
            // 캐시 메타데이터 저장
            let metadata = CacheMetadata(
                key: key,
                size: Int64(data.count),
                createdAt: Date(),
                lastAccessed: Date()
            )
            saveMetadata(metadata)
            
            updateCacheStats()
            cleanupOldCache()
        } catch {
            print("Failed to cache data for key \(key): \(error)")
        }
    }
    
    func getCachedData(for key: String) -> Data? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            
            // 마지막 접근 시간 업데이트
            updateLastAccessed(for: key)
            
            return data
        } catch {
            print("Failed to read cached data for key \(key): \(error)")
            return nil
        }
    }
    
    func removeCachedData(for key: String) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        
        do {
            try fileManager.removeItem(at: fileURL)
            removeMetadata(for: key)
            updateCacheStats()
        } catch {
            print("Failed to remove cached data for key \(key): \(error)")
        }
    }
    
    func clearAllCache() {
        isClearingCache = true
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
            
            // 메타데이터 파일도 삭제
            let metadataURL = cacheDirectory.appendingPathComponent("metadata.json")
            if fileManager.fileExists(atPath: metadataURL.path) {
                try fileManager.removeItem(at: metadataURL)
            }
            
            updateCacheStats()
            print("All cache cleared successfully")
        } catch {
            print("Failed to clear cache: \(error)")
        }
        
        isClearingCache = false
    }
    
    // MARK: - Cache Metadata Management
    private func saveMetadata(_ metadata: CacheMetadata) {
        var allMetadata = loadAllMetadata()
        
        // 기존 메타데이터 업데이트 또는 새로 추가
        if let index = allMetadata.firstIndex(where: { $0.key == metadata.key }) {
            allMetadata[index] = metadata
        } else {
            allMetadata.append(metadata)
        }
        
        saveAllMetadata(allMetadata)
    }
    
    private func updateLastAccessed(for key: String) {
        var allMetadata = loadAllMetadata()
        
        if let index = allMetadata.firstIndex(where: { $0.key == key }) {
            allMetadata[index].lastAccessed = Date()
            saveAllMetadata(allMetadata)
        }
    }
    
    private func removeMetadata(for key: String) {
        var allMetadata = loadAllMetadata()
        allMetadata.removeAll { $0.key == key }
        saveAllMetadata(allMetadata)
    }
    
    private func loadAllMetadata() -> [CacheMetadata] {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.json")
        
        guard fileManager.fileExists(atPath: metadataURL.path),
              let data = try? Data(contentsOf: metadataURL),
              let metadata = try? JSONDecoder().decode([CacheMetadata].self, from: data) else {
            return []
        }
        
        return metadata
    }
    
    private func saveAllMetadata(_ metadata: [CacheMetadata]) {
        let metadataURL = cacheDirectory.appendingPathComponent("metadata.json")
        
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL)
        } catch {
            print("Failed to save metadata: \(error)")
        }
    }
    
    // MARK: - Cache Statistics
    private func updateCacheStats() {
        let allMetadata = loadAllMetadata()
        
        cacheSize = allMetadata.reduce(0) { $0 + $1.size }
        cacheItemCount = allMetadata.count
    }
    
    // MARK: - Cache Cleanup
    private func cleanupOldCache() {
        let allMetadata = loadAllMetadata()
        let now = Date()
        
        // 오래된 캐시 항목 제거
        let expiredItems = allMetadata.filter { now.timeIntervalSince($0.createdAt) > maxCacheAge }
        
        for item in expiredItems {
            removeCachedData(for: item.key)
        }
        
        // 캐시 크기 제한 확인
        if cacheSize > maxCacheSize {
            cleanupBySize()
        }
    }
    
    private func cleanupBySize() {
        var allMetadata = loadAllMetadata()
        
        // 마지막 접근 시간순으로 정렬
        allMetadata.sort { $0.lastAccessed < $1.lastAccessed }
        
        var currentSize = cacheSize
        
        for item in allMetadata {
            if currentSize <= maxCacheSize {
                break
            }
            
            removeCachedData(for: item.key)
            currentSize -= item.size
        }
    }
    
    // MARK: - Web Content Caching
    func cacheWebContent(_ html: String, for url: URL) {
        let key = generateCacheKey(for: url)
        guard let data = html.data(using: .utf8) else { return }
        
        cacheData(data, for: key)
    }
    
    func getCachedWebContent(for url: URL) -> String? {
        let key = generateCacheKey(for: url)
        guard let data = getCachedData(for: key) else { return nil }
        
        return String(data: data, encoding: .utf8)
    }
    
    private func generateCacheKey(for url: URL) -> String {
        return url.absoluteString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? url.absoluteString
    }
    
    // MARK: - Image Caching
    func cacheImage(_ image: UIImage, for key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        cacheData(data, for: "image_\(key)")
    }
    
    func getCachedImage(for key: String) -> UIImage? {
        guard let data = getCachedData(for: "image_\(key)") else { return nil }
        return UIImage(data: data)
    }
    
    // MARK: - Offline Content Management
    func saveOfflineContent(_ content: OfflineContent) {
        let key = "offline_\(content.id)"
        
        do {
            let data = try JSONEncoder().encode(content)
            cacheData(data, for: key)
        } catch {
            print("Failed to save offline content: \(error)")
        }
    }
    
    func getOfflineContent(for id: String) -> OfflineContent? {
        let key = "offline_\(id)"
        
        guard let data = getCachedData(for: key) else { return nil }
        
        do {
            return try JSONDecoder().decode(OfflineContent.self, from: data)
        } catch {
            print("Failed to decode offline content: \(error)")
            return nil
        }
    }
    
    func getAllOfflineContent() -> [OfflineContent] {
        let allMetadata = loadAllMetadata()
        let offlineKeys = allMetadata.filter { $0.key.hasPrefix("offline_") }.map { $0.key }
        
        var offlineContent: [OfflineContent] = []
        
        for key in offlineKeys {
            if let content = getOfflineContent(for: String(key.dropFirst(8))) { // "offline_" 제거
                offlineContent.append(content)
            }
        }
        
        return offlineContent
    }
    
    // MARK: - Cache Health Check
    func performCacheHealthCheck() -> CacheHealthStatus {
        let allMetadata = loadAllMetadata()
        let now = Date()
        
        let expiredItems = allMetadata.filter { now.timeIntervalSince($0.createdAt) > maxCacheAge }
        let oversizedItems = allMetadata.filter { $0.size > 10 * 1024 * 1024 } // 10MB 이상
        
        var issues: [String] = []
        
        if !expiredItems.isEmpty {
            issues.append("\(expiredItems.count)개의 만료된 캐시 항목")
        }
        
        if !oversizedItems.isEmpty {
            issues.append("\(oversizedItems.count)개의 과대한 캐시 항목")
        }
        
        if cacheSize > maxCacheSize {
            issues.append("캐시 크기 초과")
        }
        
        return CacheHealthStatus(
            isHealthy: issues.isEmpty,
            issues: issues,
            totalItems: cacheItemCount,
            totalSize: cacheSize,
            expiredItemsCount: expiredItems.count,
            oversizedItemsCount: oversizedItems.count
        )
    }
    
    // MARK: - Cache Export/Import
    func exportCacheInfo() -> CacheExport {
        let allMetadata = loadAllMetadata()
        
        return CacheExport(
            totalItems: cacheItemCount,
            totalSize: cacheSize,
            items: allMetadata,
            exportDate: Date()
        )
    }
}

// MARK: - Supporting Models
struct CacheMetadata: Codable {
    let key: String
    let size: Int64
    let createdAt: Date
    var lastAccessed: Date
}

struct OfflineContent: Codable {
    let id: String
    let title: String
    let content: String
    let url: String
    let createdAt: Date
    let lastAccessed: Date
    let size: Int64
}

struct CacheHealthStatus {
    let isHealthy: Bool
    let issues: [String]
    let totalItems: Int
    let totalSize: Int64
    let expiredItemsCount: Int
    let oversizedItemsCount: Int
}

struct CacheExport {
    let totalItems: Int
    let totalSize: Int64
    let items: [CacheMetadata]
    let exportDate: Date
} 