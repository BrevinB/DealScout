//
//  SearchModels.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import Foundation

// MARK: - Search Support Models

/// A recent search entry for quick access
struct RecentSearch: Identifiable, Codable {

    // MARK: - Properties

    var id = UUID()
    let keywords: String
    let searchDate: Date
    let resultCount: Int?

    // MARK: - Computed Properties

    var displayText: String {
        if let count = resultCount {
            return "\(keywords) (\(count) results)"
        }
        return keywords
    }
}

/// A trending category with popularity metrics
struct TrendingCategory: Identifiable, Codable {

    // MARK: - Properties

    let id: String
    let name: String
    let trendScore: Double
    let averagePrice: Double?
    let popularKeywords: [String]
    let iconName: String

    // MARK: - Static Data

    static let trendingCategories: [TrendingCategory] = [
        TrendingCategory(
            id: "9355",
            name: "Cell Phones & Smartphones",
            trendScore: 95.0,
            averagePrice: 450,
            popularKeywords: ["iPhone", "Samsung", "Google Pixel"],
            iconName: "iphone"
        ),
        TrendingCategory(
            id: "1249",
            name: "Video Games & Consoles",
            trendScore: 88.5,
            averagePrice: 320,
            popularKeywords: ["PlayStation", "Xbox", "Nintendo"],
            iconName: "gamecontroller"
        ),
        TrendingCategory(
            id: "171485",
            name: "Laptops & Netbooks",
            trendScore: 82.3,
            averagePrice: 850,
            popularKeywords: ["MacBook", "gaming laptop", "business laptop"],
            iconName: "laptopcomputer"
        ),
        TrendingCategory(
            id: "31530",
            name: "iPads, Tablets & eReaders",
            trendScore: 78.9,
            averagePrice: 380,
            popularKeywords: ["iPad Pro", "Surface", "Galaxy Tab"],
            iconName: "ipad"
        ),
        TrendingCategory(
            id: "293",
            name: "Consumer Electronics",
            trendScore: 75.2,
            averagePrice: 200,
            popularKeywords: ["smart home", "headphones", "speakers"],
            iconName: "tv"
        )
    ]

    // MARK: - Custom Coding Keys

    enum CodingKeys: String, CodingKey {
        case id, name, trendScore, averagePrice, popularKeywords
        case iconName = "icon"
    }
}

/// Search suggestion with categorization
struct SearchSuggestion: Identifiable {

    // MARK: - Properties

    let id = UUID()
    let text: String
    let type: SuggestionType
    let categoryID: String?

    // MARK: - Nested Types

    enum SuggestionType {
        case keyword
        case category
        case brand
        case recent
    }

    // MARK: - Custom Coding Keys

    enum CodingKeys: String, CodingKey {
        case text, type
        case categoryID = "categoryId"
    }
}