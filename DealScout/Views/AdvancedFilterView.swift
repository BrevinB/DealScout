//
//  AdvancedFilterView.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import SwiftUI

// MARK: - Advanced Filter Editor

/// Comprehensive advanced filter editor providing access to all eBay filter options
struct AdvancedFilterView: View {

    // MARK: - Properties

    let filter: SearchFilter?
    @ObservedObject var viewModel: EbayDealFinderViewModel
    @Environment(\.dismiss) private var dismiss

    // Basic filter state
    @State private var name = ""
    @State private var keywords = ""
    @State private var selectedCategory: SearchFilter.EbayCategory?
    @State private var condition: SearchFilter.ItemCondition?
    @State private var minimumPrice = ""
    @State private var maximumPrice = ""
    @State private var listingType: SearchFilter.ListingType = .all
    @State private var sortOrder: SearchFilter.SortOrder = .bestMatch
    @State private var excludeKeywords = ""

    // Advanced filter states
    @State private var showingLocationFilters = false
    @State private var showingShippingFilters = false
    @State private var showingSellerFilters = false
    @State private var showingAuctionFilters = false
    @State private var showingListingFeatures = false
    @State private var showingItemSpecifics = false
    @State private var showingPaymentFilters = false
    @State private var showingPhotoFilters = false
    @State private var showingKeywordFilters = false

    // Filter configuration objects
    @State private var locationFilter: SearchFilter.LocationFilter?
    @State private var shippingFilter: SearchFilter.ShippingFilter?
    @State private var sellerFilter: SearchFilter.SellerFilter?
    @State private var auctionFilter: SearchFilter.AuctionFilter?
    @State private var listingFeatures: SearchFilter.ListingFeatures?
    @State private var itemSpecifics: SearchFilter.ItemSpecifics?
    @State private var paymentFilter: SearchFilter.PaymentFilter?
    @State private var photoFilter: SearchFilter.PhotoFilter?
    @State private var keywordFilter: SearchFilter.KeywordFilter?

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                basicFiltersSection
                advancedFiltersSection
            }
            .navigationTitle(filter == nil ? "New Advanced Search" : "Edit Advanced Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveFilter() }
                        .disabled(name.isEmpty)
                }
            }
            .onAppear { loadFilterData() }
        }
    }

    // MARK: - View Components

    private var basicFiltersSection: some View {
        Group {
            Section("Search Details") {
                TextField("Search Name", text: $name)
                TextField("Keywords", text: $keywords)
                    .autocapitalization(.none)
            }

            Section("Category & Condition") {
                Picker("Category", selection: $selectedCategory) {
                    Text("Any Category").tag(SearchFilter.EbayCategory?.none)
                    ForEach(SearchFilter.EbayCategory.categories) { category in
                        Text(category.name).tag(SearchFilter.EbayCategory?.some(category))
                    }
                }

                Picker("Condition", selection: $condition) {
                    Text("Any Condition").tag(SearchFilter.ItemCondition?.none)
                    ForEach(SearchFilter.ItemCondition.allCases, id: \.self) { condition in
                        Text(condition.displayName).tag(SearchFilter.ItemCondition?.some(condition))
                    }
                }
            }

            Section("Price & Listing") {
                HStack {
                    TextField("Min Price", text: $minimumPrice)
                        .keyboardType(.decimalPad)
                    Text("to")
                    TextField("Max Price", text: $maximumPrice)
                        .keyboardType(.decimalPad)
                }

                Picker("Listing Type", selection: $listingType) {
                    ForEach(SearchFilter.ListingType.allCases, id: \.self) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                Picker("Sort By", selection: $sortOrder) {
                    ForEach(SearchFilter.SortOrder.allCases, id: \.self) { order in
                        Text(order.displayName).tag(order)
                    }
                }

                TextField("Exclude Keywords", text: $excludeKeywords)
                    .autocapitalization(.none)
            }
        }
    }

    private var advancedFiltersSection: some View {
        Section("Advanced Filters") {
            FilterToggleRow(
                title: "Location & Distance",
                description: locationFilter?.displayText ?? "Any Location",
                isConfigured: locationFilter != nil
            ) {
                showingLocationFilters = true
            }

            FilterToggleRow(
                title: "Shipping Options",
                description: shippingFilter?.displayText ?? "Any Shipping",
                isConfigured: shippingFilter != nil
            ) {
                showingShippingFilters = true
            }

            FilterToggleRow(
                title: "Seller Requirements",
                description: sellerFilter?.displayText ?? "Any Seller",
                isConfigured: sellerFilter != nil
            ) {
                showingSellerFilters = true
            }

            FilterToggleRow(
                title: "Auction Specific",
                description: auctionFilter?.displayText ?? "Any Auction",
                isConfigured: auctionFilter != nil
            ) {
                showingAuctionFilters = true
            }

            FilterToggleRow(
                title: "Listing Features",
                description: listingFeatures?.displayText ?? "Any Features",
                isConfigured: listingFeatures != nil
            ) {
                showingListingFeatures = true
            }

            FilterToggleRow(
                title: "Item Specifics",
                description: itemSpecifics?.displayText ?? "Any Specifics",
                isConfigured: itemSpecifics != nil
            ) {
                showingItemSpecifics = true
            }

            FilterToggleRow(
                title: "Payment & Pricing",
                description: paymentFilter?.displayText ?? "Any Payment",
                isConfigured: paymentFilter != nil
            ) {
                showingPaymentFilters = true
            }

            FilterToggleRow(
                title: "Photos & Media",
                description: photoFilter?.displayText ?? "Any Photos",
                isConfigured: photoFilter != nil
            ) {
                showingPhotoFilters = true
            }

            FilterToggleRow(
                title: "Keyword Options",
                description: keywordFilter?.displayText ?? "Any Keywords",
                isConfigured: keywordFilter != nil
            ) {
                showingKeywordFilters = true
            }
        }
        .sheet(isPresented: $showingLocationFilters) {
            LocationFilterView(filter: $locationFilter)
        }
        .sheet(isPresented: $showingShippingFilters) {
            ShippingFilterView(filter: $shippingFilter)
        }
        .sheet(isPresented: $showingSellerFilters) {
            SellerFilterView(filter: $sellerFilter)
        }
        .sheet(isPresented: $showingAuctionFilters) {
            AuctionFilterView(filter: $auctionFilter)
        }
        .sheet(isPresented: $showingListingFeatures) {
            ListingFeaturesView(filter: $listingFeatures)
        }
        .sheet(isPresented: $showingItemSpecifics) {
            ItemSpecificsView(filter: $itemSpecifics)
        }
        .sheet(isPresented: $showingPaymentFilters) {
            PaymentFilterView(filter: $paymentFilter)
        }
        .sheet(isPresented: $showingPhotoFilters) {
            PhotoFilterView(filter: $photoFilter)
        }
        .sheet(isPresented: $showingKeywordFilters) {
            KeywordFilterView(filter: $keywordFilter)
        }
    }

    // MARK: - Private Methods

    private func loadFilterData() {
        guard let filter = filter else {
            // Initialize with default values for new filter
            return
        }

        name = filter.name
        keywords = ""
        selectedCategory = SearchFilter.EbayCategory.categories.first { $0.id == filter.categoryID }
        condition = filter.condition
        minimumPrice = filter.minimumPrice != nil ? String(filter.minimumPrice!) : ""
        maximumPrice = filter.maximumPrice != nil ? String(filter.maximumPrice!) : ""
        listingType = filter.listingType ?? .all
        sortOrder = filter.sortOrder
        excludeKeywords = filter.excludeKeywords ?? ""

        // Load advanced filters
        locationFilter = filter.location
        shippingFilter = filter.shippingOptions
        sellerFilter = filter.sellerFilters
        auctionFilter = filter.auctionFilters
        listingFeatures = filter.listingFeatures
        itemSpecifics = filter.itemSpecifics
        paymentFilter = filter.paymentFilters
        photoFilter = filter.photoFilters
        keywordFilter = filter.keywordFilters
    }

    private func saveFilter() {
        let newFilter = SearchFilter(
            name: name.isEmpty ? "New Advanced Search" : name,
            categoryID: selectedCategory?.id,
            minimumPrice: Double(minimumPrice),
            maximumPrice: Double(maximumPrice),
            condition: condition,
            listingType: listingType,
            location: locationFilter,
            shippingOptions: shippingFilter,
            sellerFilters: sellerFilter,
            sortOrder: sortOrder,
            excludeKeywords: excludeKeywords.isEmpty ? nil : excludeKeywords,
            auctionFilters: auctionFilter,
            listingFeatures: listingFeatures,
            itemSpecifics: itemSpecifics,
            paymentFilters: paymentFilter,
            photoFilters: photoFilter,
            keywordFilters: keywordFilter
        )

        if let existingFilter = filter {
            var updatedFilter = existingFilter
            updatedFilter.name = newFilter.name
            updatedFilter.categoryID = newFilter.categoryID
            updatedFilter.minimumPrice = newFilter.minimumPrice
            updatedFilter.maximumPrice = newFilter.maximumPrice
            updatedFilter.condition = newFilter.condition
            updatedFilter.listingType = newFilter.listingType
            updatedFilter.location = newFilter.location
            updatedFilter.shippingOptions = newFilter.shippingOptions
            updatedFilter.sellerFilters = newFilter.sellerFilters
            updatedFilter.sortOrder = newFilter.sortOrder
            updatedFilter.excludeKeywords = newFilter.excludeKeywords
            updatedFilter.auctionFilters = newFilter.auctionFilters
            updatedFilter.listingFeatures = newFilter.listingFeatures
            updatedFilter.itemSpecifics = newFilter.itemSpecifics
            updatedFilter.paymentFilters = newFilter.paymentFilters
            updatedFilter.photoFilters = newFilter.photoFilters
            updatedFilter.keywordFilters = newFilter.keywordFilters

            viewModel.updateFilter(updatedFilter)
        } else {
            viewModel.addFilter(newFilter)
        }

        dismiss()
    }
}

// MARK: - Filter Toggle Row

/// Reusable row component for advanced filter sections
struct FilterToggleRow: View {
    let title: String
    let description: String
    let isConfigured: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .foregroundColor(.primary)
                            .fontWeight(.medium)

                        if isConfigured {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        }
                    }

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(.plain)
    }
}