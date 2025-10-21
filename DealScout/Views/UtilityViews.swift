//
//  UtilityViews.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import SwiftUI

// MARK: - Utility Views

/// View for browsing and selecting search templates
struct SearchTemplatesView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: EbayDealFinderViewModel
    var onTemplateSelected: ((PresetSearchTemplate) -> Void)?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                Section {
                    Text("Choose from popular search templates to quickly set up your deal monitoring")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } header: {
                    Text("Search Templates")
                }

                Section {
                    ForEach(PresetSearchTemplate.commonTemplates) { template in
                        TemplateRow(template: template) {
                            if let onSelected = onTemplateSelected {
                                onSelected(template)
                            } else {
                                createFilterFromTemplate(template)
                            }
                        }
                    }
                } header: {
                    Text("Popular Items")
                }

                Section {
                    ForEach(TrendingCategory.trendingCategories) { category in
                        TrendingCategoryRow(category: category) {
                            createFilterFromCategory(category)
                        }
                    }
                } header: {
                    Text("Trending Categories")
                }
            }
            .navigationTitle("Templates")
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

    // MARK: - Private Methods

    private func createFilterFromTemplate(_ template: PresetSearchTemplate) {
        let filter = SearchFilter(
            name: template.name,
            categoryID: template.categoryID,
            minimumPrice: template.priceRange.minimumPrice,
            maximumPrice: template.priceRange.maximumPrice,
            condition: template.condition
        )
        viewModel.addFilter(filter)
        dismiss()
    }

    private func createFilterFromCategory(_ category: TrendingCategory) {
        let filter = SearchFilter(
            name: category.name,
            categoryID: category.id,
            minimumPrice: nil,
            maximumPrice: category.averagePrice != nil ? category.averagePrice! * 1.5 : nil
        )
        viewModel.addFilter(filter)
        dismiss()
    }
}

/// Row for displaying search templates
struct TemplateRow: View {

    // MARK: - Properties

    let template: PresetSearchTemplate
    let onSelect: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: template.iconName)
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        if let minPrice = template.priceRange.minimumPrice,
                           let maxPrice = template.priceRange.maximumPrice {
                            Text("$\(Int(minPrice)) - $\(Int(maxPrice))")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }

                        if let condition = template.condition {
                            Text(condition.displayName)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                        }
                    }
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

/// Row for displaying trending categories
struct TrendingCategoryRow: View {

    // MARK: - Properties

    let category: TrendingCategory
    let onSelect: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: category.iconName)
                    .foregroundColor(.orange)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(category.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack(spacing: 12) {
                        Text("Trending: \(category.trendScore, specifier: "%.0f")%")
                            .font(.caption)
                            .foregroundColor(.orange)

                        if let avgPrice = category.averagePrice {
                            Text("Avg: $\(avgPrice, specifier: "%.0f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Popular keywords
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(category.popularKeywords, id: \.self) { keyword in
                                Text(keyword)
                                    .font(.caption2)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.purple.opacity(0.1))
                                    .foregroundColor(.purple)
                                    .cornerRadius(3)
                            }
                        }
                    }
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

/// View for browsing recent searches
struct RecentSearchesView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: EbayDealFinderViewModel
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                if viewModel.recentSearches.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text("No Recent Searches")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Your recent searches will appear here")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    Section {
                        ForEach(viewModel.recentSearches) { search in
                            RecentSearchRow(search: search) {
                                createFilterFromSearch(search)
                            }
                        }
                    } header: {
                        HStack {
                            Text("Recent Searches")
                            Spacer()
                            Button("Clear All") {
                                viewModel.clearRecentSearches()
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Recent Searches")
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

    // MARK: - Private Methods

    private func createFilterFromSearch(_ search: RecentSearch) {
        let filter = SearchFilter(
            name: search.keywords,
            categoryID: nil,
            minimumPrice: nil,
            maximumPrice: nil
        )
        viewModel.addFilter(filter)
        dismiss()
    }
}

/// Row for displaying recent searches
struct RecentSearchRow: View {

    // MARK: - Properties

    let search: RecentSearch
    let onSelect: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onSelect) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(search.keywords)
                        .font(.headline)
                        .foregroundColor(.primary)

                    HStack {
                        Text(search.searchDate, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if let count = search.resultCount {
                            Text("• \(count) results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                Image(systemName: "plus.circle")
                    .foregroundColor(.green)
                    .font(.title3)
            }
        }
        .buttonStyle(.plain)
    }
}
