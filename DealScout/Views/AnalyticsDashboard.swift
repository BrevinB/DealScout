//
//  AnalyticsDashboard.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import SwiftUI
#if canImport(Charts)
import Charts
#endif

// MARK: - Analytics Dashboard

/// Main analytics dashboard showing price intelligence and deal insights
struct AnalyticsDashboard: View {

    // MARK: - Properties

    @StateObject private var dealScoringService = DealScoringService()
    @StateObject private var watchlistManager = WatchlistManager()
    @StateObject private var templateManager = SearchTemplateManager()

    @State private var selectedTimeframe: AnalyticsTimeFrame = .week
    @State private var showingWatchlistDetail = false
    @State private var showingTemplateLibrary = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 20) {
                    headerSection
                    quickStatsSection
                    priceInsightsSection
                    watchlistSection
                    dealQualitySection
                    templatesSection
                }
                .padding()
            }
            .navigationTitle("Deal Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Timeframe", selection: $selectedTimeframe) {
                            ForEach(AnalyticsTimeFrame.allCases, id: \.self) { timeframe in
                                Text(timeframe.displayName).tag(timeframe)
                            }
                        }
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showingWatchlistDetail) {
                WatchlistDetailView(manager: watchlistManager)
            }
            .sheet(isPresented: $showingTemplateLibrary) {
                SearchTemplateLibraryView(manager: templateManager)
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundColor(.blue)

                VStack(alignment: .leading) {
                    Text("Deal Intelligence")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Smart insights for better deals")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Stats")
                .font(.headline)
                .fontWeight(.semibold)

            let stats = watchlistManager.getWatchlistStatistics()

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Watching",
                    value: "\(stats.totalItems)",
                    subtitle: "items",
                    color: .blue,
                    icon: "eye"
                )

                StatCard(
                    title: "Total Value",
                    value: stats.formattedTotalValue,
                    subtitle: "tracked",
                    color: .green,
                    icon: "dollarsign.circle"
                )

                StatCard(
                    title: "Potential Savings",
                    value: stats.formattedPotentialSavings,
                    subtitle: "if targets hit",
                    color: .orange,
                    icon: "arrow.down.circle"
                )

                StatCard(
                    title: "Price Drops",
                    value: "\(stats.itemsWithPriceDrops)",
                    subtitle: "items trending down",
                    color: .purple,
                    icon: "chart.line.downtrend.xyaxis"
                )
            }
        }
    }

    private var priceInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Price Insights")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("View All") {
                    // Navigate to detailed price insights
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            // Sample price trend chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Market Trends")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let sampleData = generateSamplePriceData() {
                    #if canImport(Charts)
                    if #available(iOS 16.0, *) {
                        Chart(sampleData) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Price", item.price)
                            )
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 120)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { _ in
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            }
                        }
                        .chartYAxis {
                            AxisMarks { _ in
                                AxisValueLabel(format: .currency(code: "USD"))
                            }
                        }
                    } else {
                        Rectangle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(height: 120)
                            .overlay(
                                Text("Price Chart\n(iOS 16+ required)")
                                    .multilineTextAlignment(.center)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            )
                    }
                    #else
                    Rectangle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(height: 120)
                        .overlay(
                            Text("Price Chart\n(Charts framework required)")
                                .multilineTextAlignment(.center)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        )
                    #endif
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
    }

    private var watchlistSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Watchlist Highlights")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Manage") {
                    showingWatchlistDetail = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            let urgentItems = watchlistManager.getItemsByUrgency().prefix(3)

            if urgentItems.isEmpty {
                EmptyStateView(
                    icon: "eye.slash",
                    title: "No Items Watched",
                    description: "Add items to your watchlist to track prices"
                )
            } else {
                ForEach(Array(urgentItems), id: \.id) { item in
                    WatchlistItemRow(item: item)
                }
            }
        }
    }

    private var dealQualitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Deal Quality Insights")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                DealQualityDistribution()
                RecentDealScores()
            }
        }
    }

    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Search Templates")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("Browse All") {
                    showingTemplateLibrary = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }

            let popularTemplates = templateManager.getPopularTemplates().prefix(3)

            if popularTemplates.isEmpty {
                SearchTemplateCreator(manager: templateManager)
            } else {
                ForEach(Array(popularTemplates), id: \.id) { template in
                    SearchTemplateRow(template: template, manager: templateManager)
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func generateSamplePriceData() -> [PriceChartData]? {
        let calendar = Calendar.current
        let now = Date()

        return (0..<30).compactMap { dayOffset in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { return nil }
            let price = 250 + Double.random(in: -50...50) + sin(Double(dayOffset) * 0.2) * 20
            return PriceChartData(date: date, price: price)
        }.reversed()
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct WatchlistItemRow: View {
    let item: WatchlistItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(2)

                Text(item.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Text("$\(String(format: "%.2f", item.currentPrice))")
                        .font(.headline)
                        .fontWeight(.bold)

                    if let drop = item.priceDropSinceWatching, drop > 0 {
                        Text("↓\(String(format: "%.1f", drop))%")
                            .font(.caption)
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            VStack {
                Circle()
                    .fill(item.urgencyLevel.color)
                    .frame(width: 8, height: 8)

                Text(item.urgencyLevel.displayName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct DealQualityDistribution: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Deal Quality Distribution")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 4) {
                ForEach(DealQuality.allCases, id: \.self) { quality in
                    Rectangle()
                        .fill(quality.color)
                        .frame(height: 8)
                        .overlay(
                            Text("\(Int.random(in: 5...25))")
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                }
            }
            .cornerRadius(4)

            HStack {
                ForEach(DealQuality.allCases, id: \.self) { quality in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(quality.color)
                            .frame(width: 8, height: 8)
                        Text(quality.displayName)
                            .font(.caption2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct RecentDealScores: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Deal Scores")
                .font(.subheadline)
                .fontWeight(.medium)

            VStack(spacing: 8) {
                ForEach(0..<3) { index in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iPhone 14 Pro - Excellent Deal")
                                .font(.caption)
                                .fontWeight(.medium)

                            Text("25% below market average")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("8.5")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SearchTemplateRow: View {
    let template: SearchTemplate
    let manager: SearchTemplateManager

    var body: some View {
        HStack {
            Image(systemName: template.category.systemImageName)
                .foregroundColor(.blue)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                HStack {
                    Text("Used \(template.useCount) times")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    ForEach(template.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }
            }

            Spacer()

            Button("Use") {
                _ = manager.useTemplate(template)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct SearchTemplateCreator: View {
    let manager: SearchTemplateManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wand.and.stars")
                .font(.largeTitle)
                .foregroundColor(.blue)

            Text("Create Your First Template")
                .font(.headline)
                .fontWeight(.semibold)

            Text("Save your search configurations as templates for quick access")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Get Started") {
                // Navigate to template creation
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.gray)

            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Models

enum AnalyticsTimeFrame: String, CaseIterable {
    case day = "24h"
    case week = "7d"
    case month = "30d"
    case quarter = "90d"

    var displayName: String {
        switch self {
        case .day: return "24 Hours"
        case .week: return "7 Days"
        case .month: return "30 Days"
        case .quarter: return "90 Days"
        }
    }
}

struct PriceChartData: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}

// MARK: - Preview

#Preview {
    AnalyticsDashboard()
}
