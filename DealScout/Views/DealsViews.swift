//
//  DealsViews.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import SwiftUI

// MARK: - Deals and Listings Views

/// Main view for displaying deals organized by search filters
struct DealsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: EbayDealFinderViewModel
    @State private var expandedSections: Set<UUID> = []
    @State private var showingSettings = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            Group {
                if !viewModel.hasValidAPICredentials {
                    VStack(spacing: 20) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text("API Setup Required")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Configure your eBay API credentials in Settings to start finding deals")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Open Settings") {
                            showingSettings = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else if viewModel.searchResults.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "tag.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)

                        Text("No search results yet")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Run searches from your saved filters to find great deals")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if !viewModel.filters.isEmpty {
                            Button("Check All Searches") {
                                Task {
                                    await viewModel.checkAllActiveFilters()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                } else {
                    List {
                        // Summary section
                        if !viewModel.excellentDeals.isEmpty {
                            Section {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading) {
                                        Text("🎯 \(viewModel.excellentDeals.count) Excellent Deals Found!")
                                            .font(.headline)
                                            .foregroundColor(.green)
                                        Text("Great savings across your searches")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        // Results by search filter
                        ForEach(viewModel.activeSearchResults, id: \.filter.id) { item in
                            SearchResultSection(
                                filter: item.filter,
                                result: item.result,
                                isExpanded: expandedSections.contains(item.filter.id),
                                isLoading: viewModel.loadingFilters.contains(item.filter.id),
                                onToggle: {
                                    toggleSection(item.filter.id)
                                },
                                onRefresh: {
                                    Task {
                                        await viewModel.searchListings(for: item.filter)
                                    }
                                },
                                viewModel: viewModel
                            )
                        }

                        // Loading sections for active searches
                        ForEach(Array(viewModel.loadingFilters), id: \.self) { filterId in
                            if let filter = viewModel.filters.first(where: { $0.id == filterId }),
                               !viewModel.searchResults.keys.contains(filterId) {
                                SearchResultSection(
                                    filter: filter,
                                    result: nil,
                                    isExpanded: false,
                                    isLoading: true,
                                    onToggle: {
                                        // No action for loading sections
                                    },
                                    onRefresh: {
                                        // No refresh action during loading
                                    },
                                    viewModel: viewModel
                                )
                            }
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.top, 0)
                }
            }
            .navigationTitle("Deals by Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if let comparison = viewModel.activeComparison, !comparison.listings.isEmpty {
                        Button {
                            // Navigate to comparison view
                        } label: {
                            HStack {
                                Image(systemName: "scale.3d")
                                Text("\(comparison.listings.count)")
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }

                if !viewModel.filters.isEmpty && viewModel.hasValidAPICredentials {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button("Refresh All") {
                                Task {
                                    await viewModel.checkAllActiveFilters()
                                }
                            }

                            Button(expandedSections.isEmpty ? "Expand All" : "Collapse All") {
                                if expandedSections.isEmpty {
                                    expandedSections = Set(viewModel.activeSearchResults.map { $0.filter.id })
                                } else {
                                    expandedSections.removeAll()
                                }
                            }

                            if viewModel.activeComparison != nil {
                                Divider()
                                Button("Clear Comparison") {
                                    viewModel.clearComparison()
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showingErrorAlert) {
                Button("OK") {
                    viewModel.showingErrorAlert = false
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
        }
        .onAppear {
            // Auto-expand sections with excellent deals
            for item in viewModel.activeSearchResults {
                let excellentCount = item.result.listings.filter { $0.dealScore == .excellent }.count
                if excellentCount > 0 {
                    expandedSections.insert(item.filter.id)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func toggleSection(_ id: UUID) {
        if expandedSections.contains(id) {
            expandedSections.remove(id)
        } else {
            expandedSections.insert(id)
        }
    }
}

/// Section showing search results for a specific filter
struct SearchResultSection: View {

    // MARK: - Properties

    let filter: SearchFilter
    let result: EbayDealFinderViewModel.SearchResult?
    let isExpanded: Bool
    let isLoading: Bool
    let onToggle: () -> Void
    let onRefresh: () -> Void
    @ObservedObject var viewModel: EbayDealFinderViewModel
    @State private var showingSoldComparison = false

    // MARK: - Body

    var body: some View {
        Section {
            if isExpanded && !isLoading {
                if let result = result, !result.listings.isEmpty {
                    VStack(spacing: 16) {
                        // Action buttons row
                        HStack(spacing: 12) {
                            Button(action: {
                                showingSoldComparison = true
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.subheadline)
                                    Text("Market Analysis")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.blue)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                // Add all items to comparison
                                for listing in result.listings.prefix(5) {
                                    if viewModel.activeComparison == nil {
                                        viewModel.startComparison(with: listing)
                                    } else {
                                        viewModel.addToComparison(listing)
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "scale.3d")
                                        .font(.subheadline)
                                    Text("Compare Top \(min(5, result.listings.count))")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.purple)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                            .disabled(result.listings.count < 2)

                            Spacer()
                        }
                        .sheet(isPresented: $showingSoldComparison) {
                            SoldVsActiveComparisonView(
                                filter: filter,
                                activeListings: result.listings,
                                viewModel: viewModel
                            )
                        }

                        // Quick insights
                        if let insights = generateQuickInsights(for: result.listings) {
                            InsightBanner(insights: insights)
                        }

                        ForEach(result.listings) { listing in
                            ListingRow(listing: listing, viewModel: viewModel)
                        }
                    }
                } else {
                    Text("No listings found")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                        .padding(.vertical, 8)
                }
            }
        } header: {
            SearchSectionHeader(
                filter: filter,
                result: result,
                isExpanded: isExpanded,
                isLoading: isLoading,
                onToggle: onToggle,
                onRefresh: onRefresh
            )
        }
    }
}

/// Header for search result sections with stats and controls
struct SearchSectionHeader: View {

    // MARK: - Properties

    let filter: SearchFilter
    let result: EbayDealFinderViewModel.SearchResult?
    let isExpanded: Bool
    let isLoading: Bool
    let onToggle: () -> Void
    let onRefresh: () -> Void

    // MARK: - Computed Properties

    private var dealCounts: (total: Int, excellent: Int, good: Int) {
        guard let result = result else { return (0, 0, 0) }
        let total = result.listings.count
        let excellent = result.listings.filter { $0.dealScore == .excellent }.count
        let good = result.listings.filter { $0.dealScore == .good }.count
        return (total, excellent, good)
    }

    // MARK: - Body

    var body: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(filter.name)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }

                    if let result = result {
                        HStack(spacing: 12) {
                            Text("\(dealCounts.total) items")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            if dealCounts.excellent > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                    Text("\(dealCounts.excellent)")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.medium)
                                }
                            }

                            if dealCounts.good > 0 {
                                HStack(spacing: 2) {
                                    Image(systemName: "star.leadinghalf.filled")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                    Text("\(dealCounts.good)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                            }

                            Spacer()

                            Text("Updated \(result.lastUpdated, style: .relative) ago")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .disabled(isLoading)

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// Individual listing row with deal analysis and actions
struct ListingRow: View {

    // MARK: - Properties

    let listing: EbayListing
    @ObservedObject var viewModel: EbayDealFinderViewModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                AsyncImage(url: URL(string: listing.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                .frame(width: 80, height: 80)
                .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(listing.title)
                        .font(.headline)
                        .lineLimit(2)

                    HStack {
                        if listing.isSoldListing {
                            Text("SOLD $\(listing.price, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        } else {
                            Text("$\(listing.price, specifier: "%.2f")")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                        }

                        if listing.isSoldListing {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else if let shippingCost = listing.shippingCost, shippingCost > 0 {
                            Text("+ $\(shippingCost, specifier: "%.2f") shipping")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Free shipping")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    HStack(spacing: 6) {
                        Text(listing.condition)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)

                        if listing.isSoldListing {
                            Text("SOLD")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.2))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }

                        // Deal quality indicator
                        if let dealScore = listing.dealScore, !listing.isSoldListing {
                            HStack(spacing: 2) {
                                Image(systemName: dealScore.systemImageName)
                                    .font(.caption2)
                                Text(dealScore.displayName)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(dealScore.color)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(dealScore.color.opacity(0.1))
                            .cornerRadius(4)
                        }
                    }
                }

                Spacer()

                // Safari button - completely isolated from other gesture areas
                Button {
                    if let url = URL(string: listing.listingURL) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "safari")
                            .foregroundColor(.white)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(Color.blue)
                            .cornerRadius(10)

                        Text("View")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                .buttonStyle(.plain)
                .frame(width: 50)
                .contentShape(Rectangle())
            }

            // Deal Analysis
            if listing.isSoldListing {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Sold Item")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Historical sale")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Sold on \(listing.endTime, formatter: DateFormatter.soldItemFormatter)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                .padding(.top, 4)
            } else if let dealScore = listing.dealScore,
                      let avgPrice = listing.averageMarketPrice,
                      let savings = listing.savingsAmount,
                      let savingsPercentage = listing.savingsPercentage {

                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: dealScore.systemImageName)
                            .foregroundColor(dealScore.color)
                        Text(dealScore.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(dealScore.color)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Market avg: $\(avgPrice, specifier: "%.0f")")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if savings > 0 {
                            Text("Save $\(savings, specifier: "%.0f") (\(savingsPercentage, specifier: "%.0f")%)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.top, 4)
            }

            // Seller info and actions
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(listing.seller.username)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(listing.seller.feedbackScore) feedback")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(listing.seller.feedbackPercentage, specifier: "%.1f")%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        if listing.isAuction {
                            Text("Auction")
                                .font(.caption)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.red.opacity(0.1))
                                .foregroundColor(.red)
                                .cornerRadius(3)
                        } else {
                            Text("Buy It Now")
                                .font(.caption)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(3)
                        }
                    }
                }

                Spacer()
            }

            // Action buttons at the bottom - full width for all text
            if !listing.isSoldListing {
                HStack(spacing: 12) {
                    Button(action: {
                        // Add to watchlist functionality
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "eye")
                                .font(.subheadline)
                            Text("Watch")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        // Add to comparison or start new comparison
                        if viewModel.activeComparison != nil {
                            viewModel.addToComparison(listing)
                        } else {
                            viewModel.startComparison(with: listing)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "scale.3d")
                                .font(.subheadline)
                            Text("Compare")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.activeComparison?.listings.contains(where: { $0.itemID == listing.itemID }) ?? false)

                    Button(action: {
                        // Show similar items
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                                .font(.subheadline)
                            Text("Similar")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.purple.opacity(0.15))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .allowsHitTesting(true)
    }
}

// MARK: - Extensions

// MARK: - Supporting Views and Functions

struct InsightBanner: View {
    let insights: QuickInsights

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.subheadline)
                Text("Quick Insights")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                if let bestDeal = insights.bestDeal {
                    InsightItem(
                        icon: "star.fill",
                        text: "Best deal: \(String(format: "%.1f", bestDeal.savingsPercentage ?? 0))% off market price",
                        color: .green
                    )
                }

                if insights.averageSavings > 0 {
                    InsightItem(
                        icon: "chart.line.downtrend.xyaxis",
                        text: "Average savings: \(String(format: "%.1f", insights.averageSavings))%",
                        color: .blue
                    )
                }

                if let popularCondition = insights.mostPopularCondition {
                    InsightItem(
                        icon: "checkmark.circle",
                        text: "Most common: \(popularCondition)",
                        color: .purple
                    )
                }
            }
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct InsightItem: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.caption)
                .frame(width: 12)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

struct QuickInsights {
    let bestDeal: EbayListing?
    let averageSavings: Double
    let mostPopularCondition: String?
    let priceRange: (min: Double, max: Double)
}

extension SearchResultSection {
    func generateQuickInsights(for listings: [EbayListing]) -> QuickInsights? {
        guard !listings.isEmpty else { return nil }

        // Find best deal (highest savings percentage)
        let bestDeal = listings
            .compactMap { listing -> (EbayListing, Double)? in
                guard let savings = listing.savingsPercentage else { return nil }
                return (listing, savings)
            }
            .max { $0.1 < $1.1 }?.0

        // Calculate average savings
        let savingsPercentages = listings.compactMap(\.savingsPercentage)
        let averageSavings = savingsPercentages.isEmpty ? 0 : savingsPercentages.reduce(0, +) / Double(savingsPercentages.count)

        // Find most popular condition
        let conditionCounts = Dictionary(grouping: listings, by: \.condition)
            .mapValues { $0.count }
        let mostPopularCondition = conditionCounts.max { $0.value < $1.value }?.key

        // Price range
        let prices = listings.map(\.price)
        let priceRange = (min: prices.min() ?? 0, max: prices.max() ?? 0)

        return QuickInsights(
            bestDeal: bestDeal,
            averageSavings: averageSavings,
            mostPopularCondition: mostPopularCondition,
            priceRange: priceRange
        )
    }
}

// MARK: - Enhanced Listing Row

extension ListingRow {
    private var dealQualityIndicator: some View {
        Group {
            if let dealScore = listing.dealScore {
                HStack(spacing: 4) {
                    Image(systemName: dealScore.systemImageName)
                        .foregroundColor(dealScore.color)
                        .font(.caption)

                    Text(dealScore.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(dealScore.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(dealScore.color.opacity(0.1))
                .cornerRadius(6)
            }
        }
    }

    private var quickActionButtons: some View {
        HStack(spacing: 12) {
            // Add to watchlist
            Button {
                // Add to watchlist functionality
            } label: {
                Image(systemName: "eye")
                    .foregroundColor(.orange)
            }
            .buttonStyle(.plain)

            // Add to comparison
            Button {
                if viewModel.activeComparison != nil {
                    viewModel.addToComparison(listing)
                } else {
                    viewModel.startComparison(with: listing)
                }
            } label: {
                Image(systemName: "scale.3d")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.activeComparison?.listings.contains(where: { $0.itemID == listing.itemID }) ?? false)

            // Share listing
            Button {
                // Share functionality
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.gray)
            }
            .buttonStyle(.plain)
        }
    }
}

extension DateFormatter {
    static let soldItemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
