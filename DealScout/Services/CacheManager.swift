//
//  CacheManager.swift
//  DealScout
//
//  API Response and Image Caching Service
//

import Foundation
import SwiftUI
import Combine

// MARK: - Cache Manager

/// Manager for caching API responses and images with expiration support
final class CacheManager: ObservableObject {

    static let shared = CacheManager()

    // MARK: - Configuration

    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let imageCacheDirectory: URL

    // Default cache durations
    private let defaultAPICacheExpiration: TimeInterval = 300 // 5 minutes
    private let defaultImageCacheExpiration: TimeInterval = 86400 // 24 hours

    // MARK: - In-Memory Cache

    private var memoryCache: [String: CachedItem] = [:]
    private let cacheQueue = DispatchQueue(label: "com.dealscout.cache", attributes: .concurrent)

    // MARK: - Initialization

    private init() {
        // Setup cache directories
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        self.cacheDirectory = caches.appendingPathComponent("APICache", isDirectory: true)
        self.imageCacheDirectory = caches.appendingPathComponent("ImageCache", isDirectory: true)

        // Create directories if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: imageCacheDirectory, withIntermediateDirectories: true)

        // Clean expired cache on init
        Task {
            await cleanExpiredCache()
        }
    }

    // MARK: - API Response Caching

    /// Save API response to cache
    func cacheAPIResponse<T: Codable>(_ data: T, forKey key: String, expiration: TimeInterval? = nil) async {
        let expirationDate = Date().addingTimeInterval(expiration ?? defaultAPICacheExpiration)
        let cachedItem = CachedItem(data: data, expirationDate: expirationDate)

        // Save to memory cache
        cacheQueue.async(flags: .barrier) {
            self.memoryCache[key] = cachedItem
        }

        // Save to disk cache
        do {
            let encoded = try JSONEncoder().encode(cachedItem)
            let fileURL = cacheDirectory.appendingPathComponent(key.toSafeFilename())
            try encoded.write(to: fileURL)
        } catch {
            print("❌ Failed to cache API response: \(error)")
        }
    }

    /// Retrieve API response from cache
    func getCachedAPIResponse<T: Codable>(forKey key: String, type: T.Type) async -> T? {
        // Check memory cache first
        if let cachedItem = cacheQueue.sync(execute: { memoryCache[key] }) {
            if cachedItem.isValid {
                return cachedItem.data as? T
            } else {
                // Remove expired item
                cacheQueue.async(flags: .barrier) {
                    self.memoryCache.removeValue(forKey: key)
                }
            }
        }

        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(key.toSafeFilename())

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cachedItem = try JSONDecoder().decode(CachedItem.self, from: data)

            if cachedItem.isValid {
                // Update memory cache
                cacheQueue.async(flags: .barrier) {
                    self.memoryCache[key] = cachedItem
                }
                return cachedItem.data as? T
            } else {
                // Remove expired file
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
        } catch {
            print("❌ Failed to retrieve cached API response: \(error)")
            return nil
        }
    }

    // MARK: - Image Caching

    /// Cache image from URL
    @MainActor
    func cacheImage(from url: URL, expiration: TimeInterval? = nil) async -> Data? {
        let cacheKey = url.absoluteString.toSafeFilename()
        let fileURL = imageCacheDirectory.appendingPathComponent(cacheKey)

        // Check if image exists in cache and is still valid
        if let cachedImageData = await getCachedImage(from: url) {
            return cachedImageData
        }

        // Download image
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return nil
            }

            // Save to disk with metadata
            let metadata = ImageCacheMetadata(
                url: url.absoluteString,
                expirationDate: Date().addingTimeInterval(expiration ?? defaultImageCacheExpiration),
                contentType: httpResponse.mimeType ?? "image/jpeg"
            )

            let cacheData = ImageCacheData(imageData: data, metadata: metadata)
            let encoded = try JSONEncoder().encode(cacheData)
            try encoded.write(to: fileURL)

            return data
        } catch {
            print("❌ Failed to cache image: \(error)")
            return nil
        }
    }

    /// Get cached image
    func getCachedImage(from url: URL) async -> Data? {
        let cacheKey = url.absoluteString.toSafeFilename()
        let fileURL = imageCacheDirectory.appendingPathComponent(cacheKey)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let cacheData = try JSONDecoder().decode(ImageCacheData.self, from: data)

            // Check expiration
            if cacheData.metadata.expirationDate > Date() {
                return cacheData.imageData
            } else {
                // Remove expired image
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
        } catch {
            print("❌ Failed to retrieve cached image: \(error)")
            return nil
        }
    }

    // MARK: - Cache Management

    /// Clean expired cache entries
    func cleanExpiredCache() async {
        // Clean API cache
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)

            for fileURL in files {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let cachedItem = try JSONDecoder().decode(CachedItem.self, from: data)

                    if !cachedItem.isValid {
                        try fileManager.removeItem(at: fileURL)
                    }
                } catch {
                    // Remove corrupted files
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("❌ Failed to clean API cache: \(error)")
        }

        // Clean image cache
        do {
            let imageFiles = try fileManager.contentsOfDirectory(at: imageCacheDirectory, includingPropertiesForKeys: nil)

            for fileURL in imageFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let cacheData = try JSONDecoder().decode(ImageCacheData.self, from: data)

                    if cacheData.metadata.expirationDate < Date() {
                        try fileManager.removeItem(at: fileURL)
                    }
                } catch {
                    // Remove corrupted files
                    try? fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("❌ Failed to clean image cache: \(error)")
        }

        // Clean memory cache
        cacheQueue.async(flags: .barrier) {
            self.memoryCache = self.memoryCache.filter { $0.value.isValid }
        }
    }

    /// Clear all cache
    func clearAllCache() async {
        // Clear memory cache
        cacheQueue.async(flags: .barrier) {
            self.memoryCache.removeAll()
        }

        // Clear disk cache
        do {
            try fileManager.removeItem(at: cacheDirectory)
            try fileManager.removeItem(at: imageCacheDirectory)

            // Recreate directories
            try fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: imageCacheDirectory, withIntermediateDirectories: true)
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
    }

    /// Get cache size
    func getCacheSize() async -> (apiCache: Int64, imageCache: Int64) {
        var apiSize: Int64 = 0
        var imageSize: Int64 = 0

        // Calculate API cache size
        if let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    apiSize += Int64(fileSize)
                }
            }
        }

        // Calculate image cache size
        if let files = try? fileManager.contentsOfDirectory(at: imageCacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    imageSize += Int64(fileSize)
                }
            }
        }

        return (apiSize, imageSize)
    }
}

// MARK: - Cache Models

/// Cached item wrapper with expiration
struct CachedItem: Codable {
    let data: AnyCodableValue
    let expirationDate: Date

    var isValid: Bool {
        return expirationDate > Date()
    }

    init<T: Codable>(data: T, expirationDate: Date) {
        self.data = AnyCodableValue(data)
        self.expirationDate = expirationDate
    }
}

/// Image cache metadata
struct ImageCacheMetadata: Codable {
    let url: String
    let expirationDate: Date
    let contentType: String
}

/// Image cache data
struct ImageCacheData: Codable {
    let imageData: Data
    let metadata: ImageCacheMetadata
}

/// Type-erased codable wrapper
struct AnyCodableValue: Codable {
    let value: Any

    init<T: Codable>(_ value: T) {
        self.value = value
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let dictValue = try? container.decode([String: AnyCodableValue].self) {
            value = dictValue
        } else if let arrayValue = try? container.decode([AnyCodableValue].self) {
            value = arrayValue
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let dictValue as [String: AnyCodableValue]:
            try container.encode(dictValue)
        case let arrayValue as [AnyCodableValue]:
            try container.encode(arrayValue)
        default:
            let context = EncodingError.Context(codingPath: [], debugDescription: "Unsupported type")
            throw EncodingError.invalidValue(value, context)
        }
    }
}

// MARK: - String Extensions

private extension String {
    /// Convert string to safe filename
    func toSafeFilename() -> String {
        let invalidCharacters = CharacterSet(charactersIn: ":/\\?%*|\"<>")
        return self.components(separatedBy: invalidCharacters).joined(separator: "_")
    }
}
