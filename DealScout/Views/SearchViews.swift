//
//  SearchViews.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import SwiftUI

// MARK: - Search Filter Views

/// Main view for managing saved search filters
struct SearchFiltersView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: EbayDealFinderViewModel
    @State private var showingAddFilter = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                if viewModel.filters.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "magnifyingglass.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.blue)

                        Text("Scout Your Best Deals")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Create saved searches to monitor eBay and find the best prices before anyone else")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Button("Start Scouting") {
                            showingAddFilter = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ForEach(viewModel.filters) { filter in
                        SearchFilterRow(filter: filter, viewModel: viewModel)
                    }
                    .onDelete(perform: deleteFilters)
                }
            }
            .navigationTitle("DealScout Searches")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddFilter = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFilter) {
                AdvancedFilterView(filter: nil, viewModel: viewModel)
            }
        }
    }

    // MARK: - Private Methods

    private func deleteFilters(offsets: IndexSet) {
        for index in offsets {
            viewModel.deleteFilter(viewModel.filters[index])
        }
    }
}

/// Individual search filter row with controls and status
struct SearchFilterRow: View {

    // MARK: - Properties

    let filter: SearchFilter
    @ObservedObject var viewModel: EbayDealFinderViewModel
    @State private var showingEditFilter = false
    @State private var showingNotificationSettings = false

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(filter.name)
                        .font(.headline)

                    Spacer()

                    if let avgPrice = filter.averageSoldPrice {
                        HStack(spacing: 4) {
                            Image(systemName: filter.priceDirection.systemImageName)
                                .foregroundColor(filter.priceDirection.color)
                                .font(.caption)

                            Text("Avg: $\(avgPrice, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                if let categoryID = filter.categoryID,
                   let category = SearchFilter.EbayCategory.categories.first(where: { $0.id == categoryID }) {
                    Text("Category: \(category.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Filter chips in scrollable view
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Basic filters
                        if let condition = filter.condition {
                            FilterChip(text: condition.displayName, color: .blue)
                        }

                        if let minimumPrice = filter.minimumPrice, let maximumPrice = filter.maximumPrice {
                            FilterChip(text: "$\(Int(minimumPrice)) - $\(Int(maximumPrice))", color: .green)
                        }

                        if let listingType = filter.listingType, listingType != .all {
                            FilterChip(text: listingType.displayName, color: .purple)
                        }

                        if let location = filter.location {
                            FilterChip(text: location.displayText, color: .orange)
                        }

                        if let shipping = filter.shippingOptions {
                            FilterChip(text: shipping.displayText, color: .teal)
                        }

                        if let seller = filter.sellerFilters {
                            FilterChip(text: seller.displayText, color: .red)
                        }

                        // Advanced filters
                        if let auction = filter.auctionFilters {
                            FilterChip(text: auction.displayText, color: .cyan)
                        }

                        if let features = filter.listingFeatures {
                            FilterChip(text: features.displayText, color: .mint)
                        }

                        if let specifics = filter.itemSpecifics {
                            FilterChip(text: specifics.displayText, color: .indigo)
                        }

                        if let payment = filter.paymentFilters {
                            FilterChip(text: payment.displayText, color: .pink)
                        }

                        if let photo = filter.photoFilters {
                            FilterChip(text: photo.displayText, color: .brown)
                        }

                        if let keyword = filter.keywordFilters {
                            FilterChip(text: keyword.displayText, color: .yellow)
                        }

                        if filter.sortOrder != .bestMatch {
                            FilterChip(text: filter.sortOrder.displayName, color: .gray)
                        }

                        if let excludeWords = filter.excludeKeywords, !excludeWords.isEmpty {
                            FilterChip(text: "Exclude: \(excludeWords)", color: .secondary)
                        }

                        // Notification status
                        if filter.notificationSettings.isEnabled {
                            if filter.notificationSettings.isSnoozed {
                                FilterChip(text: "🔕 Snoozed", color: .orange)
                            } else {
                                FilterChip(text: "🔔 Alerts On", color: .green)
                            }
                        }
                    }
                    .padding(.horizontal, 1)
                }

                Text("Last checked: \(filter.lastChecked, formatter: relativeDateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack {
                Toggle("", isOn: .constant(filter.isActive))
                    .onTapGesture {
                        viewModel.toggleFilter(filter)
                    }

                Menu {
                    Button {
                        Task {
                            await viewModel.searchListings(for: filter)
                        }
                    } label: {
                        Label("Search Now", systemImage: "magnifyingglass")
                    }

                    Button {
                        showingNotificationSettings = true
                    } label: {
                        Label("Alert Settings", systemImage: "bell")
                    }

                    if filter.notificationSettings.isEnabled && filter.notificationSettings.isSnoozed {
                        Button {
                            viewModel.clearSnooze(for: filter)
                        } label: {
                            Label("Clear Snooze", systemImage: "bell.slash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditFilter = true
        }
        .sheet(isPresented: $showingEditFilter) {
            AdvancedFilterView(filter: filter, viewModel: viewModel)
        }
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView(filter: filter, viewModel: viewModel)
        }
    }

    // MARK: - Private Properties

    private let relativeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
}

/// Small chip view for displaying filter criteria
struct FilterChip: View {

    // MARK: - Properties

    let text: String
    let color: Color

    // MARK: - Body

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundColor(color == .secondary ? .secondary : color)
            .cornerRadius(4)
    }
}