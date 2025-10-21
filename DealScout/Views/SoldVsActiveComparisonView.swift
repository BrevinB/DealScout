//
//  SoldVsActiveComparisonView.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import SwiftUI
#if canImport(Charts)
import Charts
#endif

// MARK: - Sold vs Active Comparison View

/// Comprehensive comparison between active listings and sold items
struct SoldVsActiveComparisonView: View {

    // MARK: - Properties

    let filter: SearchFilter
    let activeListings: [EbayListing]
    @ObservedObject var viewModel: EbayDealFinderViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var soldListings: [EbayListing] = []
    @State private var isLoadingSoldItems = false
    @State private var selectedTimeFrame: TimeFrame = .thirtyDays

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    timeFrameSelector
                    comparisonSummary
                    priceComparisonChart
                    detailedAnalysis
                    soldItemsList
                }
                .padding()
            }
            .navigationTitle("Market Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Refresh") {
                        loadSoldItems()
                    }
                    .disabled(isLoadingSoldItems)
                }
            }
            .onAppear {
                loadSoldItems()
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.xaxis")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("Market Comparison")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(filter.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Text("Compare current listings with recently sold items to understand market trends and pricing")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var timeFrameSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Frame")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("Time Frame", selection: $selectedTimeFrame) {
                ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                    Text(timeFrame.displayName).tag(timeFrame)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedTimeFrame) { _ in
                loadSoldItems()
            }
        }
    }

    private var comparisonSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Summary")
                .font(.headline)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Active Listings",
                    value: "\(activeListings.count)",
                    subtitle: "currently available",
                    color: .blue,
                    icon: "tag"
                )

                StatCard(
                    title: "Sold Items",
                    value: isLoadingSoldItems ? "..." : "\(soldListings.count)",
                    subtitle: selectedTimeFrame.displayName.lowercased(),
                    color: .green,
                    icon: "checkmark.circle"
                )

                if !soldListings.isEmpty {
                    StatCard(
                        title: "Avg Active Price",
                        value: averageActivePrice,
                        subtitle: "current market",
                        color: .orange,
                        icon: "dollarsign.circle"
                    )

                    StatCard(
                        title: "Avg Sold Price",
                        value: averageSoldPrice,
                        subtitle: "recent sales",
                        color: .purple,
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
            }
        }
    }

    private var priceComparisonChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Price Distribution")
                .font(.headline)
                .fontWeight(.semibold)

            if !soldListings.isEmpty {
                #if canImport(Charts)
                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(priceDistributionData) { item in
                            BarMark(
                                x: .value("Price Range", item.range),
                                y: .value("Count", item.activeCount)
                            )
                            .foregroundStyle(.blue)
                            .opacity(0.7)

                            BarMark(
                                x: .value("Price Range", item.range),
                                y: .value("Count", item.soldCount)
                            )
                            .foregroundStyle(.green)
                            .opacity(0.7)
                        }
                    }
                    .frame(height: 200)
                    .chartLegend {
                        HStack {
                            Label("Active", systemImage: "square.fill")
                                .foregroundColor(.blue)
                            Label("Sold", systemImage: "square.fill")
                                .foregroundColor(.green)
                        }
                        .font(.caption)
                    }
                } else {
                    priceDistributionFallback
                }
                #else
                priceDistributionFallback
                #endif
            } else if isLoadingSoldItems {
                ProgressView("Loading sold items...")
                    .frame(height: 200)
            } else {
                Text("No sold items found for this time frame")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private var priceDistributionFallback: some View {
        VStack(spacing: 8) {
            ForEach(priceDistributionData.prefix(5)) { item in
                HStack {
                    Text(item.range)
                        .font(.caption)
                        .frame(width: 80, alignment: .leading)

                    HStack(spacing: 4) {
                        Rectangle()
                            .fill(.blue)
                            .frame(width: CGFloat(item.activeCount) * 3, height: 12)

                        Rectangle()
                            .fill(.green)
                            .frame(width: CGFloat(item.soldCount) * 3, height: 12)
                    }

                    Spacer()

                    Text("\(item.activeCount + item.soldCount)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Label("Active", systemImage: "square.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
                Label("Sold", systemImage: "square.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                Spacer()
            }
        }
        .padding()
    }

    private var detailedAnalysis: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Market Insights")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(alignment: .leading, spacing: 12) {
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Price Trend",
                    description: priceTrendAnalysis,
                    color: priceTrendColor
                )

                InsightRow(
                    icon: "timer",
                    title: "Market Activity",
                    description: marketActivityAnalysis,
                    color: .blue
                )

                InsightRow(
                    icon: "target",
                    title: "Opportunity",
                    description: opportunityAnalysis,
                    color: .green
                )

                if !topSellingConditions.isEmpty {
                    InsightRow(
                        icon: "star.circle",
                        title: "Popular Conditions",
                        description: "Most sold: \(topSellingConditions.joined(separator: ", "))",
                        color: .orange
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    private var soldItemsList: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Sales")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                if !soldListings.isEmpty {
                    Text("\(soldListings.count) items")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if soldListings.isEmpty && !isLoadingSoldItems {
                Text("No sold items found for the selected time frame")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .padding(.vertical, 20)
            } else {
                ForEach(soldListings.prefix(10)) { listing in
                    SoldItemRow(listing: listing)
                }

                if soldListings.count > 10 {
                    Button("Show All \(soldListings.count) Sold Items") {
                        // Could expand to show all or open in new view
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .padding(.top)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var averageActivePrice: String {
        let avg = activeListings.map(\.price).reduce(0, +) / Double(activeListings.count)
        return String(format: "$%.0f", avg)
    }

    private var averageSoldPrice: String {
        guard !soldListings.isEmpty else { return "$0" }
        let avg = soldListings.map(\.price).reduce(0, +) / Double(soldListings.count)
        return String(format: "$%.0f", avg)
    }

    private var priceTrendAnalysis: String {
        guard !soldListings.isEmpty && !activeListings.isEmpty else {
            return "Insufficient data for analysis"
        }

        let avgActive = activeListings.map(\.price).reduce(0, +) / Double(activeListings.count)
        let avgSold = soldListings.map(\.price).reduce(0, +) / Double(soldListings.count)
        let difference = ((avgActive - avgSold) / avgSold) * 100

        if abs(difference) < 5 {
            return "Prices are stable, current listings align with recent sales"
        } else if difference > 5 {
            return "Current listings are \(String(format: "%.1f", difference))% higher than recent sales"
        } else {
            return "Current listings are \(String(format: "%.1f", abs(difference)))% lower than recent sales"
        }
    }

    private var priceTrendColor: Color {
        guard !soldListings.isEmpty && !activeListings.isEmpty else { return .gray }

        let avgActive = activeListings.map(\.price).reduce(0, +) / Double(activeListings.count)
        let avgSold = soldListings.map(\.price).reduce(0, +) / Double(soldListings.count)
        let difference = ((avgActive - avgSold) / avgSold) * 100

        if abs(difference) < 5 {
            return .green
        } else if difference > 5 {
            return .red
        } else {
            return .blue
        }
    }

    private var marketActivityAnalysis: String {
        let activeDays = selectedTimeFrame.days
        let salesPerDay = Double(soldListings.count) / Double(activeDays)

        if salesPerDay > 1 {
            return "High activity: \(String(format: "%.1f", salesPerDay)) sales per day"
        } else if salesPerDay > 0.5 {
            return "Moderate activity: \(String(format: "%.1f", salesPerDay)) sales per day"
        } else {
            return "Low activity: \(String(format: "%.1f", salesPerDay)) sales per day"
        }
    }

    private var opportunityAnalysis: String {
        guard !soldListings.isEmpty && !activeListings.isEmpty else {
            return "Need more data to identify opportunities"
        }

        let minSold = soldListings.map(\.price).min() ?? 0
        let maxSold = soldListings.map(\.price).max() ?? 0
        let minActive = activeListings.map(\.price).min() ?? 0

        if minActive < minSold {
            return "Great deals available below recent sale prices"
        } else if minActive < maxSold * 0.8 {
            return "Good buying opportunities at current prices"
        } else {
            return "Current prices are at or above recent sale levels"
        }
    }

    private var topSellingConditions: [String] {
        let conditionCounts = Dictionary(grouping: soldListings, by: \.condition)
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }

        return Array(conditionCounts.prefix(3).map { $0.key })
    }

    private var priceDistributionData: [PriceDistributionItem] {
        guard !activeListings.isEmpty || !soldListings.isEmpty else { return [] }

        let allPrices = (activeListings + soldListings).map(\.price)
        let minPrice = allPrices.min() ?? 0
        let maxPrice = allPrices.max() ?? 0
        let range = maxPrice - minPrice
        let bucketSize = range / 5

        var buckets: [PriceDistributionItem] = []

        for i in 0..<5 {
            let lowerBound = minPrice + (Double(i) * bucketSize)
            let upperBound = minPrice + (Double(i + 1) * bucketSize)

            let activeCount = activeListings.filter { $0.price >= lowerBound && $0.price < upperBound }.count
            let soldCount = soldListings.filter { $0.price >= lowerBound && $0.price < upperBound }.count

            let rangeString = "$\(Int(lowerBound))-\(Int(upperBound))"

            buckets.append(PriceDistributionItem(
                id: i,
                range: rangeString,
                activeCount: activeCount,
                soldCount: soldCount
            ))
        }

        return buckets
    }

    // MARK: - Private Methods

    private func loadSoldItems() {
        isLoadingSoldItems = true

        Task {
            // Simulate API call to fetch sold items
            // In a real implementation, this would make an eBay API call
            await MainActor.run {
                // For demo purposes, create some mock sold listings
                soldListings = createMockSoldListings()
                isLoadingSoldItems = false
            }
        }
    }

    private func createMockSoldListings() -> [EbayListing] {
        // Create mock sold listings based on active listings for demo
        return activeListings.prefix(Int.random(in: 3...8)).map { listing in
            let soldPrice = listing.price * Double.random(in: 0.8...1.2)
            return EbayListing(
                itemID: "sold_" + listing.itemID,
                title: listing.title,
                price: soldPrice,
                currency: listing.currency,
                condition: listing.condition,
                imageURL: listing.imageURL,
                listingURL: listing.listingURL,
                endTime: Date().addingTimeInterval(-Double.random(in: 86400...2592000)), // 1-30 days ago
                location: listing.location,
                shippingCost: listing.shippingCost,
                buyItNowPrice: nil,
                isAuction: listing.isAuction,
                seller: listing.seller,
                dealScore: nil,
                averageMarketPrice: nil,
                savingsAmount: nil,
                savingsPercentage: nil,
                isSoldListing: true
            )
        }
    }
}

// MARK: - Supporting Views

struct SoldItemRow: View {
    let listing: EbayListing

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
            .frame(width: 50, height: 50)
            .cornerRadius(6)

            VStack(alignment: .leading, spacing: 4) {
                Text(listing.title)
                    .font(.subheadline)
                    .lineLimit(2)

                HStack {
                    Text("$\(listing.price, specifier: "%.2f")")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    Text("•")
                        .foregroundColor(.secondary)

                    Text(listing.condition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Text("Sold \(listing.endTime, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.green)
            }

            Spacer()

            Button {
                if let url = URL(string: listing.listingURL) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Image(systemName: "safari")
                    .foregroundColor(.blue)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Supporting Models

struct PriceDistributionItem: Identifiable {
    let id: Int
    let range: String
    let activeCount: Int
    let soldCount: Int
}

enum TimeFrame: String, CaseIterable {
    case sevenDays = "7d"
    case fourteenDays = "14d"
    case thirtyDays = "30d"
    case sixtyDays = "60d"

    var displayName: String {
        switch self {
        case .sevenDays: return "7 Days"
        case .fourteenDays: return "14 Days"
        case .thirtyDays: return "30 Days"
        case .sixtyDays: return "60 Days"
        }
    }

    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .fourteenDays: return 14
        case .thirtyDays: return 30
        case .sixtyDays: return 60
        }
    }
}

// MARK: - Preview

#Preview {
    SoldVsActiveComparisonView(
        filter: SearchFilter(name: "Test Filter"),
        activeListings: [],
        viewModel: EbayDealFinderViewModel()
    )
}
