//
//  OfflineDataManager.swift
//  DealScout
//
//  Offline Mode Support for Previously Loaded Data
//

import Foundation
import Combine

// MARK: - Offline Data Manager

/// Manager for offline mode support with previously loaded data
final class OfflineDataManager: ObservableObject {

    static let shared = OfflineDataManager()

    // MARK: - Published Properties

    @Published var isOfflineMode: Bool = false
    @Published var hasOfflineData: Bool = false

    // MARK: - Configuration

    private let fileManager = FileManager.default
    private let offlineDataDirectory: URL
    private let cacheManager = CacheManager.shared

    // MARK: - Network Monitoring

    private var networkMonitor: NetworkMonitor?

    // MARK: - Initialization

    private init() {
        // Setup offline data directory
        let documents = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.offlineDataDirectory = documents.appendingPathComponent("OfflineData", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: offlineDataDirectory, withIntermediateDirectories: true)

        // Initialize network monitoring
        self.networkMonitor = NetworkMonitor()
        setupNetworkMonitoring()

        // Check for existing offline data
        checkOfflineDataAvailability()
    }

    // MARK: - Network Monitoring

    private func setupNetworkMonitoring() {
        networkMonitor?.$isConnected
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isConnected in
                self?.isOfflineMode = !isConnected
            }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Offline Data Management

    /// Save search results for offline access
    func saveSearchResults(_ listings: [EbayListing], forQuery query: String) async {
        let searchData = OfflineSearchData(
            query: query,
            listings: listings,
            timestamp: Date()
        )

        do {
            let encoded = try JSONEncoder().encode(searchData)
            let fileURL = offlineDataDirectory.appendingPathComponent("search_\(query.toSafeFilename()).json")
            try encoded.write(to: fileURL)

            await MainActor.run {
                self.hasOfflineData = true
            }

            print("✅ Saved \(listings.count) listings for offline access")
        } catch {
            print("❌ Failed to save offline search data: \(error)")
        }
    }

    /// Get offline search results
    func getOfflineSearchResults(forQuery query: String) async -> [EbayListing]? {
        let fileURL = offlineDataDirectory.appendingPathComponent("search_\(query.toSafeFilename()).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let searchData = try JSONDecoder().decode(OfflineSearchData.self, from: data)

            // Check if data is not too old (e.g., within 7 days)
            let daysSinceCache = Calendar.current.dateComponents([.day], from: searchData.timestamp, to: Date()).day ?? 0

            if daysSinceCache <= 7 {
                print("✅ Retrieved \(searchData.listings.count) listings from offline cache")
                return searchData.listings
            } else {
                // Remove stale data
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
        } catch {
            print("❌ Failed to retrieve offline search data: \(error)")
            return nil
        }
    }

    /// Save market analysis for offline access
    func saveMarketAnalysis(_ analysis: MarketAnalysis, forKeywords keywords: String) async {
        let analysisData = OfflineMarketAnalysis(
            keywords: keywords,
            analysis: analysis,
            timestamp: Date()
        )

        do {
            let encoded = try JSONEncoder().encode(analysisData)
            let fileURL = offlineDataDirectory.appendingPathComponent("analysis_\(keywords.toSafeFilename()).json")
            try encoded.write(to: fileURL)

            print("✅ Saved market analysis for offline access")
        } catch {
            print("❌ Failed to save offline market analysis: \(error)")
        }
    }

    /// Get offline market analysis
    func getOfflineMarketAnalysis(forKeywords keywords: String) async -> MarketAnalysis? {
        let fileURL = offlineDataDirectory.appendingPathComponent("analysis_\(keywords.toSafeFilename()).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let analysisData = try JSONDecoder().decode(OfflineMarketAnalysis.self, from: data)

            // Check if data is not too old (e.g., within 7 days)
            let daysSinceCache = Calendar.current.dateComponents([.day], from: analysisData.timestamp, to: Date()).day ?? 0

            if daysSinceCache <= 7 {
                print("✅ Retrieved market analysis from offline cache")
                return analysisData.analysis
            } else {
                // Remove stale data
                try? fileManager.removeItem(at: fileURL)
                return nil
            }
        } catch {
            print("❌ Failed to retrieve offline market analysis: \(error)")
            return nil
        }
    }

    /// Get all offline searches
    func getAllOfflineSearches() async -> [OfflineSearchSummary] {
        var summaries: [OfflineSearchSummary] = []

        do {
            let files = try fileManager.contentsOfDirectory(at: offlineDataDirectory, includingPropertiesForKeys: [.creationDateKey])

            for fileURL in files where fileURL.lastPathComponent.hasPrefix("search_") {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let searchData = try JSONDecoder().decode(OfflineSearchData.self, from: data)

                    summaries.append(OfflineSearchSummary(
                        query: searchData.query,
                        itemCount: searchData.listings.count,
                        timestamp: searchData.timestamp
                    ))
                } catch {
                    print("❌ Failed to read offline search: \(error)")
                }
            }
        } catch {
            print("❌ Failed to enumerate offline searches: \(error)")
        }

        return summaries.sorted { $0.timestamp > $1.timestamp }
    }

    /// Clear offline data
    func clearOfflineData() async {
        do {
            try fileManager.removeItem(at: offlineDataDirectory)
            try fileManager.createDirectory(at: offlineDataDirectory, withIntermediateDirectories: true)

            await MainActor.run {
                self.hasOfflineData = false
            }

            print("✅ Cleared offline data")
        } catch {
            print("❌ Failed to clear offline data: \(error)")
        }
    }

    /// Check if offline data is available
    func checkOfflineDataAvailability() {
        do {
            let files = try fileManager.contentsOfDirectory(at: offlineDataDirectory, includingPropertiesForKeys: nil)
            DispatchQueue.main.async {
                self.hasOfflineData = !files.isEmpty
            }
        } catch {
            DispatchQueue.main.async {
                self.hasOfflineData = false
            }
        }
    }

    /// Get offline data size
    func getOfflineDataSize() async -> Int64 {
        var totalSize: Int64 = 0

        if let files = try? fileManager.contentsOfDirectory(at: offlineDataDirectory, includingPropertiesForKeys: [.fileSizeKey]) {
            for file in files {
                if let fileSize = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(fileSize)
                }
            }
        }

        return totalSize
    }
}

// MARK: - Offline Data Models

/// Offline search data
struct OfflineSearchData: Codable {
    let query: String
    let listings: [EbayListing]
    let timestamp: Date
}

/// Offline market analysis
struct OfflineMarketAnalysis: Codable {
    let keywords: String
    let analysis: MarketAnalysis
    let timestamp: Date
}

/// Offline search summary
struct OfflineSearchSummary: Identifiable {
    let id = UUID()
    let query: String
    let itemCount: Int
    let timestamp: Date
}

// MARK: - Network Monitor

/// Simple network connectivity monitor
final class NetworkMonitor: ObservableObject {
    @Published var isConnected: Bool = true

    private var reachability: URLSessionTask?

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        // Simple connectivity check using URLSession
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkConnectivity()
        }

        // Initial check
        checkConnectivity()
    }

    private func checkConnectivity() {
        guard let url = URL(string: "https://www.apple.com") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 5.0

        let task = URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                if let httpResponse = response as? HTTPURLResponse {
                    self?.isConnected = (200...299).contains(httpResponse.statusCode)
                } else {
                    self?.isConnected = error == nil
                }
            }
        }

        task.resume()
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