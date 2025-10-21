//
//  ComparisonModels.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import Foundation
import SwiftUI

// MARK: - Comparison Models

/// A collection of listings for side-by-side comparison
struct ListingComparison: Identifiable, Codable {

    // MARK: - Properties

    let id = UUID()
    var listings: [EbayListing] = []
    let createdDate: Date = Date()

    // MARK: - Computed Properties

    var title: String {
        if listings.isEmpty {
            return "Empty Comparison"
        } else if listings.count == 1 {
            return "Compare with \(listings[0].title)"
        } else {
            return "\(listings.count) Items Comparison"
        }
    }

    // MARK: - Methods

    func canAddListing() -> Bool {
        return listings.count < 4 // Limit to 4 items for better UI
    }
}

/// A price data point for historical tracking
struct PriceHistoryPoint: Codable, Identifiable {

    // MARK: - Properties

    let id = UUID()
    let itemID: String
    let price: Double
    let timestamp: Date
    let source: String // "current", "historical", "completed"
    let condition: String?

    // MARK: - Computed Properties

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: timestamp)
    }

    // MARK: - Custom Coding Keys

    enum CodingKeys: String, CodingKey {
        case itemID = "itemId"
        case price, timestamp, source, condition
    }
}

/// Historical price tracking for an item
struct ItemPriceHistory: Codable, Identifiable {

    // MARK: - Properties

    let id = UUID()
    let itemID: String
    let title: String
    var pricePoints: [PriceHistoryPoint] = []
    var lastUpdated: Date = Date()

    // MARK: - Computed Properties

    var currentPrice: Double? {
        return pricePoints
            .filter { $0.source == "current" }
            .sorted { $0.timestamp > $1.timestamp }
            .first?.price
    }

    var averagePrice: Double {
        guard !pricePoints.isEmpty else { return 0 }
        return pricePoints.map { $0.price }.reduce(0, +) / Double(pricePoints.count)
    }

    var lowestPrice: Double? {
        return pricePoints.map { $0.price }.min()
    }

    var highestPrice: Double? {
        return pricePoints.map { $0.price }.max()
    }

    var priceDirection: SearchFilter.PriceDirection {
        guard pricePoints.count >= 2 else { return .stable }
        let sortedPoints = pricePoints.sorted { $0.timestamp < $1.timestamp }
        let recent = Array(sortedPoints.suffix(5)) // Last 5 data points
        guard recent.count >= 2 else { return .stable }

        let halfCount = recent.count / 2
        let oldPoints = recent.prefix(halfCount)
        let newPoints = recent.suffix(halfCount)

        guard !oldPoints.isEmpty && !newPoints.isEmpty else { return .stable }

        let oldAverage = oldPoints.map { $0.price }.reduce(0, +) / Double(oldPoints.count)
        let newAverage = newPoints.map { $0.price }.reduce(0, +) / Double(newPoints.count)

        let change = (newAverage - oldAverage) / oldAverage
        if change > 0.05 { return .ascending }
        else if change < -0.05 { return .descending }
        else { return .stable }
    }

    // MARK: - Custom Coding Keys

    enum CodingKeys: String, CodingKey {
        case itemID = "itemId"
        case title, pricePoints, lastUpdated
    }
}

/// A similar item recommendation
struct SimilarItem: Identifiable, Codable {

    // MARK: - Properties

    let id = UUID()
    let listing: EbayListing
    let similarityScore: Double
    let similarityReasons: [SimilarityReason]

    // MARK: - Nested Types

    enum SimilarityReason: String, CaseIterable, Codable {
        case category = "Same Category"
        case brand = "Same Brand"
        case priceRange = "Similar Price"
        case keywords = "Similar Keywords"
        case seller = "Same Seller"
        case condition = "Same Condition"

        var iconName: String {
            switch self {
            case .category: return "folder"
            case .brand: return "star"
            case .priceRange: return "dollarsign.circle"
            case .keywords: return "magnifyingglass"
            case .seller: return "person"
            case .condition: return "checkmark.seal"
            }
        }

        var color: Color {
            switch self {
            case .category: return .blue
            case .brand: return .purple
            case .priceRange: return .green
            case .keywords: return .orange
            case .seller: return .red
            case .condition: return .teal
            }
        }
    }
}

/// Comparison metric for side-by-side analysis
struct ComparisonMetric {

    // MARK: - Properties

    let name: String
    let values: [String]
    let bestIndex: Int?
    let iconName: String

    // MARK: - Static Factory Methods

    static func priceMetric(listings: [EbayListing]) -> ComparisonMetric {
        let values = listings.map { String(format: "$%.2f", $0.price) }
        let bestIndex = listings.enumerated().min(by: { $0.element.price < $1.element.price })?.offset
        return ComparisonMetric(name: "Price", values: values, bestIndex: bestIndex, iconName: "dollarsign.circle")
    }

    static func conditionMetric(listings: [EbayListing]) -> ComparisonMetric {
        let values = listings.map { $0.condition }
        return ComparisonMetric(name: "Condition", values: values, bestIndex: nil, iconName: "checkmark.seal")
    }

    static func shippingMetric(listings: [EbayListing]) -> ComparisonMetric {
        let values = listings.map { listing in
            if let cost = listing.shippingCost, cost > 0 {
                return String(format: "$%.2f", cost)
            } else {
                return "Free"
            }
        }
        let bestIndex = listings.enumerated().min(by: {
            ($0.element.shippingCost ?? 0) < ($1.element.shippingCost ?? 0)
        })?.offset
        return ComparisonMetric(name: "Shipping", values: values, bestIndex: bestIndex, iconName: "shippingbox")
    }

    static func sellerMetric(listings: [EbayListing]) -> ComparisonMetric {
        let values = listings.map { String(format: "%d (%.1f%%)", $0.seller.feedbackScore, $0.seller.feedbackPercentage) }
        let bestIndex = listings.enumerated().max(by: {
            $0.element.seller.feedbackScore < $1.element.seller.feedbackScore
        })?.offset
        return ComparisonMetric(name: "Seller Rating", values: values, bestIndex: bestIndex, iconName: "person.crop.circle")
    }

    static func endTimeMetric(listings: [EbayListing]) -> ComparisonMetric {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let values = listings.map { formatter.string(from: $0.endTime) }
        return ComparisonMetric(name: "End Time", values: values, bestIndex: nil, iconName: "clock")
    }
}