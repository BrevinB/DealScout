//
//  DealScoringService.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import Foundation
import Combine
// MARK: - Deal Scoring Service

/// Service responsible for calculating deal quality scores
class DealScoringService: ObservableObject {

    // MARK: - Properties

    @Published var priceHistories: [String: PriceHistory] = [:]
    @Published var dealScores: [String: DealScore] = [:]

    // MARK: - Deal Scoring

    /// Calculate comprehensive deal score for an item
    func calculateDealScore(
        itemID: String,
        currentPrice: Double,
        searchQuery: String,
        condition: PriceDataPoint.ItemCondition?,
        sellerFeedback: Double?,
        shippingCost: Double?,
        timeRemaining: TimeInterval?,
        listingType: PriceDataPoint.ListingType
    ) -> DealScore {

        var factors: [ScoreFactor] = []
        var totalScore: Double = 5.0 // Start with neutral score
        var confidence: Double = 0.5

        // Factor 1: Price Comparison (Most Important - 40% weight)
        let priceComparisonFactor = calculatePriceComparisonScore(
            itemID: itemID,
            currentPrice: currentPrice,
            searchQuery: searchQuery,
            condition: condition
        )
        factors.append(priceComparisonFactor)
        totalScore += priceComparisonFactor.impact * 0.4
        confidence += 0.2

        // Factor 2: Seller Reliability (25% weight)
        if let feedback = sellerFeedback {
            let sellerFactor = calculateSellerScore(feedback: feedback)
            factors.append(sellerFactor)
            totalScore += sellerFactor.impact * 0.25
            confidence += 0.15
        }

        // Factor 3: Total Cost Including Shipping (20% weight)
        let totalCostFactor = calculateTotalCostScore(
            itemPrice: currentPrice,
            shippingCost: shippingCost
        )
        factors.append(totalCostFactor)
        totalScore += totalCostFactor.impact * 0.2
        confidence += 0.1

        // Factor 4: Time Sensitivity (10% weight)
        if let timeLeft = timeRemaining {
            let timeFactor = calculateTimeScore(
                timeRemaining: timeLeft,
                listingType: listingType
            )
            factors.append(timeFactor)
            totalScore += timeFactor.impact * 0.1
            confidence += 0.05
        }

        // Factor 5: Condition Value (5% weight)
        if let itemCondition = condition {
            let conditionFactor = calculateConditionScore(
                condition: itemCondition,
                price: currentPrice
            )
            factors.append(conditionFactor)
            totalScore += conditionFactor.impact * 0.05
        }

        // Normalize score to 0-10 range
        totalScore = max(0, min(10, totalScore))
        confidence = max(0, min(1, confidence))

        return DealScore(
            itemID: itemID,
            searchQuery: searchQuery,
            currentPrice: currentPrice,
            score: totalScore,
            factors: factors,
            calculatedDate: Date(),
            confidence: confidence
        )
    }

    // MARK: - Price History Management

    /// Add price data point to history
    func addPriceDataPoint(
        searchQuery: String,
        categoryID: String?,
        dataPoint: PriceDataPoint
    ) {
        let key = priceHistoryKey(searchQuery: searchQuery, categoryID: categoryID)

        if var existing = priceHistories[key] {
            existing.dataPoints.append(dataPoint)
            existing.lastUpdated = Date()

            // Keep only last 1000 data points to prevent memory issues
            if existing.dataPoints.count > 1000 {
                existing.dataPoints = Array(existing.dataPoints.suffix(1000))
            }

            priceHistories[key] = existing
        } else {
            let newHistory = PriceHistory(
                searchQuery: searchQuery,
                categoryID: categoryID,
                dataPoints: [dataPoint],
                createdDate: Date(),
                lastUpdated: Date()
            )
            priceHistories[key] = newHistory
        }
    }

    /// Get price history for a search query
    func getPriceHistory(searchQuery: String, categoryID: String?) -> PriceHistory? {
        let key = priceHistoryKey(searchQuery: searchQuery, categoryID: categoryID)
        return priceHistories[key]
    }

    /// Get market statistics for a search query
    func getMarketStatistics(searchQuery: String, categoryID: String?) -> MarketStatistics? {
        guard let history = getPriceHistory(searchQuery: searchQuery, categoryID: categoryID),
              !history.dataPoints.isEmpty else { return nil }

        let prices = history.dataPoints.map(\.price)
        let recentPrices = history.dataPoints
            .filter { $0.timestamp > Calendar.current.date(byAdding: .day, value: -30, to: Date())! }
            .map(\.price)

        guard !recentPrices.isEmpty else { return nil }

        return MarketStatistics(
            averagePrice: recentPrices.reduce(0, +) / Double(recentPrices.count),
            medianPrice: calculateMedian(prices: recentPrices),
            minimumPrice: recentPrices.min()!,
            maximumPrice: recentPrices.max()!,
            priceRange: recentPrices.max()! - recentPrices.min()!,
            sampleSize: recentPrices.count,
            volatility: history.volatilityScore,
            trend: history.priceTrend,
            lastUpdated: history.lastUpdated
        )
    }

    // MARK: - Private Scoring Methods

    private func calculatePriceComparisonScore(
        itemID: String,
        currentPrice: Double,
        searchQuery: String,
        condition: PriceDataPoint.ItemCondition?
    ) -> ScoreFactor {

        guard let history = getPriceHistory(searchQuery: searchQuery, categoryID: nil),
              let statistics = getMarketStatistics(searchQuery: searchQuery, categoryID: nil) else {
            return ScoreFactor(
                name: "Price vs Market",
                impact: 0,
                description: "Insufficient market data for comparison"
            )
        }

        let percentDifference = ((statistics.averagePrice - currentPrice) / statistics.averagePrice) * 100

        let impact: Double
        let description: String

        switch percentDifference {
        case 30...: // 30%+ below market
            impact = 3.0
            description = "Exceptional price - \(Int(percentDifference))% below market average"
        case 20..<30: // 20-30% below market
            impact = 2.0
            description = "Excellent price - \(Int(percentDifference))% below market average"
        case 10..<20: // 10-20% below market
            impact = 1.0
            description = "Good price - \(Int(percentDifference))% below market average"
        case 5..<10: // 5-10% below market
            impact = 0.5
            description = "Fair price - \(Int(percentDifference))% below market average"
        case -5..<5: // Within 5% of market
            impact = 0
            description = "Market price - within 5% of average"
        case -15..<(-5): // 5-15% above market
            impact = -1.0
            description = "Above market - \(Int(abs(percentDifference)))% higher than average"
        default: // 15%+ above market
            impact = -2.0
            description = "Overpriced - \(Int(abs(percentDifference)))% above market average"
        }

        return ScoreFactor(
            name: "Price vs Market",
            impact: impact,
            description: description
        )
    }

    private func calculateSellerScore(feedback: Double) -> ScoreFactor {
        let impact: Double
        let description: String

        switch feedback {
        case 99.5...:
            impact = 1.0
            description = "Exceptional seller rating (\(String(format: "%.1f", feedback))%)"
        case 98.0..<99.5:
            impact = 0.5
            description = "Excellent seller rating (\(String(format: "%.1f", feedback))%)"
        case 95.0..<98.0:
            impact = 0
            description = "Good seller rating (\(String(format: "%.1f", feedback))%)"
        case 90.0..<95.0:
            impact = -0.5
            description = "Below average seller rating (\(String(format: "%.1f", feedback))%)"
        default:
            impact = -1.0
            description = "Poor seller rating (\(String(format: "%.1f", feedback))%)"
        }

        return ScoreFactor(
            name: "Seller Rating",
            impact: impact,
            description: description
        )
    }

    private func calculateTotalCostScore(itemPrice: Double, shippingCost: Double?) -> ScoreFactor {
        let shipping = shippingCost ?? 0
        let impact: Double
        let description: String

        if shipping == 0 {
            impact = 0.5
            description = "Free shipping included"
        } else {
            let shippingPercent = (shipping / itemPrice) * 100
            switch shippingPercent {
            case 0..<5:
                impact = 0.2
                description = "Low shipping cost (\(String(format: "%.1f", shippingPercent))% of item price)"
            case 5..<15:
                impact = 0
                description = "Moderate shipping cost (\(String(format: "%.1f", shippingPercent))% of item price)"
            case 15..<25:
                impact = -0.3
                description = "High shipping cost (\(String(format: "%.1f", shippingPercent))% of item price)"
            default:
                impact = -0.5
                description = "Very high shipping cost (\(String(format: "%.1f", shippingPercent))% of item price)"
            }
        }

        return ScoreFactor(
            name: "Total Cost",
            impact: impact,
            description: description
        )
    }

    private func calculateTimeScore(
        timeRemaining: TimeInterval,
        listingType: PriceDataPoint.ListingType
    ) -> ScoreFactor {

        let hoursRemaining = timeRemaining / 3600
        let impact: Double
        let description: String

        if listingType == .auction {
            switch hoursRemaining {
            case 0..<1:
                impact = 0.5
                description = "Auction ending soon - potential for good deals"
            case 1..<24:
                impact = 0.2
                description = "Good timing for auction bidding"
            case 24..<72:
                impact = 0
                description = "Standard auction timeframe"
            default:
                impact = -0.1
                description = "Long auction duration - prices may rise"
            }
        } else {
            impact = 0
            description = "Fixed price listing - time not a factor"
        }

        return ScoreFactor(
            name: "Time Sensitivity",
            impact: impact,
            description: description
        )
    }

    private func calculateConditionScore(
        condition: PriceDataPoint.ItemCondition,
        price: Double
    ) -> ScoreFactor {

        let impact: Double
        let description: String

        switch condition {
        case .new:
            impact = 0.2
            description = "New condition provides excellent value"
        case .openBox:
            impact = 0.1
            description = "Open box condition offers good savings"
        case .refurbished:
            impact = 0
            description = "Refurbished condition - standard value"
        case .used:
            impact = -0.1
            description = "Used condition - verify item details carefully"
        }

        return ScoreFactor(
            name: "Condition Value",
            impact: impact,
            description: description
        )
    }

    // MARK: - Utility Methods

    private func priceHistoryKey(searchQuery: String, categoryID: String?) -> String {
        return "\(searchQuery)_\(categoryID ?? "all")"
    }

    private func calculateMedian(prices: [Double]) -> Double {
        let sorted = prices.sorted()
        let count = sorted.count

        if count % 2 == 0 {
            return (sorted[count/2 - 1] + sorted[count/2]) / 2
        } else {
            return sorted[count/2]
        }
    }
}

// MARK: - Market Statistics

/// Market statistics for a search query
struct MarketStatistics: Codable {
    let averagePrice: Double
    let medianPrice: Double
    let minimumPrice: Double
    let maximumPrice: Double
    let priceRange: Double
    let sampleSize: Int
    let volatility: Double
    let trend: PriceTrend
    let lastUpdated: Date

    var formattedAveragePrice: String {
        return String(format: "$%.2f", averagePrice)
    }

    var formattedPriceRange: String {
        return String(format: "$%.2f - $%.2f", minimumPrice, maximumPrice)
    }

    var volatilityDescription: String {
        switch volatility {
        case 0..<10:
            return "Low volatility - stable pricing"
        case 10..<25:
            return "Moderate volatility - some price variation"
        case 25..<50:
            return "High volatility - significant price swings"
        default:
            return "Very high volatility - highly unpredictable pricing"
        }
    }
}
