//
//  PriceIntelligence.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import Foundation

// MARK: - Price History Models

/// Represents a price data point in time
struct PriceDataPoint: Identifiable, Codable {
    let id = UUID()
    let price: Double
    let timestamp: Date
    let listingType: ListingType
    let condition: ItemCondition?
    let itemID: String
    let sellerID: String?

    enum ListingType: String, Codable {
        case auction = "auction"
        case buyItNow = "buy_it_now"
        case bestOffer = "best_offer"
        case sold = "sold"
    }

    enum ItemCondition: String, Codable {
        case new = "new"
        case openBox = "open_box"
        case refurbished = "refurbished"
        case used = "used"
    }
}

/// Historical price data for a specific item/search
struct PriceHistory: Identifiable, Codable {
    let id = UUID()
    let searchQuery: String
    let categoryID: String?
    var dataPoints: [PriceDataPoint]
    let createdDate: Date
    var lastUpdated: Date

    // MARK: - Computed Properties

    var currentAveragePrice: Double? {
        let recentPoints = dataPoints.filter {
            Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.contains($0.timestamp) ?? false
        }
        guard !recentPoints.isEmpty else { return nil }
        return recentPoints.map(\.price).reduce(0, +) / Double(recentPoints.count)
    }

    var priceRange: ClosedRange<Double>? {
        guard !dataPoints.isEmpty else { return nil }
        let prices = dataPoints.map(\.price)
        return prices.min()!...prices.max()!
    }

    var priceTrend: PriceTrend {
        guard dataPoints.count >= 2 else { return .stable }

        let recent = Array(dataPoints.suffix(10))
        let older = Array(dataPoints.prefix(10))

        let recentAvg = recent.map(\.price).reduce(0, +) / Double(recent.count)
        let olderAvg = older.map(\.price).reduce(0, +) / Double(older.count)

        let changePercent = ((recentAvg - olderAvg) / olderAvg) * 100

        if changePercent > 5 {
            return .increasing
        } else if changePercent < -5 {
            return .decreasing
        } else {
            return .stable
        }
    }

    var volatilityScore: Double {
        guard dataPoints.count > 1 else { return 0 }

        let prices = dataPoints.map(\.price)
        let mean = prices.reduce(0, +) / Double(prices.count)
        let variance = prices.map { pow($0 - mean, 2) }.reduce(0, +) / Double(prices.count)
        let standardDeviation = sqrt(variance)

        return (standardDeviation / mean) * 100
    }
}

enum PriceTrend: String, Codable {
    case increasing = "increasing"
    case decreasing = "decreasing"
    case stable = "stable"

    var displayName: String {
        switch self {
        case .increasing: return "Trending Up"
        case .decreasing: return "Trending Down"
        case .stable: return "Stable"
        }
    }

    var systemImageName: String {
        switch self {
        case .increasing: return "arrow.up.right"
        case .decreasing: return "arrow.down.right"
        case .stable: return "minus"
        }
    }

    var color: Color {
        switch self {
        case .increasing: return .red
        case .decreasing: return .green
        case .stable: return .gray
        }
    }
}

// MARK: - Deal Quality Models

/// Represents the quality score of a deal
struct DealScore: Identifiable, Codable {
    let id = UUID()
    let itemID: String
    let searchQuery: String
    let currentPrice: Double
    let score: Double // 0-10 scale
    let factors: [ScoreFactor]
    let calculatedDate: Date
    let confidence: Double // 0-1 scale

    var qualityTier: DealQuality {
        switch score {
        case 8.5...10: return .exceptional
        case 7.0..<8.5: return .excellent
        case 5.5..<7.0: return .good
        case 3.0..<5.5: return .fair
        default: return .poor
        }
    }

    var recommendation: String {
        switch qualityTier {
        case .exceptional:
            return "🔥 Exceptional deal! Act fast - this won't last long."
        case .excellent:
            return "⭐ Excellent deal! Well below market price."
        case .good:
            return "✅ Good deal! Better than average pricing."
        case .fair:
            return "⚠️ Fair deal. Consider waiting for better pricing."
        case .poor:
            return "❌ Poor deal. Price is above market average."
        }
    }
}

enum DealQuality: String, Codable, CaseIterable {
    case exceptional = "exceptional"
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"

    var displayName: String {
        switch self {
        case .exceptional: return "Exceptional"
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }

    var color: Color {
        switch self {
        case .exceptional: return .purple
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
}

/// Factors that contribute to deal score calculation
struct ScoreFactor: Identifiable, Codable {
    let id = UUID()
    let name: String
    let impact: Double // -5 to +5
    let description: String

    static let priceComparison = ScoreFactor(
        name: "Price vs Market",
        impact: 0,
        description: "How this price compares to recent market prices"
    )

    static let sellerReliability = ScoreFactor(
        name: "Seller Rating",
        impact: 0,
        description: "Seller feedback score and reliability metrics"
    )

    static let conditionValue = ScoreFactor(
        name: "Condition Value",
        impact: 0,
        description: "Item condition relative to price point"
    )

    static let timeRemaining = ScoreFactor(
        name: "Time Sensitivity",
        impact: 0,
        description: "Auction time remaining or listing urgency"
    )

    static let shippingCost = ScoreFactor(
        name: "Total Cost",
        impact: 0,
        description: "Including shipping and fees in deal calculation"
    )
}

// MARK: - Watchlist Models

/// Item being watched with price targets
struct WatchlistItem: Identifiable, Codable {
    let id = UUID()
    let itemID: String
    let title: String
    var currentPrice: Double
    var targetPrice: Double?
    let maxPrice: Double?
    let imageURL: String?
    let sellerID: String?
    let endTime: Date?
    let condition: PriceDataPoint.ItemCondition?
    let watchingSince: Date
    var lastChecked: Date
    var priceHistory: [PriceDataPoint]
    var alertsEnabled: Bool
    var isActive: Bool

    // MARK: - Computed Properties

    var priceDropSinceWatching: Double? {
        guard let firstPrice = priceHistory.first?.price else { return nil }
        return ((firstPrice - currentPrice) / firstPrice) * 100
    }

    var shouldAlert: Bool {
        guard alertsEnabled && isActive else { return false }

        if let target = targetPrice, currentPrice <= target {
            return true
        }

        if let max = maxPrice, currentPrice <= max {
            return true
        }

        return false
    }

    var statusText: String {
        if let target = targetPrice {
            if currentPrice <= target {
                return "🎯 Target price reached!"
            } else {
                let diff = currentPrice - target
                return "💰 $\(String(format: "%.2f", diff)) above target"
            }
        } else if let max = maxPrice {
            if currentPrice <= max {
                return "✅ Within price range"
            } else {
                let diff = currentPrice - max
                return "❌ $\(String(format: "%.2f", diff)) over budget"
            }
        }
        return "👁 Watching for changes"
    }

    var urgencyLevel: UrgencyLevel {
        guard let endTime = endTime else { return .none }

        let timeRemaining = endTime.timeIntervalSinceNow

        if timeRemaining < 3600 { // Less than 1 hour
            return .critical
        } else if timeRemaining < 86400 { // Less than 1 day
            return .high
        } else if timeRemaining < 259200 { // Less than 3 days
            return .medium
        } else {
            return .low
        }
    }
}

enum UrgencyLevel: String, Codable {
    case none = "none"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .none: return "No Rush"
        case .low: return "Low Urgency"
        case .medium: return "Medium Urgency"
        case .high: return "High Urgency"
        case .critical: return "Critical - Ending Soon!"
        }
    }

    var color: Color {
        switch self {
        case .none: return .gray
        case .low: return .blue
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Search Templates

/// Pre-configured search templates for common use cases
struct SearchTemplate: Identifiable, Codable {
    let id = UUID()
    var name: String
    var description: String
    var category: TemplateCategory
    var baseFilter: SearchFilter
    var tags: [String]
    var useCount: Int
    let createdDate: Date
    var lastUsed: Date?
    var isUserCreated: Bool
    var isPublic: Bool

    // MARK: - Template Categories

    enum TemplateCategory: String, CaseIterable, Codable {
        case electronics = "electronics"
        case fashion = "fashion"
        case collectibles = "collectibles"
        case automotive = "automotive"
        case home = "home"
        case sports = "sports"
        case gaming = "gaming"
        case books = "books"
        case custom = "custom"

        var displayName: String {
            switch self {
            case .electronics: return "Electronics"
            case .fashion: return "Fashion & Style"
            case .collectibles: return "Collectibles"
            case .automotive: return "Automotive"
            case .home: return "Home & Garden"
            case .sports: return "Sports & Outdoors"
            case .gaming: return "Gaming"
            case .books: return "Books & Media"
            case .custom: return "Custom"
            }
        }

        var systemImageName: String {
            switch self {
            case .electronics: return "iphone"
            case .fashion: return "tshirt"
            case .collectibles: return "star"
            case .automotive: return "car"
            case .home: return "house"
            case .sports: return "sportscourt"
            case .gaming: return "gamecontroller"
            case .books: return "book"
            case .custom: return "wand.and.stars"
            }
        }
    }

}

// MARK: - SearchTemplate Extensions

extension SearchTemplate {
    // MARK: - Predefined Templates

    static let gamingLaptopDeals = SearchTemplate(
        name: "Gaming Laptop Deals",
        description: "High-performance laptops with RTX graphics under $1500",
        category: .gaming,
        baseFilter: SearchFilter(
            name: "Gaming Laptop Deals",
            categoryID: "171485", // Laptops & Netbooks
            maximumPrice: 1500,
            condition: .used,
            listingType: .buyItNow,
            sortOrder: .pricePlusShippingLowest
        ),
        tags: ["gaming", "laptop", "RTX", "deals"],
        useCount: 0,
        createdDate: Date(),
        isUserCreated: false,
        isPublic: true
    )

    static let iphoneDeals = SearchTemplate(
        name: "iPhone Deal Hunter",
        description: "Latest iPhone models with good condition ratings",
        category: .electronics,
        baseFilter: SearchFilter(
            name: "iPhone Deal Hunter",
            categoryID: "9355", // Cell Phones & Accessories
            condition: .used,
            listingType: .buyItNow,
            sortOrder: .pricePlusShippingLowest
        ),
        tags: ["iPhone", "smartphone", "apple"],
        useCount: 0,
        createdDate: Date(),
        isUserCreated: false,
        isPublic: true
    )

    static let collectibleWatches = SearchTemplate(
        name: "Vintage Watch Collector",
        description: "Authentic vintage watches from reputable sellers",
        category: .collectibles,
        baseFilter: SearchFilter(
            name: "Vintage Watch Collector",
            categoryID: "14324", // Watches
            listingType: .auction,
            sellerFilters: SearchFilter.SellerFilter(
                minimumFeedbackScore: 500,
                minimumFeedbackPercentage: 98.0,
                topRatedSellersOnly: true,
                businessSellersOnly: false
            ),
            sortOrder: .endTimeSoonest
        ),
        tags: ["vintage", "watches", "collector", "authentic"],
        useCount: 0,
        createdDate: Date(),
        isUserCreated: false,
        isPublic: true
    )
}

// MARK: - Color Extension

import SwiftUI

extension Color {
    static let dealGreen = Color.green
    static let dealRed = Color.red
    static let dealBlue = Color.blue
    static let dealOrange = Color.orange
    static let dealPurple = Color.purple
}
