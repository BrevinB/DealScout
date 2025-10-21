//
//  SearchTemplateManager.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import Foundation
import Combine

// MARK: - Search Template Manager

/// Manages search templates and provides recommendations
class SearchTemplateManager: ObservableObject {

    // MARK: - Properties

    @Published var userTemplates: [SearchTemplate] = []
    @Published var predefinedTemplates: [SearchTemplate] = []
    @Published var recommendedTemplates: [SearchTemplate] = []

    private let userDefaults = UserDefaults.standard
    private let templatesKey = "SavedSearchTemplates"

    // MARK: - Initialization

    init() {
        loadPredefinedTemplates()
        loadUserTemplates()
        generateRecommendations()
    }

    // MARK: - Template Management

    /// Save a new user template
    func saveTemplate(_ template: SearchTemplate) {
        var updatedTemplate = template
        updatedTemplate.isUserCreated = true
        userTemplates.append(updatedTemplate)
        saveUserTemplates()
    }

    /// Update an existing template
    func updateTemplate(_ template: SearchTemplate) {
        if let index = userTemplates.firstIndex(where: { $0.id == template.id }) {
            userTemplates[index] = template
            saveUserTemplates()
        }
    }

    /// Delete a template
    func deleteTemplate(_ template: SearchTemplate) {
        userTemplates.removeAll { $0.id == template.id }
        saveUserTemplates()
    }

    /// Use a template (increment use count and update last used)
    func useTemplate(_ template: SearchTemplate) -> SearchFilter {
        // Update use count
        if template.isUserCreated {
            if let index = userTemplates.firstIndex(where: { $0.id == template.id }) {
                userTemplates[index].useCount += 1
                userTemplates[index].lastUsed = Date()
                saveUserTemplates()
            }
        } else {
            if let index = predefinedTemplates.firstIndex(where: { $0.id == template.id }) {
                predefinedTemplates[index].useCount += 1
                predefinedTemplates[index].lastUsed = Date()
            }
        }

        return template.baseFilter
    }

    /// Get all templates by category
    func getTemplates(for category: SearchTemplate.TemplateCategory) -> [SearchTemplate] {
        let all = userTemplates + predefinedTemplates
        return all.filter { $0.category == category }
            .sorted { $0.useCount > $1.useCount }
    }

    /// Get popular templates
    func getPopularTemplates() -> [SearchTemplate] {
        let all = userTemplates + predefinedTemplates
        return all.filter { $0.useCount > 0 }
            .sorted { $0.useCount > $1.useCount }
            .prefix(10)
            .map { $0 }
    }

    /// Get recently used templates
    func getRecentTemplates() -> [SearchTemplate] {
        let all = userTemplates + predefinedTemplates
        return all.compactMap { template in
            guard let lastUsed = template.lastUsed else { return nil }
            return template
        }
        .sorted { $0.lastUsed! > $1.lastUsed! }
        .prefix(5)
        .map { $0 }
    }

    /// Create template from search filter
    func createTemplate(
        from filter: SearchFilter,
        name: String,
        description: String,
        category: SearchTemplate.TemplateCategory,
        tags: [String] = []
    ) -> SearchTemplate {
        return SearchTemplate(
            name: name,
            description: description,
            category: category,
            baseFilter: filter,
            tags: tags,
            useCount: 0,
            createdDate: Date(),
            lastUsed: nil,
            isUserCreated: true,
            isPublic: false
        )
    }

    /// Generate smart template suggestions based on user search patterns
    func generateRecommendations() {
        recommendedTemplates = []

        // Analyze user's search patterns and suggest relevant templates
        let userCategories = extractUserPreferences()

        for category in userCategories {
            let categoryTemplates = predefinedTemplates.filter { $0.category == category }
            recommendedTemplates.append(contentsOf: categoryTemplates.prefix(2))
        }

        // Add some general popular templates
        if recommendedTemplates.count < 6 {
            let popular = [
                SearchTemplate.gamingLaptopDeals,
                SearchTemplate.iphoneDeals,
                SearchTemplate.collectibleWatches
            ]
            recommendedTemplates.append(contentsOf: popular)
        }
    }

    // MARK: - Search Pattern Analysis

    /// Analyze user's search history to suggest relevant categories
    private func extractUserPreferences() -> [SearchTemplate.TemplateCategory] {
        // This would analyze actual search history in a real implementation
        // For now, return some default categories
        return [.electronics, .gaming, .collectibles]
    }

    // MARK: - Persistence

    private func loadUserTemplates() {
        guard let data = userDefaults.data(forKey: templatesKey),
              let templates = try? JSONDecoder().decode([SearchTemplate].self, from: data) else {
            userTemplates = []
            return
        }
        userTemplates = templates
    }

    private func saveUserTemplates() {
        guard let data = try? JSONEncoder().encode(userTemplates) else { return }
        userDefaults.set(data, forKey: templatesKey)
    }

    private func loadPredefinedTemplates() {
        predefinedTemplates = [
            // Electronics Templates
            SearchTemplate(
                name: "Budget Smartphones",
                description: "Quality smartphones under $300 with good ratings",
                category: .electronics,
                baseFilter: SearchFilter(
                    name: "Budget Smartphones",
                    categoryID: "9355",
                    maximumPrice: 300,
                    condition: .used,
                    listingType: .buyItNow,
                    sellerFilters: SearchFilter.SellerFilter(
                        minimumFeedbackScore: 100,
                        minimumFeedbackPercentage: 95.0,
                        topRatedSellersOnly: false,
                        businessSellersOnly: false
                    ),
                    sortOrder: .pricePlusShippingLowest
                ),
                tags: ["smartphone", "budget", "android", "iPhone"],
                useCount: 0,
                createdDate: Date(),
                isUserCreated: false,
                isPublic: true
            ),

            SearchTemplate.gamingLaptopDeals,

            SearchTemplate(
                name: "4K TV Deals",
                description: "Large 4K smart TVs with free shipping",
                category: .electronics,
                baseFilter: SearchFilter(
                    name: "4K TV Deals",
                    categoryID: "11071",
                    minimumPrice: 300,
                    condition: .new,
                    listingType: .buyItNow,
                    shippingOptions: SearchFilter.ShippingFilter(
                        freeShippingOnly: true,
                        localPickupAvailable: false,
                        maximumShippingCost: nil,
                        expeditedShipping: false
                    ),
                    sortOrder: .pricePlusShippingLowest
                ),
                tags: ["4K", "TV", "smart", "large"],
                useCount: 0,
                createdDate: Date(),
                isUserCreated: false,
                isPublic: true
            ),

            // Fashion Templates
            SearchTemplate(
                name: "Designer Handbags",
                description: "Authentic designer handbags with authenticity guarantee",
                category: .fashion,
                baseFilter: SearchFilter(
                    name: "Designer Handbags",
                    categoryID: "169291",
                    minimumPrice: 100,
                    condition: .used,
                    sortOrder: .bestMatch,
                    listingFeatures: SearchFilter.ListingFeatures(
                        acceptsBestOffer: false,
                        buyItNowAvailable: true,
                        returnsAccepted: true,
                        authorizedSeller: true,
                        dealsAndSavings: false,
                        saleItems: false,
                        benefitsCharity: false,
                        authenticityGuarantee: true,
                        watchedItems: false,
                        soldListings: false,
                        completedListings: false,
                        listingsAsLots: false
                    )
                ),
                tags: ["designer", "handbag", "authentic", "luxury"],
                useCount: 0,
                createdDate: Date(),
                isUserCreated: false,
                isPublic: true
            ),

            // Gaming Templates
            SearchTemplate(
                name: "Retro Gaming Consoles",
                description: "Classic gaming consoles in working condition",
                category: .gaming,
                baseFilter: SearchFilter(
                    name: "Retro Gaming Consoles",
                    categoryID: "139971",
                    condition: .used,
                    listingType: .auction,
                    sellerFilters: SearchFilter.SellerFilter(
                        minimumFeedbackScore: 50,
                        minimumFeedbackPercentage: 98.0,
                        topRatedSellersOnly: false,
                        businessSellersOnly: false
                    ),
                    sortOrder: .endTimeSoonest
                ),
                tags: ["retro", "gaming", "console", "vintage"],
                useCount: 0,
                createdDate: Date(),
                isUserCreated: false,
                isPublic: true
            ),

            SearchTemplate(
                name: "Gaming Chair Deals",
                description: "Ergonomic gaming chairs with good condition",
                category: .gaming,
                baseFilter: SearchFilter(
                    name: "Gaming Chair Deals",
                    categoryID: "171955",
                    maximumPrice: 200,
                    condition: .used,
                    listingType: .buyItNow,
                    location: SearchFilter.LocationFilter(
                        country: nil,
                        state: nil,
                        zipCode: nil,
                        maximumDistance: 100,
                        localPickupOnly: true
                    ),
                    sortOrder: .distanceNearest
                ),
                tags: ["gaming", "chair", "ergonomic", "local"],
                useCount: 0,
                createdDate: Date(),
                isUserCreated: false,
                isPublic: true
            ),

            // Collectibles Templates
            SearchTemplate.collectibleWatches,

            SearchTemplate(
                name: "Sports Card Auctions",
                description: "Graded sports cards ending soon",
                category: .collectibles,
                baseFilter: SearchFilter(
                    name: "Sports Card Auctions",
                    categoryID: "212",
                    listingType: .auction,
                    sortOrder: .endTimeSoonest,
                    auctionFilters: SearchFilter.AuctionFilter(
                        endingWithinHours: 24,
                        minimumBidCount: nil,
                        maximumBidCount: nil,
                        noBidsOnly: false,
                        hasReservePrice: false
                    )
                ),
                tags: ["sports", "cards", "graded", "auction"],
                useCount: 0,
                createdDate: Date(),
                isUserCreated: false,
                isPublic: true
            ),

            // Automotive Templates
            SearchTemplate(
                name: "Car Parts Local",
                description: "OEM car parts available for local pickup",
                category: .automotive,
                baseFilter: SearchFilter(
                    name: "Car Parts Local",
                    categoryID: "6030",
                    condition: .used,
                    listingType: .buyItNow,
                    location: SearchFilter.LocationFilter(
                        country: nil,
                        state: nil,
                        zipCode: nil,
                        maximumDistance: 50,
                        localPickupOnly: true
                    ),
                    sortOrder: .distanceNearest
                ),
                tags: ["car", "parts", "OEM", "local"],
                useCount: 0,
                createdDate: Date(),
                isUserCreated: false,
                isPublic: true
            )
        ]
    }
}
