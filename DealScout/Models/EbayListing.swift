//
//  EbayListing.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import Foundation
import SwiftUI

// MARK: - eBay Listing Models

/// A listing from eBay search results with deal analysis
struct EbayListing: Identifiable, Codable {

    // MARK: - Properties

    let id = UUID()
    let itemID: String
    let title: String
    let price: Double
    let currency: String
    let condition: String
    let imageURL: String?
    let listingURL: String
    let endTime: Date
    let location: String
    let shippingCost: Double?
    let buyItNowPrice: Double?
    let isAuction: Bool
    let seller: SellerInfo

    // Deal analysis properties
    var dealScore: DealScore?
    var averageMarketPrice: Double?
    var savingsAmount: Double?
    var savingsPercentage: Double?
    var isSoldListing: Bool = false

    // MARK: - Nested Types

    /// Seller information for the listing
    struct SellerInfo: Codable {
        let username: String
        let feedbackScore: Int
        let feedbackPercentage: Double
    }

    /// Deal quality assessment enumeration
    enum DealScore: String, Codable, CaseIterable {
        case excellent = "excellent"
        case good = "good"
        case fair = "fair"
        case poor = "poor"

        var displayName: String {
            switch self {
            case .excellent: return "Excellent Deal"
            case .good: return "Good Deal"
            case .fair: return "Fair Price"
            case .poor: return "Overpriced"
            }
        }

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .orange
            case .poor: return .red
            }
        }

        var systemImageName: String {
            switch self {
            case .excellent: return "star.fill"
            case .good: return "star.leadinghalf.filled"
            case .fair: return "star"
            case .poor: return "exclamationmark.triangle.fill"
            }
        }
    }

    // MARK: - Custom Coding Keys

    enum CodingKeys: String, CodingKey {
        case itemID = "itemId"
        case title, price, currency, condition, imageURL, listingURL, endTime
        case location, shippingCost, buyItNowPrice, isAuction, seller
        case dealScore, averageMarketPrice, savingsAmount, savingsPercentage, isSoldListing
    }
}

// MARK: - Sold Listing Models

/// A completed/sold eBay listing for market analysis
struct SoldListing: Identifiable, Codable {

    // MARK: - Properties

    let id = UUID()
    let itemID: String
    let title: String
    let soldPrice: Double
    let soldDate: Date
    let condition: SearchFilter.ItemCondition?
    let imageURL: String?
    let imageUrl: String? // Compatibility property
    let listingURL: String
    let originalPrice: String
    let bidsCount: Int?
    let wasAuction: Bool
    let location: String
    let sellerName: String
    let sellerFeedback: Int

    // MARK: - Initializer

    init(itemID: String, title: String, soldPrice: Double, soldDate: Date, condition: SearchFilter.ItemCondition?, imageURL: String?, listingURL: String, originalPrice: String, bidsCount: Int?, wasAuction: Bool, location: String, sellerName: String, sellerFeedback: Int) {
        self.itemID = itemID
        self.title = title
        self.soldPrice = soldPrice
        self.soldDate = soldDate
        self.condition = condition
        self.imageURL = imageURL
        self.imageUrl = imageURL // Set both for compatibility
        self.listingURL = listingURL
        self.originalPrice = originalPrice
        self.bidsCount = bidsCount
        self.wasAuction = wasAuction
        self.location = location
        self.sellerName = sellerName
        self.sellerFeedback = sellerFeedback
    }

    // MARK: - Computed Properties

    var discountFromOriginal: Double? {
        guard let originalPriceDouble = Double(originalPrice), originalPriceDouble > 0 else { return nil }
        return ((originalPriceDouble - soldPrice) / originalPriceDouble) * 100
    }

    var formattedSoldDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: soldDate)
    }

    // MARK: - Custom Coding Keys

    enum CodingKeys: String, CodingKey {
        case itemID = "itemId"
        case title, soldPrice, soldDate, condition, imageURL, imageUrl, listingURL
        case originalPrice, bidsCount, wasAuction, location, sellerName, sellerFeedback
    }
}

// MARK: - Market Analysis Models

/// Comprehensive analysis of sold items for market insights
struct SoldItemsAnalysis: Codable {

    // MARK: - Nested Types

    struct PriceRange: Codable {
        let minimum: Double
        let maximum: Double

        enum CodingKeys: String, CodingKey {
            case minimum = "min"
            case maximum = "max"
        }
    }

    struct ListingTypeRatio: Codable {
        let auctions: Int
        let fixedPrice: Int
    }

    // MARK: - Properties

    let soldListings: [SoldListing]
    let priceComparison: PriceComparison
    let averageDaysToSell: Int
    let sellThroughRate: Double
    let auctionVsFixedRatio: Double
    let conditionBreakdown: [SearchFilter.ItemCondition: Int]
}

/// Price comparison between current and sold listings
struct PriceComparison: Codable {

    // MARK: - Nested Types

    struct PriceIndicator {
        let text: String
        let color: Color
    }

    // MARK: - Properties

    let currentAverage: Double
    let soldAverage: Double
    let difference: Double
    let differencePercentage: Double

    // MARK: - Computed Properties

    var indicator: PriceIndicator {
        if differencePercentage > 10 {
            return PriceIndicator(text: "Current prices are higher", color: .red)
        } else if differencePercentage < -10 {
            return PriceIndicator(text: "Current prices are lower", color: .green)
        } else {
            return PriceIndicator(text: "Prices are stable", color: .blue)
        }
    }

    var formattedDifference: String {
        let sign = difference >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", difference))"
    }

    var formattedPercentage: String {
        let sign = differencePercentage >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", differencePercentage))%"
    }
}