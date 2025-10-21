//
//  EbayAPIModels.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import Foundation

// MARK: - eBay API Response Models

/// eBay search response wrapper
struct EbaySearchResponse: Codable {
    let itemSummaries: [EbayItemSummary]?
    let total: Int?
    let offset: Int?
    let limit: Int?
}

/// Individual item summary from eBay API
struct EbayItemSummary: Codable {
    let itemID: String
    let title: String
    let price: EbayPrice?
    let condition: String?
    let image: EbayImage?
    let itemWebURL: String
    let itemEndDate: String?
    let itemLocation: EbayLocation?
    let shippingOptions: [EbayShippingOption]?
    let buyingOptions: [String]?
    let seller: EbaySeller?

    enum CodingKeys: String, CodingKey {
        case itemID = "itemId"
        case title, price, condition, image
        case itemWebURL = "itemWebUrl"
        case itemEndDate, itemLocation, shippingOptions, buyingOptions, seller
    }
}

/// Price information from eBay API
struct EbayPrice: Codable {
    let value: String
    let currency: String

    var doubleValue: Double {
        return Double(value) ?? 0.0
    }
}

/// Image information from eBay API
struct EbayImage: Codable {
    let imageURL: String

    enum CodingKeys: String, CodingKey {
        case imageURL = "imageUrl"
    }
}

/// Location information from eBay API
struct EbayLocation: Codable {
    let country: String
}

/// Shipping option from eBay API
struct EbayShippingOption: Codable {
    let shippingCost: EbayPrice?
}

/// Seller information from eBay API
struct EbaySeller: Codable {
    let username: String?
    let feedbackScore: Int?
    let feedbackPercentage: Double?

    enum CodingKeys: String, CodingKey {
        case username, feedbackScore, feedbackPercentage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        username = try container.decodeIfPresent(String.self, forKey: .username)
        feedbackScore = try container.decodeIfPresent(Int.self, forKey: .feedbackScore)

        // Handle feedbackPercentage as either Double or String
        if let percentageDouble = try? container.decodeIfPresent(Double.self, forKey: .feedbackPercentage) {
            feedbackPercentage = percentageDouble
        } else if let percentageString = try? container.decodeIfPresent(String.self, forKey: .feedbackPercentage) {
            feedbackPercentage = Double(percentageString)
        } else {
            feedbackPercentage = nil
        }
    }
}

// MARK: - API Error Types

/// eBay API specific error types
enum EbayAPIError: Error {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError
    case authenticationError
    case rateLimitExceeded
    case networkError

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError:
            return "Failed to decode response"
        case .authenticationError:
            return "Authentication failed"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .networkError:
            return "No network connection"
        }
    }
}