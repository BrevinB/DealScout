//
//  FilterDetailViews.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import SwiftUI

// MARK: - Location Filter View

struct LocationFilterView: View {
    @Binding var filter: SearchFilter.LocationFilter?
    @Environment(\.dismiss) private var dismiss

    @State private var country = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var maximumDistance = ""
    @State private var localPickupOnly = false

    var body: some View {
        NavigationView {
            Form {
                Section("Location") {
                    TextField("Country", text: $country)
                    TextField("State/Province", text: $state)
                    TextField("ZIP/Postal Code", text: $zipCode)
                }

                Section("Distance") {
                    TextField("Maximum Distance (miles)", text: $maximumDistance)
                        .keyboardType(.numberPad)

                    Toggle("Local Pickup Only", isOn: $localPickupOnly)
                }
            }
            .navigationTitle("Location Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let filter = filter else { return }
        country = filter.country ?? ""
        state = filter.state ?? ""
        zipCode = filter.zipCode ?? ""
        maximumDistance = filter.maximumDistance != nil ? String(filter.maximumDistance!) : ""
        localPickupOnly = filter.localPickupOnly
    }

    private func saveFilter() {
        let hasContent = !country.isEmpty || !state.isEmpty || !zipCode.isEmpty ||
                        !maximumDistance.isEmpty || localPickupOnly

        if hasContent {
            filter = SearchFilter.LocationFilter(
                country: country.isEmpty ? nil : country,
                state: state.isEmpty ? nil : state,
                zipCode: zipCode.isEmpty ? nil : zipCode,
                maximumDistance: Int(maximumDistance),
                localPickupOnly: localPickupOnly
            )
        } else {
            filter = nil
        }
        dismiss()
    }
}

// MARK: - Shipping Filter View

struct ShippingFilterView: View {
    @Binding var filter: SearchFilter.ShippingFilter?
    @Environment(\.dismiss) private var dismiss

    @State private var freeShippingOnly = false
    @State private var localPickupAvailable = false
    @State private var maximumShippingCost = ""
    @State private var expeditedShipping = false

    var body: some View {
        NavigationView {
            Form {
                Section("Shipping Options") {
                    Toggle("Free Shipping Only", isOn: $freeShippingOnly)
                    Toggle("Local Pickup Available", isOn: $localPickupAvailable)
                    Toggle("Expedited Shipping", isOn: $expeditedShipping)
                }

                Section("Shipping Cost") {
                    TextField("Maximum Shipping Cost", text: $maximumShippingCost)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle("Shipping Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let filter = filter else { return }
        freeShippingOnly = filter.freeShippingOnly
        localPickupAvailable = filter.localPickupAvailable
        maximumShippingCost = filter.maximumShippingCost != nil ? String(filter.maximumShippingCost!) : ""
        expeditedShipping = filter.expeditedShipping
    }

    private func saveFilter() {
        let hasContent = freeShippingOnly || localPickupAvailable || expeditedShipping || !maximumShippingCost.isEmpty

        if hasContent {
            filter = SearchFilter.ShippingFilter(
                freeShippingOnly: freeShippingOnly,
                localPickupAvailable: localPickupAvailable,
                maximumShippingCost: Double(maximumShippingCost),
                expeditedShipping: expeditedShipping
            )
        } else {
            filter = nil
        }
        dismiss()
    }
}

// MARK: - Seller Filter View

struct SellerFilterView: View {
    @Binding var filter: SearchFilter.SellerFilter?
    @Environment(\.dismiss) private var dismiss

    @State private var minimumFeedbackScore = ""
    @State private var minimumFeedbackPercentage = ""
    @State private var topRatedSellersOnly = false
    @State private var businessSellersOnly = false

    var body: some View {
        NavigationView {
            Form {
                Section("Seller Reputation") {
                    TextField("Minimum Feedback Score", text: $minimumFeedbackScore)
                        .keyboardType(.numberPad)

                    TextField("Minimum Feedback %", text: $minimumFeedbackPercentage)
                        .keyboardType(.decimalPad)
                }

                Section("Seller Type") {
                    Toggle("Top Rated Sellers Only", isOn: $topRatedSellersOnly)
                    Toggle("Business Sellers Only", isOn: $businessSellersOnly)
                }
            }
            .navigationTitle("Seller Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let filter = filter else { return }
        minimumFeedbackScore = filter.minimumFeedbackScore != nil ? String(filter.minimumFeedbackScore!) : ""
        minimumFeedbackPercentage = filter.minimumFeedbackPercentage != nil ? String(filter.minimumFeedbackPercentage!) : ""
        topRatedSellersOnly = filter.topRatedSellersOnly
        businessSellersOnly = filter.businessSellersOnly
    }

    private func saveFilter() {
        let hasContent = !minimumFeedbackScore.isEmpty || !minimumFeedbackPercentage.isEmpty ||
                        topRatedSellersOnly || businessSellersOnly

        if hasContent {
            filter = SearchFilter.SellerFilter(
                minimumFeedbackScore: Int(minimumFeedbackScore),
                minimumFeedbackPercentage: Double(minimumFeedbackPercentage),
                topRatedSellersOnly: topRatedSellersOnly,
                businessSellersOnly: businessSellersOnly
            )
        } else {
            filter = nil
        }
        dismiss()
    }
}

// MARK: - Auction Filter View

struct AuctionFilterView: View {
    @Binding var filter: SearchFilter.AuctionFilter?
    @Environment(\.dismiss) private var dismiss

    @State private var endingWithinHours = ""
    @State private var minimumBidCount = ""
    @State private var maximumBidCount = ""
    @State private var noBidsOnly = false
    @State private var hasReservePrice: Bool?

    var body: some View {
        NavigationView {
            Form {
                Section("Auction Timing") {
                    TextField("Ending Within Hours", text: $endingWithinHours)
                        .keyboardType(.numberPad)
                }

                Section("Bid Requirements") {
                    TextField("Minimum Bid Count", text: $minimumBidCount)
                        .keyboardType(.numberPad)

                    TextField("Maximum Bid Count", text: $maximumBidCount)
                        .keyboardType(.numberPad)

                    Toggle("No Bids Only", isOn: $noBidsOnly)
                }

                Section("Reserve Price") {
                    Picker("Reserve Price", selection: Binding<Bool?>(
                        get: { hasReservePrice },
                        set: { hasReservePrice = $0 }
                    )) {
                        Text("Any").tag(Bool?.none)
                        Text("With Reserve").tag(Bool?.some(true))
                        Text("No Reserve").tag(Bool?.some(false))
                    }
                }
            }
            .navigationTitle("Auction Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let filter = filter else { return }
        endingWithinHours = filter.endingWithinHours != nil ? String(filter.endingWithinHours!) : ""
        minimumBidCount = filter.minimumBidCount != nil ? String(filter.minimumBidCount!) : ""
        maximumBidCount = filter.maximumBidCount != nil ? String(filter.maximumBidCount!) : ""
        noBidsOnly = filter.noBidsOnly
        hasReservePrice = filter.hasReservePrice
    }

    private func saveFilter() {
        let hasContent = !endingWithinHours.isEmpty || !minimumBidCount.isEmpty ||
                        !maximumBidCount.isEmpty || noBidsOnly || hasReservePrice != nil

        if hasContent {
            filter = SearchFilter.AuctionFilter(
                endingWithinHours: Int(endingWithinHours),
                minimumBidCount: Int(minimumBidCount),
                maximumBidCount: Int(maximumBidCount),
                noBidsOnly: noBidsOnly,
                hasReservePrice: hasReservePrice
            )
        } else {
            filter = nil
        }
        dismiss()
    }
}

// MARK: - Listing Features View

struct ListingFeaturesView: View {
    @Binding var filter: SearchFilter.ListingFeatures?
    @Environment(\.dismiss) private var dismiss

    @State private var acceptsBestOffer = false
    @State private var buyItNowAvailable = false
    @State private var returnsAccepted = false
    @State private var authorizedSeller = false
    @State private var dealsAndSavings = false
    @State private var saleItems = false
    @State private var benefitsCharity = false
    @State private var authenticityGuarantee = false
    @State private var watchedItems = false
    @State private var soldListings = false
    @State private var completedListings = false
    @State private var listingsAsLots = false

    var body: some View {
        NavigationView {
            Form {
                Section("Purchase Options") {
                    Toggle("Accepts Best Offer", isOn: $acceptsBestOffer)
                    Toggle("Buy It Now Available", isOn: $buyItNowAvailable)
                    Toggle("Returns Accepted", isOn: $returnsAccepted)
                }

                Section("Seller Features") {
                    Toggle("Authorized Seller", isOn: $authorizedSeller)
                    Toggle("Authenticity Guarantee", isOn: $authenticityGuarantee)
                }

                Section("Special Listings") {
                    Toggle("Deals & Savings", isOn: $dealsAndSavings)
                    Toggle("Sale Items", isOn: $saleItems)
                    Toggle("Benefits Charity", isOn: $benefitsCharity)
                    Toggle("Listings as Lots", isOn: $listingsAsLots)
                }

                Section("Listing History") {
                    Toggle("Watched Items", isOn: $watchedItems)
                    Toggle("Sold Listings", isOn: $soldListings)
                    Toggle("Completed Listings", isOn: $completedListings)
                }
            }
            .navigationTitle("Listing Features")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let filter = filter else { return }
        acceptsBestOffer = filter.acceptsBestOffer
        buyItNowAvailable = filter.buyItNowAvailable
        returnsAccepted = filter.returnsAccepted
        authorizedSeller = filter.authorizedSeller
        dealsAndSavings = filter.dealsAndSavings
        saleItems = filter.saleItems
        benefitsCharity = filter.benefitsCharity
        authenticityGuarantee = filter.authenticityGuarantee
        watchedItems = filter.watchedItems
        soldListings = filter.soldListings
        completedListings = filter.completedListings
        listingsAsLots = filter.listingsAsLots
    }

    private func saveFilter() {
        let hasContent = acceptsBestOffer || buyItNowAvailable || returnsAccepted || authorizedSeller ||
                        dealsAndSavings || saleItems || benefitsCharity || authenticityGuarantee ||
                        watchedItems || soldListings || completedListings || listingsAsLots

        if hasContent {
            filter = SearchFilter.ListingFeatures(
                acceptsBestOffer: acceptsBestOffer,
                buyItNowAvailable: buyItNowAvailable,
                returnsAccepted: returnsAccepted,
                authorizedSeller: authorizedSeller,
                dealsAndSavings: dealsAndSavings,
                saleItems: saleItems,
                benefitsCharity: benefitsCharity,
                authenticityGuarantee: authenticityGuarantee,
                watchedItems: watchedItems,
                soldListings: soldListings,
                completedListings: completedListings,
                listingsAsLots: listingsAsLots
            )
        } else {
            filter = nil
        }
        dismiss()
    }
}

// MARK: - Item Specifics View

struct ItemSpecificsView: View {
    @Binding var filter: SearchFilter.ItemSpecifics?
    @Environment(\.dismiss) private var dismiss

    @State private var brand = ""
    @State private var model = ""
    @State private var size = ""
    @State private var color = ""
    @State private var material = ""
    @State private var customAttributes: [String: String] = [:]
    @State private var newAttributeKey = ""
    @State private var newAttributeValue = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Common Attributes") {
                    TextField("Brand", text: $brand)
                    TextField("Model", text: $model)
                    TextField("Size", text: $size)
                    TextField("Color", text: $color)
                    TextField("Material", text: $material)
                }

                Section("Custom Attributes") {
                    ForEach(Array(customAttributes.keys), id: \.self) { key in
                        HStack {
                            Text(key)
                                .fontWeight(.medium)
                            Spacer()
                            Text(customAttributes[key] ?? "")
                                .foregroundColor(.secondary)
                        }
                        .swipeActions {
                            Button("Delete", role: .destructive) {
                                customAttributes.removeValue(forKey: key)
                            }
                        }
                    }

                    HStack {
                        TextField("Attribute Name", text: $newAttributeKey)
                        TextField("Value", text: $newAttributeValue)
                        Button("Add") {
                            if !newAttributeKey.isEmpty && !newAttributeValue.isEmpty {
                                customAttributes[newAttributeKey] = newAttributeValue
                                newAttributeKey = ""
                                newAttributeValue = ""
                            }
                        }
                        .disabled(newAttributeKey.isEmpty || newAttributeValue.isEmpty)
                    }
                }
            }
            .navigationTitle("Item Specifics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let filter = filter else { return }
        brand = filter.brand ?? ""
        model = filter.model ?? ""
        size = filter.size ?? ""
        color = filter.color ?? ""
        material = filter.material ?? ""
        customAttributes = filter.customAttributes
    }

    private func saveFilter() {
        let hasContent = !brand.isEmpty || !model.isEmpty || !size.isEmpty ||
                        !color.isEmpty || !material.isEmpty || !customAttributes.isEmpty

        if hasContent {
            filter = SearchFilter.ItemSpecifics(
                brand: brand.isEmpty ? nil : brand,
                model: model.isEmpty ? nil : model,
                size: size.isEmpty ? nil : size,
                color: color.isEmpty ? nil : color,
                material: material.isEmpty ? nil : material,
                customAttributes: customAttributes
            )
        } else {
            filter = nil
        }
        dismiss()
    }
}

// MARK: - Payment Filter View

struct PaymentFilterView: View {
    @Binding var filter: SearchFilter.PaymentFilter?
    @Environment(\.dismiss) private var dismiss

    @State private var acceptsPayPal = false
    @State private var acceptsCreditCards = false
    @State private var buyerPaysShipping: Bool?
    @State private var priceDropPercentage = ""
    @State private var onSaleOnly = false

    var body: some View {
        NavigationView {
            Form {
                Section("Payment Methods") {
                    Toggle("Accepts PayPal", isOn: $acceptsPayPal)
                    Toggle("Accepts Credit Cards", isOn: $acceptsCreditCards)
                }

                Section("Shipping Payment") {
                    Picker("Shipping Payment", selection: Binding<Bool?>(
                        get: { buyerPaysShipping },
                        set: { buyerPaysShipping = $0 }
                    )) {
                        Text("Any").tag(Bool?.none)
                        Text("Buyer Pays").tag(Bool?.some(true))
                        Text("Seller Pays").tag(Bool?.some(false))
                    }
                }

                Section("Price Conditions") {
                    TextField("Price Drop % (minimum)", text: $priceDropPercentage)
                        .keyboardType(.decimalPad)

                    Toggle("On Sale Only", isOn: $onSaleOnly)
                }
            }
            .navigationTitle("Payment Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let filter = filter else { return }
        acceptsPayPal = filter.acceptsPayPal
        acceptsCreditCards = filter.acceptsCreditCards
        buyerPaysShipping = filter.buyerPaysShipping
        priceDropPercentage = filter.priceDropPercentage != nil ? String(filter.priceDropPercentage!) : ""
        onSaleOnly = filter.onSaleOnly
    }

    private func saveFilter() {
        let hasContent = acceptsPayPal || acceptsCreditCards || buyerPaysShipping != nil ||
                        !priceDropPercentage.isEmpty || onSaleOnly

        if hasContent {
            filter = SearchFilter.PaymentFilter(
                acceptsPayPal: acceptsPayPal,
                acceptsCreditCards: acceptsCreditCards,
                buyerPaysShipping: buyerPaysShipping,
                priceDropPercentage: Double(priceDropPercentage),
                onSaleOnly: onSaleOnly
            )
        } else {
            filter = nil
        }
        dismiss()
    }
}

// MARK: - Photo Filter View

struct PhotoFilterView: View {
    @Binding var filter: SearchFilter.PhotoFilter?
    @Environment(\.dismiss) private var dismiss

    @State private var picturesOnly = false
    @State private var galleryViewAvailable = false
    @State private var moreThanTwelvePhotos = false

    var body: some View {
        NavigationView {
            Form {
                Section("Photo Requirements") {
                    Toggle("Pictures Only", isOn: $picturesOnly)
                    Toggle("Gallery View Available", isOn: $galleryViewAvailable)
                    Toggle("More Than 12 Photos", isOn: $moreThanTwelvePhotos)
                }
            }
            .navigationTitle("Photo Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let filter = filter else { return }
        picturesOnly = filter.picturesOnly
        galleryViewAvailable = filter.galleryViewAvailable
        moreThanTwelvePhotos = filter.moreThanTwelvePhotos
    }

    private func saveFilter() {
        let hasContent = picturesOnly || galleryViewAvailable || moreThanTwelvePhotos

        if hasContent {
            filter = SearchFilter.PhotoFilter(
                picturesOnly: picturesOnly,
                galleryViewAvailable: galleryViewAvailable,
                moreThanTwelvePhotos: moreThanTwelvePhotos
            )
        } else {
            filter = nil
        }
        dismiss()
    }
}

// MARK: - Keyword Filter View

struct KeywordFilterView: View {
    @Binding var filter: SearchFilter.KeywordFilter?
    @Environment(\.dismiss) private var dismiss

    @State private var searchTitle = true
    @State private var searchDescription = false
    @State private var exactPhraseOnly = false
    @State private var anyOfTheseWords = ""
    @State private var excludeTheseWords = ""
    @State private var atLeastOneOfTheseWords = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Search Scope") {
                    Toggle("Search Title", isOn: $searchTitle)
                    Toggle("Search Description", isOn: $searchDescription)
                    Toggle("Exact Phrase Only", isOn: $exactPhraseOnly)
                }

                Section("Keyword Logic") {
                    TextField("Any of these words", text: $anyOfTheseWords)
                        .autocapitalization(.none)

                    TextField("Exclude these words", text: $excludeTheseWords)
                        .autocapitalization(.none)

                    TextField("At least one of these", text: $atLeastOneOfTheseWords)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Keyword Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                }
            }
            .onAppear { loadData() }
        }
    }

    private func loadData() {
        guard let filter = filter else { return }
        searchTitle = filter.searchTitle
        searchDescription = filter.searchDescription
        exactPhraseOnly = filter.exactPhraseOnly
        anyOfTheseWords = filter.anyOfTheseWords ?? ""
        excludeTheseWords = filter.excludeTheseWords ?? ""
        atLeastOneOfTheseWords = filter.atLeastOneOfTheseWords ?? ""
    }

    private func saveFilter() {
        let hasContent = !searchTitle || searchDescription || exactPhraseOnly ||
                        !anyOfTheseWords.isEmpty || !excludeTheseWords.isEmpty || !atLeastOneOfTheseWords.isEmpty

        if hasContent {
            filter = SearchFilter.KeywordFilter(
                searchTitle: searchTitle,
                searchDescription: searchDescription,
                exactPhraseOnly: exactPhraseOnly,
                anyOfTheseWords: anyOfTheseWords.isEmpty ? nil : anyOfTheseWords,
                excludeTheseWords: excludeTheseWords.isEmpty ? nil : excludeTheseWords,
                atLeastOneOfTheseWords: atLeastOneOfTheseWords.isEmpty ? nil : atLeastOneOfTheseWords
            )
        } else {
            filter = nil
        }
        dismiss()
    }
}