//
//  AnalysisViews.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import SwiftUI

// MARK: - Analysis Views

/// Main market insights view showing trends and analysis
struct MarketInsightsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: EbayDealFinderViewModel

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let selectedFilter = viewModel.selectedFilter,
                       let analysis = viewModel.marketAnalysis {

                        // Market Overview
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Market Analysis: \(selectedFilter.name)")
                                .font(.title2)
                                .fontWeight(.bold)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                MarketStatCard(
                                    title: "Average Price",
                                    value: "$\(analysis.averagePrice, default: "%.0f")",
                                    subtitle: "Market average",
                                    color: .blue
                                )

                                MarketStatCard(
                                    title: "Price Trend",
                                    value: analysis.priceDirection.rawValue.capitalized,
                                    subtitle: "Last 30 days",
                                    color: analysis.priceDirection.color
                                )

                                MarketStatCard(
                                    title: "Lowest Price",
                                    value: "$\(analysis.lowestPrice, default: "%.0f")",
                                    subtitle: "Best deal found",
                                    color: .green
                                )

                                MarketStatCard(
                                    title: "Items Sold",
                                    value: "\(analysis.totalSold)",
                                    subtitle: "Recent activity",
                                    color: .orange
                                )
                            }
                        }
                        .padding()

                        // Price Range Chart
                        VStack(alignment: .leading) {
                            Text("Price Distribution")
                                .font(.headline)
                                .padding(.horizontal)

                            PriceRangeChart(analysis: analysis)
                                .frame(height: 200)
                                .padding()
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Sold Items Analysis
                        if let soldAnalysis = analysis.soldItemsAnalysis {
                            SoldItemsAnalysisSection(analysis: soldAnalysis)
                                .padding(.horizontal)
                        }

                    } else {
                        // Empty state
                        VStack(spacing: 20) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)

                            Text("No Market Data")
                                .font(.title2)
                                .fontWeight(.medium)

                            Text("Run a search to see market analysis")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Market Insights")
        }
    }
}

/// Card showing market statistics
struct MarketStatCard: View {

    // MARK: - Properties

    let title: String
    let value: String
    let subtitle: String
    let color: Color

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Chart showing price range distribution
struct PriceRangeChart: View {

    // MARK: - Properties

    let analysis: MarketAnalysis

    // MARK: - Body

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(0..<5, id: \.self) { index in
                VStack {
                    Rectangle()
                        .fill(Color.blue.opacity(0.7))
                        .frame(height: CGFloat.random(in: 40...150))

                    Text("$\(Int(analysis.lowestPrice + Double(index) * (analysis.highestPrice - analysis.lowestPrice) / 4), specifier: "%.0f")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}

/// Section showing sold items analysis
struct SoldItemsAnalysisSection: View {

    // MARK: - Properties

    let analysis: SoldItemsAnalysis

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sold Items Analysis")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MarketStatCard(
                    title: "Avg Days to Sell",
                    value: "\(analysis.averageDaysToSell)",
                    subtitle: "Market velocity",
                    color: .purple
                )

                MarketStatCard(
                    title: "Sell Through Rate",
                    value: "\(analysis.sellThroughRate, default: "%.0f")%",
                    subtitle: "Success rate",
                    color: .green
                )

                MarketStatCard(
                    title: "Auction vs Fixed",
                    value: "\(analysis.auctionVsFixedRatio, default: "%.0f")%",
                    subtitle: "Auction preference",
                    color: .orange
                )

                MarketStatCard(
                    title: "Items Analyzed",
                    value: "\(analysis.soldListings.count)",
                    subtitle: "Sample size",
                    color: .blue
                )
            }
        }
    }
}

/// Summary card component
struct SummaryCard: View {

    // MARK: - Properties

    let title: String
    let value: String
    let subtitle: String
    let color: Color

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(value)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

/// Price comparison section
struct PriceComparisonSection: View {

    // MARK: - Properties

    let activeListings: [EbayListing]
    let priceComparison: PriceComparison

    // MARK: - Computed Properties

    private var currentAverage: Double {
        guard !activeListings.isEmpty else { return 0 }
        return activeListings.map { $0.price }.reduce(0, +) / Double(activeListings.count)
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Analysis")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Active Average")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("$\(currentAverage, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }

                    Spacer()

                    VStack(alignment: .trailing) {
                        Text("Sold Average")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("$\(priceComparison.soldAverage, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }

                Divider()

                HStack {
                    Text(priceComparison.indicator.text)
                        .font(.subheadline)
                        .foregroundColor(priceComparison.indicator.color)

                    Spacer()

                    Text(priceComparison.formattedPercentage)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(priceComparison.indicator.color)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

/// Market insights section
struct MarketInsightsSection: View {

    // MARK: - Properties

    let analysis: SoldItemsAnalysis

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Insights")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 12) {
                MarketInsightRow(
                    icon: "clock",
                    title: "Average Time to Sell",
                    value: "\(analysis.averageDaysToSell) days",
                    color: .blue
                )

                MarketInsightRow(
                    icon: "percent",
                    title: "Sell Through Rate",
                    value: "\(analysis.sellThroughRate, default: "%.1f")%",
                    color: .green
                )

                MarketInsightRow(
                    icon: "hammer",
                    title: "Auction Preference",
                    value: "\(analysis.auctionVsFixedRatio, default: "%.1f")%",
                    color: .orange
                )
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

/// Individual insight row
struct MarketInsightRow: View {

    // MARK: - Properties

    let icon: String
    let title: String
    let value: String
    let color: Color

    // MARK: - Body

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(title)
                .font(.subheadline)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
        .padding(.vertical, 8)
    }
}

/// Condition breakdown section
struct ConditionBreakdownSection: View {

    // MARK: - Properties

    let analysis: SoldItemsAnalysis

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Condition Breakdown")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(Array(analysis.conditionBreakdown.keys), id: \.self) { condition in
                    if let count = analysis.conditionBreakdown[condition] {
                        ConditionRow(
                            condition: condition,
                            count: count,
                            total: analysis.soldListings.count
                        )
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

/// Individual condition row
struct ConditionRow: View {

    // MARK: - Properties

    let condition: SearchFilter.ItemCondition
    let count: Int
    let total: Int

    // MARK: - Computed Properties

    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total) * 100
    }

    // MARK: - Body

    var body: some View {
        HStack {
            Text(condition.displayName)
                .font(.subheadline)

            Spacer()

            HStack(spacing: 8) {
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("(\(percentage, specifier: "%.1f")%)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

/// Recent sold items section
struct RecentSoldItemsSection: View {

    // MARK: - Properties

    let soldListings: [SoldListing]

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Sales")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)

            if soldListings.isEmpty {
                Text("No recent sales data available")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 8) {
                    ForEach(soldListings) { listing in
                        SoldListingRow(listing: listing)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

/// Individual sold listing row
struct SoldListingRow: View {

    // MARK: - Properties

    let listing: SoldListing

    // MARK: - Body

    var body: some View {
        HStack {
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
            .frame(width: 40, height: 40)
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                Text(listing.title)
                    .font(.subheadline)
                    .lineLimit(1)

                Text("$\(listing.soldPrice, specifier: "%.2f") • \(listing.formattedSoldDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.caption)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
