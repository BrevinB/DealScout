//
//  SearchFilter.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import Foundation

// MARK: - Search Filter Models

/// A comprehensive search filter for eBay searches
struct SearchFilter: Identifiable, Codable {

    // MARK: - Nested Types

    /// Item condition enumeration
    enum ItemCondition: String, CaseIterable, Codable, Hashable {
        case new = "1000"
        case openBox = "1500"
        case refurbished = "2000"
        case used = "3000"

        var displayName: String {
            switch self {
            case .new: return "New"
            case .openBox: return "Open Box"
            case .refurbished: return "Refurbished"
            case .used: return "Used"
            }
        }
    }

    /// Price direction trend
    enum PriceDirection: String, Codable {
        case ascending = "up"
        case descending = "down"
        case stable = "stable"

        var systemImageName: String {
            switch self {
            case .ascending: return "arrow.up.circle.fill"
            case .descending: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .ascending: return .red
            case .descending: return .green
            case .stable: return .gray
            }
        }
    }

    /// Listing type filter
    enum ListingType: String, CaseIterable, Codable, Hashable {
        case all = "All"
        case auction = "Auction"
        case buyItNow = "BuyItNow"
        case buyItNowOrBestOffer = "BuyItNowOrBestOffer"
        case classified = "Classified"

        var displayName: String {
            switch self {
            case .all: return "All Types"
            case .auction: return "Auction"
            case .buyItNow: return "Buy It Now"
            case .buyItNowOrBestOffer: return "Buy It Now + Best Offer"
            case .classified: return "Classified"
            }
        }
    }

    /// Sort order options
    enum SortOrder: String, CaseIterable, Codable, Hashable {
        case bestMatch = "BestMatch"
        case pricePlusShippingLowest = "PricePlusShippingLowest"
        case pricePlusShippingHighest = "PricePlusShippingHighest"
        case endTimeSoonest = "EndTimeSoonest"
        case startTimeNewest = "StartTimeNewest"
        case distanceNearest = "DistanceNearest"
        case currentBidHighest = "CurrentBidHighest"
        case bidCountMost = "BidCountMost"
        case priceLowest = "PriceLowest"
        case priceHighest = "PriceHighest"

        var displayName: String {
            switch self {
            case .bestMatch: return "Best Match"
            case .pricePlusShippingLowest: return "Price + Shipping: Lowest"
            case .pricePlusShippingHighest: return "Price + Shipping: Highest"
            case .endTimeSoonest: return "Ending Soonest"
            case .startTimeNewest: return "Newly Listed"
            case .distanceNearest: return "Distance: Nearest"
            case .currentBidHighest: return "Highest Current Bid"
            case .bidCountMost: return "Most Bids"
            case .priceLowest: return "Price: Lowest"
            case .priceHighest: return "Price: Highest"
            }
        }
    }

    /// Location-based filtering
    struct LocationFilter: Codable {
        let country: String?
        let state: String?
        let zipCode: String?
        let maximumDistance: Int?
        let localPickupOnly: Bool

        var displayText: String {
            var components: [String] = []
            if let country = country { components.append(country) }
            if let state = state { components.append(state) }
            if let zipCode = zipCode { components.append(zipCode) }
            return components.isEmpty ? "Any Location" : components.joined(separator: ", ")
        }
    }

    /// Shipping-related filters
    struct ShippingFilter: Codable {
        let freeShippingOnly: Bool
        let localPickupAvailable: Bool
        let maximumShippingCost: Double?
        let expeditedShipping: Bool

        var displayText: String {
            var components: [String] = []
            if freeShippingOnly { components.append("free shipping") }
            if localPickupAvailable { components.append("local pickup") }
            if let maxCost = maximumShippingCost {
                components.append("shipping ≤ $\(String(format: "%.0f", maxCost))")
            }
            if expeditedShipping { components.append("expedited") }
            return components.isEmpty ? "Any Shipping" : components.joined(separator: ", ")
        }
    }

    /// Seller-related filters
    struct SellerFilter: Codable {
        let minimumFeedbackScore: Int?
        let minimumFeedbackPercentage: Double?
        let topRatedSellersOnly: Bool
        let businessSellersOnly: Bool

        var displayText: String {
            var components: [String] = []
            if let minScore = minimumFeedbackScore { components.append("≥\(minScore) feedback") }
            if let minPercentage = minimumFeedbackPercentage {
                components.append("≥\(String(format: "%.0f", minPercentage))%")
            }
            if topRatedSellersOnly { components.append("top rated") }
            if businessSellersOnly { components.append("business sellers") }
            return components.isEmpty ? "Any Seller" : components.joined(separator: ", ")
        }
    }

    /// Auction-specific filters
    struct AuctionFilter: Codable {
        let endingWithinHours: Int?
        let minimumBidCount: Int?
        let maximumBidCount: Int?
        let noBidsOnly: Bool
        let hasReservePrice: Bool?

        var displayText: String {
            var components: [String] = []
            if let hours = endingWithinHours {
                components.append("ending in \(hours)h")
            }
            if let minBids = minimumBidCount {
                components.append("≥\(minBids) bids")
            }
            if let maxBids = maximumBidCount {
                components.append("≤\(maxBids) bids")
            }
            if noBidsOnly {
                components.append("no bids")
            }
            if let hasReserve = hasReservePrice {
                components.append(hasReserve ? "with reserve" : "no reserve")
            }
            return components.isEmpty ? "Any Auction" : components.joined(separator: ", ")
        }
    }

    /// Special listing features filter
    struct ListingFeatures: Codable {
        let acceptsBestOffer: Bool
        let buyItNowAvailable: Bool
        let returnsAccepted: Bool
        let authorizedSeller: Bool
        let dealsAndSavings: Bool
        let saleItems: Bool
        let benefitsCharity: Bool
        let authenticityGuarantee: Bool
        let watchedItems: Bool
        let soldListings: Bool
        let completedListings: Bool
        let listingsAsLots: Bool

        var displayText: String {
            var components: [String] = []
            if acceptsBestOffer { components.append("best offer") }
            if buyItNowAvailable { components.append("buy it now") }
            if returnsAccepted { components.append("returns accepted") }
            if authorizedSeller { components.append("authorized seller") }
            if dealsAndSavings { components.append("deals & savings") }
            if saleItems { components.append("sale items") }
            if benefitsCharity { components.append("charity") }
            if authenticityGuarantee { components.append("authenticity guarantee") }
            if watchedItems { components.append("watched") }
            if soldListings { components.append("sold listings") }
            if completedListings { components.append("completed listings") }
            if listingsAsLots { components.append("lots") }
            return components.isEmpty ? "Any Features" : components.joined(separator: ", ")
        }
    }

    /// Item specifics and attributes filter
    struct ItemSpecifics: Codable {
        let brand: String?
        let model: String?
        let size: String?
        let color: String?
        let material: String?
        let customAttributes: [String: String]

        var displayText: String {
            var components: [String] = []
            if let brand = brand { components.append("Brand: \(brand)") }
            if let model = model { components.append("Model: \(model)") }
            if let size = size { components.append("Size: \(size)") }
            if let color = color { components.append("Color: \(color)") }
            if let material = material { components.append("Material: \(material)") }
            components.append(contentsOf: customAttributes.map { "\($0.key): \($0.value)" })
            return components.isEmpty ? "Any Specifics" : components.joined(separator: ", ")
        }
    }

    /// Price and payment filters
    struct PaymentFilter: Codable {
        let acceptsPayPal: Bool
        let acceptsCreditCards: Bool
        let buyerPaysShipping: Bool?
        let priceDropPercentage: Double?
        let onSaleOnly: Bool

        var displayText: String {
            var components: [String] = []
            if acceptsPayPal { components.append("PayPal") }
            if acceptsCreditCards { components.append("credit cards") }
            if let buyerPays = buyerPaysShipping {
                components.append(buyerPays ? "buyer pays shipping" : "seller pays shipping")
            }
            if let dropPercent = priceDropPercentage {
                components.append("\(Int(dropPercent))% price drop")
            }
            if onSaleOnly { components.append("on sale") }
            return components.isEmpty ? "Any Payment" : components.joined(separator: ", ")
        }
    }

    /// Photo and media filters
    struct PhotoFilter: Codable {
        let picturesOnly: Bool
        let galleryViewAvailable: Bool
        let moreThanTwelvePhotos: Bool

        var displayText: String {
            var components: [String] = []
            if picturesOnly { components.append("with pictures") }
            if galleryViewAvailable { components.append("gallery view") }
            if moreThanTwelvePhotos { components.append("12+ photos") }
            return components.isEmpty ? "Any Photos" : components.joined(separator: ", ")
        }
    }

    /// Advanced keyword filtering options
    struct KeywordFilter: Codable {
        let searchTitle: Bool
        let searchDescription: Bool
        let exactPhraseOnly: Bool
        let anyOfTheseWords: String?
        let excludeTheseWords: String?
        let atLeastOneOfTheseWords: String?

        var displayText: String {
            var components: [String] = []
            if searchTitle && searchDescription {
                components.append("title & description")
            } else if searchTitle {
                components.append("title only")
            } else if searchDescription {
                components.append("description only")
            }
            if exactPhraseOnly { components.append("exact phrase") }
            if let anyWords = anyOfTheseWords, !anyWords.isEmpty {
                components.append("any: \(anyWords)")
            }
            if let excludeWords = excludeTheseWords, !excludeWords.isEmpty {
                components.append("exclude: \(excludeWords)")
            }
            if let atLeastWords = atLeastOneOfTheseWords, !atLeastWords.isEmpty {
                components.append("at least: \(atLeastWords)")
            }
            return components.isEmpty ? "Any Keywords" : components.joined(separator: ", ")
        }
    }

    /// eBay category information
    struct EbayCategory: Codable, Identifiable, Hashable {
        let id: String
        let name: String

        static let categories: [EbayCategory] = [
            EbayCategory(id: "58058", name: "Computers/Tablets & Networking"),
            EbayCategory(id: "9355", name: "Cell Phones & Accessories"),
            EbayCategory(id: "1249", name: "Video Games & Consoles"),
            EbayCategory(id: "293", name: "Consumer Electronics"),
            EbayCategory(id: "15032", name: "Cameras & Photo"),
            EbayCategory(id: "11450", name: "Clothing, Shoes & Accessories"),
            EbayCategory(id: "2984", name: "Home & Garden"),
            EbayCategory(id: "6028", name: "Motors"),
            EbayCategory(id: "1", name: "Collectibles"),
            EbayCategory(id: "550", name: "Art"),
            EbayCategory(id: "888", name: "Everything Else")
        ]
    }

    // MARK: - Properties

    let id = UUID()
    var name: String
    var categoryID: String?
    var minimumPrice: Double?
    var maximumPrice: Double?
    var condition: ItemCondition?
    var isActive: Bool = true
    var lastChecked: Date = Date()
    var averageSoldPrice: Double?
    var priceDirection: PriceDirection = .stable
    var notificationSettings = NotificationSettings()

    // Enhanced filtering options
    var listingType: ListingType?
    var location: LocationFilter?
    var shippingOptions: ShippingFilter?
    var sellerFilters: SellerFilter?
    var sortOrder: SortOrder = .bestMatch
    var excludeKeywords: String?
    var includeSoldItems: Bool = false

    // Advanced eBay filtering options
    var auctionFilters: AuctionFilter?
    var listingFeatures: ListingFeatures?
    var itemSpecifics: ItemSpecifics?
    var paymentFilters: PaymentFilter?
    var photoFilters: PhotoFilter?
    var keywordFilters: KeywordFilter?

    // MARK: - Initializers

    init(
        name: String,
        categoryID: String? = nil,
        minimumPrice: Double? = nil,
        maximumPrice: Double? = nil,
        condition: ItemCondition? = nil,
        listingType: ListingType? = nil,
        location: LocationFilter? = nil,
        shippingOptions: ShippingFilter? = nil,
        sellerFilters: SellerFilter? = nil,
        sortOrder: SortOrder = .bestMatch,
        excludeKeywords: String? = nil,
        auctionFilters: AuctionFilter? = nil,
        listingFeatures: ListingFeatures? = nil,
        itemSpecifics: ItemSpecifics? = nil,
        paymentFilters: PaymentFilter? = nil,
        photoFilters: PhotoFilter? = nil,
        keywordFilters: KeywordFilter? = nil
    ) {
        self.name = name
        self.categoryID = categoryID
        self.minimumPrice = minimumPrice
        self.maximumPrice = maximumPrice
        self.condition = condition
        self.listingType = listingType
        self.location = location
        self.shippingOptions = shippingOptions
        self.sellerFilters = sellerFilters
        self.sortOrder = sortOrder
        self.excludeKeywords = excludeKeywords
        self.auctionFilters = auctionFilters
        self.listingFeatures = listingFeatures
        self.itemSpecifics = itemSpecifics
        self.paymentFilters = paymentFilters
        self.photoFilters = photoFilters
        self.keywordFilters = keywordFilters
    }

    // MARK: - Computed Properties

    var hasActiveFilters: Bool {
        return minimumPrice != nil ||
               maximumPrice != nil ||
               condition != nil ||
               listingType != nil ||
               location != nil ||
               shippingOptions != nil ||
               sellerFilters != nil ||
               !(excludeKeywords?.isEmpty ?? true) ||
               auctionFilters != nil ||
               listingFeatures != nil ||
               itemSpecifics != nil ||
               paymentFilters != nil ||
               photoFilters != nil ||
               keywordFilters != nil
    }
}

// MARK: - Color Extension

import SwiftUI

extension Color {
    static let systemGray6 = Color(.systemGray6)
}
