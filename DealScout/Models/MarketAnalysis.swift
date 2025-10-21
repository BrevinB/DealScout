//
//  MarketAnalysis.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import Foundation

// MARK: - Market Analysis Models

/// Comprehensive market analysis for search results
struct MarketAnalysis: Codable {

    // MARK: - Properties

    let averagePrice: Double
    let medianPrice: Double
    let lowestPrice: Double
    let highestPrice: Double
    let totalSold: Int
    let priceDirection: SearchFilter.PriceDirection
    let last30DaysAverage: Double
    let last7DaysAverage: Double
    let soldItems: [SoldListing]?
    let soldItemsAnalysis: SoldItemsAnalysis?

    // MARK: - Initializers

    init(
        averagePrice: Double,
        medianPrice: Double,
        lowestPrice: Double,
        highestPrice: Double,
        totalSold: Int,
        priceDirection: SearchFilter.PriceDirection,
        last30DaysAverage: Double,
        last7DaysAverage: Double,
        soldItems: [SoldListing]? = nil,
        soldItemsAnalysis: SoldItemsAnalysis? = nil
    ) {
        self.averagePrice = averagePrice
        self.medianPrice = medianPrice
        self.lowestPrice = lowestPrice
        self.highestPrice = highestPrice
        self.totalSold = totalSold
        self.priceDirection = priceDirection
        self.last30DaysAverage = last30DaysAverage
        self.last7DaysAverage = last7DaysAverage
        self.soldItems = soldItems
        self.soldItemsAnalysis = soldItemsAnalysis
    }

    // MARK: - Custom Coding

    enum CodingKeys: String, CodingKey {
        case averagePrice, medianPrice, lowestPrice, highestPrice, totalSold
        case priceDirection, last30DaysAverage, last7DaysAverage, soldItems, soldItemsAnalysis
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        averagePrice = try container.decode(Double.self, forKey: .averagePrice)
        medianPrice = try container.decode(Double.self, forKey: .medianPrice)
        lowestPrice = try container.decode(Double.self, forKey: .lowestPrice)
        highestPrice = try container.decode(Double.self, forKey: .highestPrice)
        totalSold = try container.decode(Int.self, forKey: .totalSold)
        priceDirection = try container.decode(SearchFilter.PriceDirection.self, forKey: .priceDirection)
        last30DaysAverage = try container.decode(Double.self, forKey: .last30DaysAverage)
        last7DaysAverage = try container.decode(Double.self, forKey: .last7DaysAverage)
        soldItems = try container.decodeIfPresent([SoldListing].self, forKey: .soldItems)
        soldItemsAnalysis = try container.decodeIfPresent(SoldItemsAnalysis.self, forKey: .soldItemsAnalysis)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(averagePrice, forKey: .averagePrice)
        try container.encode(medianPrice, forKey: .medianPrice)
        try container.encode(lowestPrice, forKey: .lowestPrice)
        try container.encode(highestPrice, forKey: .highestPrice)
        try container.encode(totalSold, forKey: .totalSold)
        try container.encode(priceDirection, forKey: .priceDirection)
        try container.encode(last30DaysAverage, forKey: .last30DaysAverage)
        try container.encode(last7DaysAverage, forKey: .last7DaysAverage)
        try container.encodeIfPresent(soldItems, forKey: .soldItems)
        try container.encodeIfPresent(soldItemsAnalysis, forKey: .soldItemsAnalysis)
    }
}