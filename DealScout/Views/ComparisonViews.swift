//
//  ComparisonViews.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import SwiftUI

// MARK: - Comparison Views

/// Main comparison view for side-by-side listing analysis
struct ComparisonView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: EbayDealFinderViewModel

    // MARK: - Body

    var body: some View {
        NavigationView {
            Group {
                if let comparison = viewModel.activeComparison, !comparison.listings.isEmpty {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Comparison Grid
                            ComparisonGrid(
                                listings: comparison.listings,
                                viewModel: viewModel
                            )

                            // Comparison Metrics
                            ComparisonMetricsView(listings: comparison.listings)

                            // Similar Items
                            if let firstListing = comparison.listings.first {
                                SimilarItemsView(
                                    targetListing: firstListing,
                                    allListings: viewModel.allListings,
                                    viewModel: viewModel
                                )
                            }
                        }
                        .padding()
                    }
                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "scale.3d")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("No Items to Compare")
                            .font(.title2)
                            .fontWeight(.medium)

                        Text("Add items to comparison from the deals view")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        if !viewModel.savedComparisons.isEmpty {
                            Button("View Saved Comparisons") {
                                // Show saved comparisons
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Compare Items")
            .toolbar {
                if let comparison = viewModel.activeComparison, !comparison.listings.isEmpty {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button("Save") {
                            viewModel.saveComparison()
                        }

                        Button("Clear") {
                            viewModel.clearComparison()
                        }
                    }
                }
            }
        }
    }
}

/// Grid layout for comparing multiple listings
struct ComparisonGrid: View {

    // MARK: - Properties

    let listings: [EbayListing]
    @ObservedObject var viewModel: EbayDealFinderViewModel

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(listings) { listing in
                    ComparisonCard(listing: listing, viewModel: viewModel)
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Individual card for comparison grid
struct ComparisonCard: View {

    // MARK: - Properties

    let listing: EbayListing
    @ObservedObject var viewModel: EbayDealFinderViewModel
    @State private var showingPriceHistory = false

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Remove button
            HStack {
                Spacer()
                Button {
                    viewModel.removeFromComparison(listing)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }

            // Image
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
            .frame(height: 120)
            .cornerRadius(8)

            // Title
            Text(listing.title)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            // Price
            VStack(alignment: .leading, spacing: 4) {
                Text("$\(listing.price, specifier: "%.2f")")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                if let shippingCost = listing.shippingCost, shippingCost > 0 {
                    Text("+ $\(shippingCost, specifier: "%.2f") shipping")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Free shipping")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Deal Score
            if let dealScore = listing.dealScore {
                HStack(spacing: 4) {
                    Image(systemName: dealScore.systemImageName)
                        .foregroundColor(dealScore.color)
                    Text(dealScore.displayName)
                        .font(.caption)
                        .foregroundColor(dealScore.color)
                        .fontWeight(.medium)
                }
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                DetailRow(label: "Condition", value: listing.condition)
                DetailRow(label: "Seller", value: listing.seller.username)
                DetailRow(label: "Feedback", value: "\(listing.seller.feedbackScore)")
                DetailRow(label: "Type", value: listing.isAuction ? "Auction" : "Buy It Now")
            }

            // Actions
            HStack(spacing: 8) {
                Button("Price History") {
                    showingPriceHistory = true
                }
                .font(.caption)
                .buttonStyle(.bordered)

                Button("View") {
                    if let url = URL(string: listing.listingURL) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
            }

            Spacer()
        }
        .frame(width: 200)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        .sheet(isPresented: $showingPriceHistory) {
            ListingPriceHistoryView(listing: listing, viewModel: viewModel)
        }
    }
}

/// Detail row for comparison cards
struct DetailRow: View {

    // MARK: - Properties

    let label: String
    let value: String

    // MARK: - Body

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

/// Metrics comparison view
struct ComparisonMetricsView: View {

    // MARK: - Properties

    let listings: [EbayListing]

    // MARK: - Computed Properties

    private var metrics: [ComparisonMetric] {
        [
            ComparisonMetric.priceMetric(listings: listings),
            ComparisonMetric.conditionMetric(listings: listings),
            ComparisonMetric.shippingMetric(listings: listings),
            ComparisonMetric.sellerMetric(listings: listings),
            ComparisonMetric.endTimeMetric(listings: listings)
        ]
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Comparison Metrics")
                .font(.title2)
                .fontWeight(.bold)

            ForEach(metrics.indices, id: \.self) { index in
                MetricComparisonRow(metric: metrics[index], listingCount: listings.count)
            }
        }
        .padding(.vertical)
    }
}

/// Individual metric comparison row
struct MetricComparisonRow: View {

    // MARK: - Properties

    let metric: ComparisonMetric
    let listingCount: Int

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.iconName)
                    .foregroundColor(.blue)
                Text(metric.name)
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 12) {
                ForEach(0..<listingCount, id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text("Item \(index + 1)")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(metric.values[index])
                            .font(.subheadline)
                            .fontWeight(metric.bestIndex == index ? .bold : .regular)
                            .foregroundColor(metric.bestIndex == index ? .green : .primary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if index < listingCount - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Similar items recommendations view
struct SimilarItemsView: View {

    // MARK: - Properties

    let targetListing: EbayListing
    let allListings: [EbayListing]
    @ObservedObject var viewModel: EbayDealFinderViewModel

    // MARK: - Computed Properties

    private var similarItems: [SimilarItem] {
        viewModel.findSimilarItems(to: targetListing, from: allListings)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Similar Items")
                .font(.title2)
                .fontWeight(.bold)

            if similarItems.isEmpty {
                Text("No similar items found")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(similarItems) { item in
                            SimilarItemCard(item: item, viewModel: viewModel)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.vertical)
    }
}

/// Card for similar item recommendations
struct SimilarItemCard: View {

    // MARK: - Properties

    let item: SimilarItem
    @ObservedObject var viewModel: EbayDealFinderViewModel

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AsyncImage(url: URL(string: item.listing.imageURL ?? "")) { image in
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
            .frame(height: 80)
            .cornerRadius(6)

            Text(item.listing.title)
                .font(.caption)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text("$\(item.listing.price, specifier: "%.2f")")
                .font(.caption)
                .fontWeight(.bold)

            Text("\(item.similarityScore * 100, specifier: "%.0f")% similar")
                .font(.caption2)
                .foregroundColor(.blue)

            HStack(spacing: 4) {
                ForEach(Array(item.similarityReasons.prefix(2)), id: \.self) { reason in
                    Image(systemName: reason.iconName)
                        .font(.caption2)
                        .foregroundColor(reason.color)
                }
            }

            Button("Compare") {
                viewModel.addToComparison(item.listing)
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .frame(width: 140)
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Price history view for individual listings
struct ListingPriceHistoryView: View {

    // MARK: - Properties

    let listing: EbayListing
    @ObservedObject var viewModel: EbayDealFinderViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Computed Properties

    private var priceHistory: ItemPriceHistory? {
        viewModel.getPriceHistory(for: listing.itemID)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(listing.title)
                            .font(.headline)
                            .lineLimit(2)

                        Text("Current Price: $\(listing.price, specifier: "%.2f")")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()

                    if let history = priceHistory, !history.pricePoints.isEmpty {
                        // Price Statistics
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            PriceStatCard(
                                title: "Average",
                                value: "$\(history.averagePrice, default: "%.2f")",
                                color: .blue
                            )

                            PriceStatCard(
                                title: "Lowest",
                                value: "$\(history.lowestPrice ?? 0, default: "%.2f")",
                                color: .green
                            )

                            PriceStatCard(
                                title: "Highest",
                                value: "$\(history.highestPrice ?? 0, default: "%.2f")",
                                color: .red
                            )

                            PriceStatCard(
                                title: "Trend",
                                value: history.priceDirection.rawValue.capitalized,
                                color: history.priceDirection.color
                            )
                        }
                        .padding(.horizontal)

                        // Price Chart
                        VStack(alignment: .leading) {
                            Text("Price History")
                                .font(.headline)
                                .padding(.horizontal)

                            PriceChartView(pricePoints: history.pricePoints)
                                .frame(height: 200)
                                .padding()
                        }

                        // Price Timeline
                        VStack(alignment: .leading) {
                            Text("Price Timeline")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(history.pricePoints.prefix(10)) { point in
                                PriceTimelineRow(pricePoint: point)
                            }
                        }
                    } else {
                        Text("No price history available")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle("Price History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Price statistic card
struct PriceStatCard: View {

    // MARK: - Properties

    let title: String
    let value: String
    let color: Color

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Simple price chart view
struct PriceChartView: View {

    // MARK: - Properties

    let pricePoints: [PriceHistoryPoint]

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            if pricePoints.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Path { path in
                    let points = pricePoints.sorted { $0.timestamp < $1.timestamp }
                    let maxPrice = points.map { $0.price }.max() ?? 1
                    let minPrice = points.map { $0.price }.min() ?? 0
                    let priceRange = maxPrice - minPrice
                    let width = geometry.size.width
                    let height = geometry.size.height

                    for (index, point) in points.enumerated() {
                        let x = CGFloat(index) / CGFloat(points.count - 1) * width
                        let y = height - (CGFloat(point.price - minPrice) / CGFloat(priceRange) * height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
                .background(
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            }
        }
    }
}

/// Price timeline row
struct PriceTimelineRow: View {

    // MARK: - Properties

    let pricePoint: PriceHistoryPoint

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("$\(pricePoint.price, specifier: "%.2f")")
                    .font(.headline)
                    .fontWeight(.bold)

                Text(pricePoint.source.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text(pricePoint.formattedDate)
                    .font(.subheadline)

                if let condition = pricePoint.condition {
                    Text(condition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}
