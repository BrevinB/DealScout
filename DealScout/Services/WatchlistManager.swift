//
//  WatchlistManager.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import Foundation
import UserNotifications
import UIKit
import Combine

// MARK: - Watchlist Manager

/// Manages user's watchlist items and price target monitoring
class WatchlistManager: ObservableObject {

    // MARK: - Properties

    @Published var watchlistItems: [WatchlistItem] = []
    @Published var activeAlerts: [PriceAlert] = []

    private let userDefaults = UserDefaults.standard
    private let watchlistKey = "UserWatchlist"
    private let alertsKey = "ActivePriceAlerts"

    // MARK: - Initialization

    init() {
        loadWatchlist()
        loadAlerts()
        setupNotificationObservers()
    }

    // MARK: - Watchlist Management

    /// Add item to watchlist
    func addToWatchlist(
        itemID: String,
        title: String,
        currentPrice: Double,
        targetPrice: Double? = nil,
        maxPrice: Double? = nil,
        imageURL: String? = nil,
        sellerID: String? = nil,
        endTime: Date? = nil,
        condition: PriceDataPoint.ItemCondition? = nil
    ) {
        let item = WatchlistItem(
            itemID: itemID,
            title: title,
            currentPrice: currentPrice,
            targetPrice: targetPrice,
            maxPrice: maxPrice,
            imageURL: imageURL,
            sellerID: sellerID,
            endTime: endTime,
            condition: condition,
            watchingSince: Date(),
            lastChecked: Date(),
            priceHistory: [PriceDataPoint(
                price: currentPrice,
                timestamp: Date(),
                listingType: .buyItNow,
                condition: condition,
                itemID: itemID,
                sellerID: sellerID
            )],
            alertsEnabled: true,
            isActive: true
        )

        watchlistItems.append(item)
        saveWatchlist()

        // Create price alert if target price is set
        if let target = targetPrice {
            createPriceAlert(for: item, targetPrice: target)
        }
    }

    /// Remove item from watchlist
    func removeFromWatchlist(_ item: WatchlistItem) {
        watchlistItems.removeAll { $0.id == item.id }
        activeAlerts.removeAll { $0.itemID == item.itemID }
        saveWatchlist()
        saveAlerts()
    }

    /// Update price for watchlist item
    func updatePrice(for itemID: String, newPrice: Double, timestamp: Date = Date()) {
        guard let index = watchlistItems.firstIndex(where: { $0.itemID == itemID }) else { return }

        let oldPrice = watchlistItems[index].currentPrice
        watchlistItems[index].currentPrice = newPrice
        watchlistItems[index].lastChecked = timestamp

        // Add to price history
        let dataPoint = PriceDataPoint(
            price: newPrice,
            timestamp: timestamp,
            listingType: .buyItNow,
            condition: watchlistItems[index].condition,
            itemID: itemID,
            sellerID: watchlistItems[index].sellerID
        )
        watchlistItems[index].priceHistory.append(dataPoint)

        // Check if alert should be triggered
        let item = watchlistItems[index]
        if item.shouldAlert {
            triggerPriceAlert(for: item, oldPrice: oldPrice, newPrice: newPrice)
        }

        saveWatchlist()
    }

    /// Update price target for item
    func updatePriceTarget(for itemID: String, targetPrice: Double?) {
        guard let index = watchlistItems.firstIndex(where: { $0.itemID == itemID }) else { return }

        watchlistItems[index].targetPrice = targetPrice

        // Remove existing alerts for this item
        activeAlerts.removeAll { $0.itemID == itemID }

        // Create new alert if target price is set
        if let target = targetPrice {
            createPriceAlert(for: watchlistItems[index], targetPrice: target)
        }

        saveWatchlist()
        saveAlerts()
    }

    /// Toggle alerts for item
    func toggleAlerts(for itemID: String) {
        guard let index = watchlistItems.firstIndex(where: { $0.itemID == itemID }) else { return }

        watchlistItems[index].alertsEnabled.toggle()
        saveWatchlist()
    }

    /// Get items that need price updates
    func getItemsNeedingUpdate() -> [WatchlistItem] {
        let updateThreshold = Date().addingTimeInterval(-3600) // 1 hour ago
        return watchlistItems.filter {
            $0.isActive && $0.lastChecked < updateThreshold
        }
    }

    /// Get items sorted by urgency
    func getItemsByUrgency() -> [WatchlistItem] {
        return watchlistItems
            .filter { $0.isActive }
            .sorted { item1, item2 in
                // Sort by urgency level, then by target proximity
                if item1.urgencyLevel != item2.urgencyLevel {
                    return item1.urgencyLevel.rawValue > item2.urgencyLevel.rawValue
                }

                // If both have target prices, sort by proximity to target
                if let target1 = item1.targetPrice, let target2 = item2.targetPrice {
                    let proximity1 = abs(item1.currentPrice - target1) / target1
                    let proximity2 = abs(item2.currentPrice - target2) / target2
                    return proximity1 < proximity2
                }

                return item1.watchingSince > item2.watchingSince
            }
    }

    /// Get price drop opportunities
    func getPriceDropOpportunities() -> [WatchlistItem] {
        return watchlistItems
            .filter { $0.isActive }
            .compactMap { item in
                guard let drop = item.priceDropSinceWatching, drop > 5 else { return nil }
                return item
            }
            .sorted { ($0.priceDropSinceWatching ?? 0) > ($1.priceDropSinceWatching ?? 0) }
    }

    // MARK: - Alert Management

    /// Create price alert for item
    private func createPriceAlert(for item: WatchlistItem, targetPrice: Double) {
        let alert = PriceAlert(
            itemID: item.itemID,
            itemTitle: item.title,
            targetPrice: targetPrice,
            currentPrice: item.currentPrice,
            alertType: .targetReached,
            createdDate: Date(),
            isActive: true,
            oldPrice: nil
        )

        activeAlerts.append(alert)
        saveAlerts()

        // Schedule local notification
        scheduleLocalNotification(for: alert)
    }

    /// Trigger price alert
    private func triggerPriceAlert(for item: WatchlistItem, oldPrice: Double, newPrice: Double) {
        let alertType: PriceAlert.AlertType = newPrice < oldPrice ? .priceDropped : .targetReached

        let alert = PriceAlert(
            itemID: item.itemID,
            itemTitle: item.title,
            targetPrice: item.targetPrice ?? newPrice,
            currentPrice: newPrice,
            alertType: alertType,
            createdDate: Date(),
            isActive: true,
            oldPrice: oldPrice
        )

        activeAlerts.append(alert)
        saveAlerts()

        // Send local notification
        sendPriceAlertNotification(for: alert)
    }

    /// Schedule local notification for price target
    private func scheduleLocalNotification(for alert: PriceAlert) {
        let content = UNMutableNotificationContent()
        content.title = "Price Target Set"
        content.body = "Watching \(alert.itemTitle) for price of $\(String(format: "%.2f", alert.targetPrice))"
        content.sound = .default

        let identifier = "price_target_\(alert.itemID)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Send price alert notification
    private func sendPriceAlertNotification(for alert: PriceAlert) {
        let content = UNMutableNotificationContent()

        switch alert.alertType {
        case .targetReached:
            content.title = "🎯 Price Target Reached!"
            content.body = "\(alert.itemTitle) is now $\(String(format: "%.2f", alert.currentPrice))"
        case .priceDropped:
            let drop = ((alert.oldPrice ?? 0.0) - alert.currentPrice) / (alert.oldPrice ?? 1.0) * 100
            content.title = "📉 Price Drop Alert!"
            content.body = "\(alert.itemTitle) dropped \(String(format: "%.1f", drop))% to $\(String(format: "%.2f", alert.currentPrice))"
        case .endingSoon:
            content.title = "⏰ Auction Ending Soon!"
            content.body = "\(alert.itemTitle) auction ends soon at $\(String(format: "%.2f", alert.currentPrice))"
        }

        content.sound = .default

        let identifier = "price_alert_\(UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Statistics

    /// Get watchlist statistics
    func getWatchlistStatistics() -> WatchlistStatistics {
        let activeItems = watchlistItems.filter { $0.isActive }

        let totalValue: Double = activeItems.reduce(0.0) { $0 + $1.currentPrice }
        let targetSavings = activeItems.compactMap { item in
            guard let target = item.targetPrice else { return nil }
            return max(0.0, item.currentPrice - target)
        }.reduce(0.0, +)

        let priceDrops = activeItems.compactMap { $0.priceDropSinceWatching }.filter { $0 > 0.0 }
        let averagePriceDrop = priceDrops.isEmpty ? 0.0 : priceDrops.reduce(0.0, +) / Double(priceDrops.count)

        let alertsTriggered = activeAlerts.filter {
            Calendar.current.isDateInToday($0.createdDate)
        }.count

        return WatchlistStatistics(
            totalItems: activeItems.count,
            totalValue: totalValue,
            averageItemValue: activeItems.isEmpty ? 0 : totalValue / Double(activeItems.count),
            potentialSavings: targetSavings,
            averagePriceDrop: averagePriceDrop,
            alertsTriggeredToday: alertsTriggered,
            itemsWithPriceDrops: priceDrops.count
        )
    }

    // MARK: - Persistence

    private func saveWatchlist() {
        guard let data = try? JSONEncoder().encode(watchlistItems) else { return }
        userDefaults.set(data, forKey: watchlistKey)
    }

    private func loadWatchlist() {
        guard let data = userDefaults.data(forKey: watchlistKey),
              let items = try? JSONDecoder().decode([WatchlistItem].self, from: data) else {
            watchlistItems = []
            return
        }
        watchlistItems = items
    }

    private func saveAlerts() {
        guard let data = try? JSONEncoder().encode(activeAlerts) else { return }
        userDefaults.set(data, forKey: alertsKey)
    }

    private func loadAlerts() {
        guard let data = userDefaults.data(forKey: alertsKey),
              let alerts = try? JSONDecoder().decode([PriceAlert].self, from: data) else {
            activeAlerts = []
            return
        }
        activeAlerts = alerts
    }

    private func setupNotificationObservers() {
        // Set up notification observers for app lifecycle events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        // Check for price updates when app becomes active
        // This would trigger price refresh in a real implementation
    }
}

// MARK: - Price Alert Model

/// Represents a price alert notification
struct PriceAlert: Identifiable, Codable {
    let id = UUID()
    let itemID: String
    let itemTitle: String
    let targetPrice: Double
    let currentPrice: Double
    let alertType: AlertType
    let createdDate: Date
    var isActive: Bool
    let oldPrice: Double?

    enum AlertType: String, Codable {
        case targetReached = "target_reached"
        case priceDropped = "price_dropped"
        case endingSoon = "ending_soon"

        var displayName: String {
            switch self {
            case .targetReached: return "Target Reached"
            case .priceDropped: return "Price Dropped"
            case .endingSoon: return "Ending Soon"
            }
        }

        var systemImageName: String {
            switch self {
            case .targetReached: return "target"
            case .priceDropped: return "arrow.down.circle"
            case .endingSoon: return "clock"
            }
        }
    }
}

// MARK: - Watchlist Statistics

/// Statistics about the user's watchlist
struct WatchlistStatistics: Codable {
    let totalItems: Int
    let totalValue: Double
    let averageItemValue: Double
    let potentialSavings: Double
    let averagePriceDrop: Double
    let alertsTriggeredToday: Int
    let itemsWithPriceDrops: Int

    var formattedTotalValue: String {
        return String(format: "$%.2f", totalValue)
    }

    var formattedPotentialSavings: String {
        return String(format: "$%.2f", potentialSavings)
    }

    var formattedAveragePriceDrop: String {
        return String(format: "%.1f%%", averagePriceDrop)
    }
}

