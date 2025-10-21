//
//  EbayDealFinderViewModel.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import Foundation
import SwiftUI
import UserNotifications
import Combine

// MARK: - Main ViewModel

/// Main view model for eBay deal finding functionality
final class EbayDealFinderViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var filters: [SearchFilter] = []
    @Published var searchResults: [UUID: SearchResult] = [:] // Results per filter ID
    @Published var isLoading = false
    @Published var loadingFilters: Set<UUID> = [] // Track which filters are loading
    @Published var errorMessage: String?
    @Published var showingErrorAlert = false
    @Published var selectedFilter: SearchFilter?
    @Published var marketAnalysis: MarketAnalysis?
    @Published var recentSearches: [RecentSearch] = []
    @Published var searchSuggestions: [SearchSuggestion] = []
    @Published var activeComparison: ListingComparison?
    @Published var priceHistories: [ItemPriceHistory] = []
    @Published var savedComparisons: [ListingComparison] = []

    // MARK: - Nested Types

    struct SearchResult {
        let filter: SearchFilter
        let listings: [EbayListing]
        let marketAnalysis: MarketAnalysis?
        let lastUpdated: Date
    }

    // MARK: - Private Properties

    let apiService = EbayAPIService()
    private let userDefaults = UserDefaults.standard
    private let filtersKey = "EbaySavedFilters"
    private let recentSearchesKey = "EbayRecentSearches"
    private let priceHistoriesKey = "EbayPriceHistories"
    private let savedComparisonsKey = "EbaySavedComparisons"

    // MARK: - Computed Properties

    var hasValidAPICredentials: Bool {
        return apiService.hasValidCredentials
    }

    var allListings: [EbayListing] {
        return searchResults.values.flatMap { $0.listings }
    }

    var excellentDeals: [EbayListing] {
        return allListings.filter { $0.dealScore == .excellent }
    }

    var activeSearchResults: [(filter: SearchFilter, result: SearchResult)] {
        return searchResults.compactMap { (id, result) in
            if filters.contains(where: { $0.id == id && $0.isActive }) {
                return (filter: result.filter, result: result)
            }
            return nil
        }.sorted { $0.filter.name < $1.filter.name }
    }

    // MARK: - Initialization

    init() {
        loadFilters()
        loadRecentSearches()
        loadPriceHistories()
        loadSavedComparisons()
        requestNotificationPermission()

        // Listen for credential updates
        NotificationCenter.default.addObserver(
            forName: .ebayCredentialsUpdated,
            object: nil,
            queue: .main
        ) { _ in
            self.objectWillChange.send()
        }
    }

    // MARK: - API Testing

    func testAPIConnection() async -> String {
        let result = await apiService.testConnection()
        DispatchQueue.main.async {
            self.errorMessage = result.message
            self.showingErrorAlert = true
        }
        return result.message
    }

    // MARK: - Filter Management

    func addFilter(_ filter: SearchFilter) {
        filters.append(filter)
        saveFilters()
    }

    func updateFilter(_ filter: SearchFilter) {
        if let index = filters.firstIndex(where: { $0.id == filter.id }) {
            filters[index] = filter
            saveFilters()
        }
    }

    func deleteFilter(_ filter: SearchFilter) {
        filters.removeAll { $0.id == filter.id }
        saveFilters()
    }

    func toggleFilter(_ filter: SearchFilter) {
        if let index = filters.firstIndex(where: { $0.id == filter.id }) {
            filters[index].isActive.toggle()
            saveFilters()
        }
    }

    // MARK: - Search Operations

    func searchListings(for filter: SearchFilter) async {
        DispatchQueue.main.async {
            self.loadingFilters.insert(filter.id)
            self.isLoading = !self.loadingFilters.isEmpty
            self.errorMessage = nil
        }

        do {
            let listings = try await apiService.searchItems(filter: filter)
            let analysis = try await apiService.getCompletedListings(keywords: filter.name)

            // If sold items are included, fetch and merge sold listings
            var allListings = listings
            if filter.includeSoldItems {
                let soldAnalysis = try await apiService.analyzeSoldItems(
                    keywords: filter.name,
                    categoryID: filter.categoryID,
                    condition: filter.condition,
                    daysSold: 30
                )

                // Convert sold listings to EbayListing format for display
                let soldAsEbayListings = soldAnalysis.soldListings.map { soldListing in
                    EbayListing(
                        itemID: soldListing.id.uuidString,
                        title: soldListing.title,
                        price: soldListing.soldPrice,
                        currency: "USD",
                        condition: soldListing.condition?.displayName ?? "Unknown",
                        imageURL: soldListing.imageUrl,
                        listingURL: "https://ebay.com/\(soldListing.id.uuidString)",
                        endTime: soldListing.soldDate,
                        location: soldListing.location,
                        shippingCost: 0.0,
                        buyItNowPrice: soldListing.soldPrice,
                        isAuction: false,
                        seller: EbayListing.SellerInfo(
                            username: soldListing.sellerName,
                            feedbackScore: soldListing.sellerFeedback,
                            feedbackPercentage: 98.0
                        ),
                        dealScore: .good,
                        averageMarketPrice: nil,
                        savingsAmount: nil,
                        savingsPercentage: nil,
                        isSoldListing: true
                    )
                }

                allListings.append(contentsOf: soldAsEbayListings)
            }

            // Track this search in recent searches and price history
            DispatchQueue.main.async {
                self.addRecentSearch(keywords: filter.name, resultCount: listings.count)

                // Track price history for all listings
                for listing in listings {
                    self.trackPriceHistory(for: listing)
                }
            }

            let result = SearchResult(
                filter: filter,
                listings: allListings,
                marketAnalysis: analysis,
                lastUpdated: Date()
            )

            DispatchQueue.main.async {
                self.searchResults[filter.id] = result
                self.loadingFilters.remove(filter.id)
                self.isLoading = !self.loadingFilters.isEmpty

                // Update market analysis for the insights view
                self.selectedFilter = filter
                self.marketAnalysis = analysis

                // Update the filter's last checked time
                if let index = self.filters.firstIndex(where: { $0.id == filter.id }) {
                    self.filters[index].lastChecked = Date()
                    self.saveFilters()
                }
            }

            // Check for deals and notify based on filter settings
            checkDealsAndNotify(listings: listings, filter: filter)

        } catch let error as EbayAPIError {
            DispatchQueue.main.async {
                self.loadingFilters.remove(filter.id)
                self.isLoading = !self.loadingFilters.isEmpty
                self.handleAPIError(error)
            }
        } catch {
            DispatchQueue.main.async {
                self.loadingFilters.remove(filter.id)
                self.isLoading = !self.loadingFilters.isEmpty
                self.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                self.showingErrorAlert = true
            }
        }
    }

    func checkAllActiveFilters() async {
        for filter in filters where filter.isActive {
            await searchListings(for: filter)
        }
    }

    func selectFilterForMarketAnalysis(_ filter: SearchFilter) {
        selectedFilter = filter
        if let result = searchResults[filter.id] {
            marketAnalysis = result.marketAnalysis
        }
    }

    // MARK: - Error Handling

    private func handleAPIError(_ error: EbayAPIError) {
        switch error {
        case .authenticationError:
            self.errorMessage = "Please configure your eBay API credentials in Settings"
        case .rateLimitExceeded:
            self.errorMessage = "Rate limit exceeded. Please try again later."
        case .httpError(let code):
            self.errorMessage = "Server error (\(code)). Please try again."
        case .invalidURL:
            self.errorMessage = "Invalid request. Please check your search parameters."
        case .invalidResponse:
            self.errorMessage = "Invalid response from eBay API."
        case .decodingError:
            self.errorMessage = "Failed to process eBay data. Please try again."
        case .networkError:
            self.errorMessage = "Failed to process eBay data due to a network error. Please check network and try again"
        }
        self.showingErrorAlert = true
    }

    // MARK: - Persistence

    private func saveFilters() {
        if let encoded = try? JSONEncoder().encode(filters) {
            userDefaults.set(encoded, forKey: filtersKey)
        }
    }

    private func loadFilters() {
        if let data = userDefaults.data(forKey: filtersKey),
           let decoded = try? JSONDecoder().decode([SearchFilter].self, from: data) {
            filters = decoded
        }
    }

    private func loadRecentSearches() {
        if let data = userDefaults.data(forKey: recentSearchesKey),
           let decoded = try? JSONDecoder().decode([RecentSearch].self, from: data) {
            recentSearches = decoded.sorted { $0.searchDate > $1.searchDate }
        }
    }

    private func saveRecentSearches() {
        if let encoded = try? JSONEncoder().encode(recentSearches) {
            userDefaults.set(encoded, forKey: recentSearchesKey)
        }
    }

    private func loadPriceHistories() {
        if let data = userDefaults.data(forKey: priceHistoriesKey),
           let decoded = try? JSONDecoder().decode([ItemPriceHistory].self, from: data) {
            priceHistories = decoded
        }
    }

    private func savePriceHistories() {
        if let encoded = try? JSONEncoder().encode(priceHistories) {
            userDefaults.set(encoded, forKey: priceHistoriesKey)
        }
    }

    private func loadSavedComparisons() {
        if let data = userDefaults.data(forKey: savedComparisonsKey),
           let decoded = try? JSONDecoder().decode([ListingComparison].self, from: data) {
            savedComparisons = decoded.sorted { $0.createdDate > $1.createdDate }
        }
    }

    private func saveSavedComparisons() {
        if let encoded = try? JSONEncoder().encode(savedComparisons) {
            userDefaults.set(encoded, forKey: savedComparisonsKey)
        }
    }

    // MARK: - Recent Searches

    func addRecentSearch(keywords: String, resultCount: Int? = nil) {
        // Remove existing search with same keywords
        recentSearches.removeAll { $0.keywords.lowercased() == keywords.lowercased() }

        // Add new search at the beginning
        let newSearch = RecentSearch(keywords: keywords, searchDate: Date(), resultCount: resultCount)
        recentSearches.insert(newSearch, at: 0)

        // Keep only last 20 searches
        if recentSearches.count > 20 {
            recentSearches = Array(recentSearches.prefix(20))
        }

        saveRecentSearches()
    }

    func clearRecentSearches() {
        recentSearches.removeAll()
        saveRecentSearches()
    }

    // MARK: - Search Suggestions

    func generateSearchSuggestions(for query: String) {
        let lowercaseQuery = query.lowercased()
        var suggestions: [SearchSuggestion] = []

        // Recent searches matching query
        let recentMatches = recentSearches.filter {
            $0.keywords.lowercased().contains(lowercaseQuery)
        }.prefix(3)

        for recent in recentMatches {
            suggestions.append(SearchSuggestion(
                text: recent.keywords,
                type: .recent,
                categoryID: nil
            ))
        }

        // Common templates matching query
        let templateMatches = PresetSearchTemplate.commonTemplates.filter {
            $0.keywords.lowercased().contains(lowercaseQuery) ||
            $0.name.lowercased().contains(lowercaseQuery)
        }.prefix(5)

        for template in templateMatches {
            suggestions.append(SearchSuggestion(
                text: template.keywords,
                type: .keyword,
                categoryID: template.categoryID
            ))
        }

        // Popular keywords from trending categories
        for category in TrendingCategory.trendingCategories {
            for keyword in category.popularKeywords {
                if keyword.lowercased().contains(lowercaseQuery) {
                    suggestions.append(SearchSuggestion(
                        text: keyword,
                        type: .brand,
                        categoryID: category.id
                    ))
                }
            }
        }

        // Categories matching query
        let categoryMatches = SearchFilter.EbayCategory.categories.filter {
            $0.name.lowercased().contains(lowercaseQuery)
        }.prefix(3)

        for category in categoryMatches {
            suggestions.append(SearchSuggestion(
                text: category.name,
                type: .category,
                categoryID: category.id
            ))
        }

        // Remove duplicates and limit results
        let uniqueSuggestions = suggestions.reduce(into: [SearchSuggestion]()) { result, suggestion in
            if !result.contains(where: { $0.text.lowercased() == suggestion.text.lowercased() }) {
                result.append(suggestion)
            }
        }

        searchSuggestions = Array(uniqueSuggestions.prefix(8))
    }
}

// MARK: - Comparison Management

extension EbayDealFinderViewModel {

    func startComparison(with listing: EbayListing) {
        activeComparison = ListingComparison(listings: [listing])
    }

    func addToComparison(_ listing: EbayListing) {
        guard var comparison = activeComparison,
              comparison.canAddListing() else { return }

        // Don't add duplicate items
        if !comparison.listings.contains(where: { $0.itemID == listing.itemID }) {
            comparison.listings.append(listing)
            activeComparison = comparison
        }
    }

    func removeFromComparison(_ listing: EbayListing) {
        guard var comparison = activeComparison else { return }
        comparison.listings.removeAll { $0.itemID == listing.itemID }

        if comparison.listings.isEmpty {
            activeComparison = nil
        } else {
            activeComparison = comparison
        }
    }

    func clearComparison() {
        activeComparison = nil
    }

    func saveComparison() {
        guard let comparison = activeComparison,
              !comparison.listings.isEmpty else { return }

        savedComparisons.append(comparison)
        saveSavedComparisons()
        activeComparison = nil
    }

    func deleteComparison(_ comparison: ListingComparison) {
        savedComparisons.removeAll { $0.id == comparison.id }
        saveSavedComparisons()
    }
}

// MARK: - Price History Management

extension EbayDealFinderViewModel {

    func trackPriceHistory(for listing: EbayListing) {
        let pricePoint = PriceHistoryPoint(
            itemID: listing.itemID,
            price: listing.price,
            timestamp: Date(),
            source: "current",
            condition: listing.condition
        )

        if let index = priceHistories.firstIndex(where: { $0.itemID == listing.itemID }) {
            // Update existing history
            priceHistories[index].pricePoints.append(pricePoint)
            priceHistories[index].lastUpdated = Date()

            // Keep only last 100 points to manage storage
            if priceHistories[index].pricePoints.count > 100 {
                priceHistories[index].pricePoints = Array(priceHistories[index].pricePoints.suffix(100))
            }
        } else {
            // Create new history
            let history = ItemPriceHistory(
                itemID: listing.itemID,
                title: listing.title,
                pricePoints: [pricePoint]
            )
            priceHistories.append(history)
        }

        savePriceHistories()
    }

    func getPriceHistory(for itemID: String) -> ItemPriceHistory? {
        return priceHistories.first { $0.itemID == itemID }
    }
}

// MARK: - Similar Items

extension EbayDealFinderViewModel {

    func findSimilarItems(to listing: EbayListing, from allListings: [EbayListing]) -> [SimilarItem] {
        let targetWords = Set(listing.title.lowercased().components(separatedBy: .whitespacesAndNewlines))

        let similarItems = allListings.compactMap { candidateListing -> SimilarItem? in
            guard candidateListing.itemID != listing.itemID else { return nil }

            var reasons: [SimilarItem.SimilarityReason] = []
            var score: Double = 0

            // Category similarity
            if let targetCategory = extractCategoryFromListing(listing),
               let candidateCategory = extractCategoryFromListing(candidateListing),
               targetCategory == candidateCategory {
                reasons.append(.category)
                score += 0.3
            }

            // Brand similarity (simple keyword matching)
            let targetBrands = extractBrands(from: listing.title)
            let candidateBrands = extractBrands(from: candidateListing.title)
            if !targetBrands.isDisjoint(with: candidateBrands) {
                reasons.append(.brand)
                score += 0.25
            }

            // Price range similarity (within 30%)
            let priceDifference = abs(listing.price - candidateListing.price) / listing.price
            if priceDifference <= 0.3 {
                reasons.append(.priceRange)
                score += 0.2
            }

            // Keywords similarity
            let candidateWords = Set(candidateListing.title.lowercased().components(separatedBy: .whitespacesAndNewlines))
            let commonWords = targetWords.intersection(candidateWords)
            let keywordSimilarity = Double(commonWords.count) / Double(targetWords.union(candidateWords).count)
            if keywordSimilarity > 0.3 {
                reasons.append(.keywords)
                score += keywordSimilarity * 0.2
            }

            // Condition similarity
            if listing.condition == candidateListing.condition {
                reasons.append(.condition)
                score += 0.1
            }

            // Seller similarity
            if listing.seller.username == candidateListing.seller.username {
                reasons.append(.seller)
                score += 0.05
            }

            // Only return items with some similarity
            guard score > 0.2 && !reasons.isEmpty else { return nil }

            return SimilarItem(
                listing: candidateListing,
                similarityScore: score,
                similarityReasons: reasons
            )
        }

        return similarItems.sorted { $0.similarityScore > $1.similarityScore }.prefix(10).map { $0 }
    }

    private func extractBrands(from title: String) -> Set<String> {
        let commonBrands = ["apple", "samsung", "sony", "nintendo", "microsoft", "google", "lg", "hp", "dell", "lenovo", "asus", "acer", "canon", "nikon", "intel", "amd", "nvidia"]
        let words = title.lowercased().components(separatedBy: .whitespacesAndNewlines)
        return Set(words.filter { commonBrands.contains($0) })
    }

    private func extractCategoryFromListing(_ listing: EbayListing) -> String? {
        // In a real app, this would use the actual eBay category from API
        // For now, we'll do simple keyword-based category detection
        let title = listing.title.lowercased()

        if title.contains("iphone") || title.contains("samsung") || title.contains("phone") {
            return "phones"
        } else if title.contains("laptop") || title.contains("macbook") || title.contains("computer") {
            return "computers"
        } else if title.contains("game") || title.contains("playstation") || title.contains("xbox") || title.contains("nintendo") {
            return "gaming"
        } else if title.contains("watch") || title.contains("jewelry") {
            return "accessories"
        }

        return nil
    }
}

// MARK: - Notification Management

extension EbayDealFinderViewModel {

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }

    private func checkDealsAndNotify(listings: [EbayListing], filter: SearchFilter) {
        guard filter.notificationSettings.isEnabled,
              !filter.notificationSettings.isSnoozed else { return }

        let notifyingDeals = listings.filter { listing in
            // Check deal score threshold
            if !filter.notificationSettings.dealScoreThreshold.shouldNotify(for: listing.dealScore) {
                return false
            }

            // Check savings threshold if set
            if let minSavings = filter.notificationSettings.maxSavingsThreshold,
               let savings = listing.savingsAmount,
               savings < minSavings {
                return false
            }

            // Check price drop threshold if set
            if let priceDropThreshold = filter.notificationSettings.priceDropThreshold,
               let savingsPercentage = listing.savingsPercentage,
               savingsPercentage < priceDropThreshold {
                return false
            }

            return true
        }

        if !notifyingDeals.isEmpty {
            sendRichDealNotification(deals: notifyingDeals, filter: filter)
        }
    }

    private func sendRichDealNotification(deals: [EbayListing], filter: SearchFilter) {
        let content = UNMutableNotificationContent()

        // Rich content
        if deals.count == 1 {
            let deal = deals[0]
            content.title = "🎯 Great Deal Found!"
            content.body = "\(deal.title) - $\(String(format: "%.0f", deal.price))"
            if let savings = deal.savingsAmount {
                content.body += " (Save $\(String(format: "%.0f", savings)))"
            }
        } else {
            content.title = "🎯 \(deals.count) Great Deals Found!"
            content.body = "New deals for '\(filter.name)'"
            let totalSavings = deals.compactMap { $0.savingsAmount }.reduce(0, +)
            if totalSavings > 0 {
                content.body += " - Save up to $\(String(format: "%.0f", totalSavings))"
            }
        }

        content.sound = UNNotificationSound.default
        content.badge = NSNumber(value: deals.count)

        // User info for handling actions
        content.userInfo = [
            "filterId": filter.id.uuidString,
            "dealCount": deals.count,
            "filterName": filter.name
        ]

        // Add image if available
        if let firstDeal = deals.first,
           let imageURL = firstDeal.imageURL,
           let url = URL(string: imageURL) {
            downloadImageForNotification(url: url) { attachment in
                if let attachment = attachment {
                    content.attachments = [attachment]
                }
                self.scheduleNotification(content: content, filter: filter)
            }
        } else {
            scheduleNotification(content: content, filter: filter)
        }
    }

    private func downloadImageForNotification(url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let attachment = try? UNNotificationAttachment(
                    identifier: UUID().uuidString,
                    url: self.saveImageForNotification(data: data),
                    options: [UNNotificationAttachmentOptionsTypeHintKey: "public.jpeg"]
                  ) else {
                completion(nil)
                return
            }
            completion(attachment)
        }.resume()
    }

    private func saveImageForNotification(data: Data) -> URL {
        let tempDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
        let fileName = "\(UUID().uuidString).jpg"
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        try? data.write(to: fileURL)
        return fileURL
    }

    private func scheduleNotification(content: UNMutableNotificationContent, filter: SearchFilter) {
        // Add action buttons
        let viewAction = UNNotificationAction(
            identifier: "VIEW_DEALS",
            title: "View Deals",
            options: [.foreground]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_1H",
            title: "Snooze 1h",
            options: []
        )

        let disableAction = UNNotificationAction(
            identifier: "DISABLE_ALERTS",
            title: "Turn Off",
            options: [.destructive]
        )

        let category = UNNotificationCategory(
            identifier: "DEAL_ALERT",
            actions: [viewAction, snoozeAction, disableAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
        content.categoryIdentifier = "DEAL_ALERT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "deal_\(filter.id.uuidString)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            } else {
                // Update notification tracking
                DispatchQueue.main.async {
                    if let index = self.filters.firstIndex(where: { $0.id == filter.id }) {
                        self.filters[index].notificationSettings.lastNotificationDate = Date()
                        self.filters[index].notificationSettings.notificationCount += 1
                        self.saveFilters()
                    }
                }
            }
        }
    }

    func snoozeNotifications(for filter: SearchFilter, duration: NotificationSettings.SnoozeDuration) {
        if let index = filters.firstIndex(where: { $0.id == filter.id }) {
            filters[index].notificationSettings.snooze(for: duration)
            saveFilters()
        }
    }

    func disableNotifications(for filter: SearchFilter) {
        if let index = filters.firstIndex(where: { $0.id == filter.id }) {
            filters[index].notificationSettings.isEnabled = false
            saveFilters()
        }
    }

    func clearSnooze(for filter: SearchFilter) {
        if let index = filters.firstIndex(where: { $0.id == filter.id }) {
            filters[index].notificationSettings.clearSnooze()
            saveFilters()
        }
    }

    func updateNotificationSettings(for filter: SearchFilter, settings: NotificationSettings) {
        if let index = filters.firstIndex(where: { $0.id == filter.id }) {
            filters[index].notificationSettings = settings
            saveFilters()
        }
    }
}
