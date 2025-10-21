//
//  WatchlistViews.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import SwiftUI
#if canImport(Charts)
import Charts
#endif
import Combine

// MARK: - Watchlist Detail View

/// Detailed watchlist management interface
struct WatchlistDetailView: View {

    // MARK: - Properties

    @ObservedObject var manager: WatchlistManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedFilter: WatchlistFilter = .all
    @State private var sortBy: WatchlistSort = .urgency
    @State private var showingAddItemSheet = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack {
                if manager.watchlistItems.isEmpty {
                    emptyStateView
                } else {
                    VStack(spacing: 0) {
                        filterAndSortBar
                        watchlistContent
                    }
                }
            }
            .navigationTitle("Watchlist")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItemSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddItemSheet) {
                AddToWatchlistView(manager: manager)
            }
        }
    }

    // MARK: - View Components

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "eye.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Items in Watchlist")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add items to track their prices and get notified when they hit your target price")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Add First Item") {
                showingAddItemSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filterAndSortBar: some View {
        HStack {
            Menu {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(WatchlistFilter.allCases, id: \.self) { filter in
                        Text(filter.displayName).tag(filter)
                    }
                }
            } label: {
                HStack {
                    Text(selectedFilter.displayName)
                    Image(systemName: "chevron.down")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }

            Spacer()

            Menu {
                Picker("Sort", selection: $sortBy) {
                    ForEach(WatchlistSort.allCases, id: \.self) { sort in
                        Text(sort.displayName).tag(sort)
                    }
                }
            } label: {
                HStack {
                    Text("Sort: \(sortBy.displayName)")
                    Image(systemName: "arrow.up.arrow.down")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    private var watchlistContent: some View {
        List {
            ForEach(filteredAndSortedItems) { item in
                WatchlistDetailRow(item: item, manager: manager)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button("Remove", role: .destructive) {
                            manager.removeFromWatchlist(item)
                        }

                        Button("Edit") {
                            // Edit item
                        }
                        .tint(.blue)
                    }
            }
        }
        .listStyle(.plain)
    }

    // MARK: - Computed Properties

    private var filteredAndSortedItems: [WatchlistItem] {
        let filtered = manager.watchlistItems.filter { item in
            switch selectedFilter {
            case .all:
                return item.isActive
            case .targetSet:
                return item.isActive && item.targetPrice != nil
            case .priceDrops:
                return item.isActive && (item.priceDropSinceWatching ?? 0) > 0
            case .endingSoon:
                return item.isActive && item.urgencyLevel == .high || item.urgencyLevel == .critical
            }
        }

        return filtered.sorted { item1, item2 in
            switch sortBy {
            case .urgency:
                return item1.urgencyLevel.rawValue > item2.urgencyLevel.rawValue
            case .priceHigh:
                return item1.currentPrice > item2.currentPrice
            case .priceLow:
                return item1.currentPrice < item2.currentPrice
            case .added:
                return item1.watchingSince > item2.watchingSince
            case .alphabetical:
                return item1.title < item2.title
            }
        }
    }
}

// MARK: - Watchlist Detail Row

struct WatchlistDetailRow: View {
    let item: WatchlistItem
    @ObservedObject var manager: WatchlistManager

    @State private var showingPriceHistory = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and urgency
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(2)

                    if let condition = item.condition {
                        Text(condition.rawValue.capitalized)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(item.urgencyLevel.displayName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(item.urgencyLevel.color)

                    if let endTime = item.endTime {
                        Text(endTime, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Price information
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current Price")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("$\(String(format: "%.2f", item.currentPrice))")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                if let target = item.targetPrice {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Target Price")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("$\(String(format: "%.2f", target))")
                            .font(.headline)
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                if let drop = item.priceDropSinceWatching, drop > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Price Drop")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("↓\(String(format: "%.1f", drop))%")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }
            }

            // Status and actions
            HStack {
                Text(item.statusText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Price Chart") {
                    showingPriceHistory = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)

                Toggle("Alerts", isOn: .constant(item.alertsEnabled))
                    .toggleStyle(.switch)
                    .scaleEffect(0.8)
                    .onTapGesture {
                        manager.toggleAlerts(for: item.itemID)
                    }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .sheet(isPresented: $showingPriceHistory) {
            PriceHistoryView(item: item)
        }
    }
}

// MARK: - Add to Watchlist View

struct AddToWatchlistView: View {
    @ObservedObject var manager: WatchlistManager
    @Environment(\.dismiss) private var dismiss

    @State private var itemID = ""
    @State private var title = ""
    @State private var currentPrice = ""
    @State private var targetPrice = ""
    @State private var condition: PriceDataPoint.ItemCondition?

    var body: some View {
        NavigationView {
            Form {
                Section("Item Details") {
                    TextField("Item ID or URL", text: $itemID)
                    TextField("Item Title", text: $title)
                    TextField("Current Price", text: $currentPrice)
                        .keyboardType(.decimalPad)
                }

                Section("Price Targets") {
                    TextField("Target Price (Optional)", text: $targetPrice)
                        .keyboardType(.decimalPad)
                }

                Section("Condition") {
                    Picker("Condition", selection: $condition) {
                        Text("Not Specified").tag(PriceDataPoint.ItemCondition?.none)
                        ForEach([PriceDataPoint.ItemCondition.new, .openBox, .refurbished, .used], id: \.self) { condition in
                            Text(condition.rawValue.capitalized).tag(PriceDataPoint.ItemCondition?.some(condition))
                        }
                    }
                }
            }
            .navigationTitle("Add to Watchlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(itemID.isEmpty || title.isEmpty || currentPrice.isEmpty)
                }
            }
        }
    }

    private func addItem() {
        guard let price = Double(currentPrice) else { return }
        let target = targetPrice.isEmpty ? nil : Double(targetPrice)

        manager.addToWatchlist(
            itemID: itemID,
            title: title,
            currentPrice: price,
            targetPrice: target,
            condition: condition
        )

        dismiss()
    }
}

// MARK: - Price History View

struct PriceHistoryView: View {
    let item: WatchlistItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                // Item summary
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.headline)
                        .lineLimit(3)

                    HStack {
                        Text("Current: $\(String(format: "%.2f", item.currentPrice))")
                            .font(.subheadline)

                        if let target = item.targetPrice {
                            Text("Target: $\(String(format: "%.2f", target))")
                                .font(.subheadline)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)

                // Price chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Price History")
                        .font(.headline)
                        .fontWeight(.semibold)

                    if !item.priceHistory.isEmpty {
                        #if canImport(Charts)
                        if #available(iOS 16.0, *) {
                            Chart(item.priceHistory) { dataPoint in
                                LineMark(
                                    x: .value("Date", dataPoint.timestamp),
                                    y: .value("Price", dataPoint.price)
                                )
                                .foregroundStyle(.blue)

                                if let target = item.targetPrice {
                                    RuleMark(y: .value("Target", target))
                                        .foregroundStyle(.green)
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                }
                            }
                            .frame(height: 200)
                        } else {
                            Rectangle()
                                .fill(Color.blue.opacity(0.1))
                                .frame(height: 200)
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
                            .frame(height: 200)
                            .overlay(
                                Text("Price Chart\n(Charts framework required)")
                                    .multilineTextAlignment(.center)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            )
                        #endif
                    } else {
                        Text("No price history available")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Price History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Enums

enum WatchlistFilter: CaseIterable {
    case all
    case targetSet
    case priceDrops
    case endingSoon

    var displayName: String {
        switch self {
        case .all: return "All Items"
        case .targetSet: return "With Targets"
        case .priceDrops: return "Price Drops"
        case .endingSoon: return "Ending Soon"
        }
    }
}

enum WatchlistSort: CaseIterable {
    case urgency
    case priceHigh
    case priceLow
    case added
    case alphabetical

    var displayName: String {
        switch self {
        case .urgency: return "Urgency"
        case .priceHigh: return "Price: High"
        case .priceLow: return "Price: Low"
        case .added: return "Recently Added"
        case .alphabetical: return "A-Z"
        }
    }
}

// MARK: - Preview

#Preview {
    WatchlistDetailView(manager: WatchlistManager())
}
