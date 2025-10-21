//
//  SearchTemplate.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import Foundation

// MARK: - Search Template Models

/// A predefined search template for common eBay searches
struct PresetSearchTemplate: Identifiable, Codable {

    // MARK: - Nested Types

    /// Price range for template searches
    struct PriceRange: Codable {
        let minimumPrice: Double?
        let maximumPrice: Double?

        init(minimum: Double?, maximum: Double?) {
            self.minimumPrice = minimum
            self.maximumPrice = maximum
        }
    }

    // MARK: - Properties

    let id = UUID()
    let name: String
    let keywords: String
    let categoryID: String?
    let condition: SearchFilter.ItemCondition?
    let priceRange: PriceRange
    let description: String
    let iconName: String

    // MARK: - Static Data

    /// Common predefined search templates
    static let commonTemplates: [PresetSearchTemplate] = [
        PresetSearchTemplate(
            name: "iPhone Pro Max",
            keywords: "iPhone Pro Max",
            categoryID: "9355",
            condition: .used,
            priceRange: PriceRange(minimum: 500, maximum: 1200),
            description: "Latest iPhone Pro Max models",
            iconName: "iphone"
        ),
        PresetSearchTemplate(
            name: "MacBook Pro",
            keywords: "MacBook Pro",
            categoryID: "58058",
            condition: nil,
            priceRange: PriceRange(minimum: 800, maximum: 3000),
            description: "Professional MacBook laptops",
            iconName: "laptopcomputer"
        ),
        PresetSearchTemplate(
            name: "PlayStation 5",
            keywords: "PlayStation 5 PS5",
            categoryID: "1249",
            condition: .used,
            priceRange: PriceRange(minimum: 400, maximum: 600),
            description: "Sony PlayStation 5 console",
            iconName: "gamecontroller"
        ),
        PresetSearchTemplate(
            name: "Gaming Laptop",
            keywords: "gaming laptop RTX",
            categoryID: "171485",
            condition: nil,
            priceRange: PriceRange(minimum: 800, maximum: 2500),
            description: "High-performance gaming laptops",
            iconName: "laptopcomputer"
        ),
        PresetSearchTemplate(
            name: "iPad Pro",
            keywords: "iPad Pro",
            categoryID: "31530",
            condition: nil,
            priceRange: PriceRange(minimum: 400, maximum: 1200),
            description: "Apple iPad Pro tablets",
            iconName: "ipad"
        ),
        PresetSearchTemplate(
            name: "Apple Watch",
            keywords: "Apple Watch Series",
            categoryID: "281",
            condition: .used,
            priceRange: PriceRange(minimum: 200, maximum: 800),
            description: "Apple smartwatches",
            iconName: "applewatch"
        ),
        PresetSearchTemplate(
            name: "Nintendo Switch",
            keywords: "Nintendo Switch console",
            categoryID: "1249",
            condition: nil,
            priceRange: PriceRange(minimum: 200, maximum: 400),
            description: "Nintendo Switch gaming console",
            iconName: "gamecontroller"
        ),
        PresetSearchTemplate(
            name: "AirPods Pro",
            keywords: "AirPods Pro",
            categoryID: "178893",
            condition: .new,
            priceRange: PriceRange(minimum: 150, maximum: 250),
            description: "Apple AirPods Pro wireless earbuds",
            iconName: "airpods"
        )
    ]
}
