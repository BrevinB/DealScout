//
//  SearchTemplateViews.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import SwiftUI

// MARK: - Search Template Library

/// Main interface for browsing and managing search templates
struct SearchTemplateLibraryView: View {

    // MARK: - Properties

    @ObservedObject var manager: SearchTemplateManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedCategory: SearchTemplate.TemplateCategory = .electronics
    @State private var searchText = ""
    @State private var showingCreateTemplate = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchBar
                categoryTabs
                templateGrid
            }
            .navigationTitle("Template Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateTemplate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                CreateTemplateView(manager: manager)
            }
        }
    }

    // MARK: - View Components

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Search templates...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private var categoryTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(SearchTemplate.TemplateCategory.allCases, id: \.self) { category in
                    CategoryTab(
                        category: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }

    private var templateGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(filteredTemplates) { template in
                    TemplateCard(template: template, manager: manager)
                }
            }
            .padding()
        }
    }

    // MARK: - Computed Properties

    private var filteredTemplates: [SearchTemplate] {
        let categoryTemplates = manager.getTemplates(for: selectedCategory)

        if searchText.isEmpty {
            return categoryTemplates
        } else {
            return categoryTemplates.filter { template in
                template.name.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
}

// MARK: - Category Tab

struct CategoryTab: View {
    let category: SearchTemplate.TemplateCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.systemImageName)
                    .font(.title2)

                Text(category.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: SearchTemplate
    @ObservedObject var manager: SearchTemplateManager

    @State private var showingPreview = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: template.category.systemImageName)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)

                    Text(template.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            // Description
            Text(template.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)

            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(template.tags.prefix(3), id: \.self) { tag in
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

            // Stats and actions
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Used \(template.useCount) times")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if template.isUserCreated {
                        Text("Custom")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }

                Spacer()

                Button("Preview") {
                    showingPreview = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Use") {
                    _ = manager.useTemplate(template)
                    // Navigate to search with template applied
                }
                .font(.caption)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .sheet(isPresented: $showingPreview) {
            TemplatePreviewView(template: template, manager: manager)
        }
    }
}

// MARK: - Template Preview

struct TemplatePreviewView: View {
    let template: SearchTemplate
    @ObservedObject var manager: SearchTemplateManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Template header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: template.category.systemImageName)
                                .font(.largeTitle)
                                .foregroundColor(.blue)

                            VStack(alignment: .leading) {
                                Text(template.name)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text(template.category.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }

                        Text(template.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Template configuration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Search Configuration")
                            .font(.headline)
                            .fontWeight(.semibold)

                        FilterConfigurationView(filter: template.baseFilter)
                    }

                    // Template stats
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Template Statistics")
                            .font(.headline)
                            .fontWeight(.semibold)

                        HStack {
                            StatItem(title: "Times Used", value: "\(template.useCount)")
                            StatItem(title: "Created", value: template.createdDate.formatted(.dateTime.month().day()))
                            if let lastUsed = template.lastUsed {
                                StatItem(title: "Last Used", value: lastUsed.formatted(.dateTime.month().day()))
                            }
                        }
                    }

                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Template Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Use Template") {
                        _ = manager.useTemplate(template)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Filter Configuration View

struct FilterConfigurationView: View {
    let filter: SearchFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let categoryID = filter.categoryID,
               let category = SearchFilter.EbayCategory.categories.first(where: { $0.id == categoryID }) {
                ConfigItem(title: "Category", value: category.name)
            }

            if let condition = filter.condition {
                ConfigItem(title: "Condition", value: condition.displayName)
            }

            if let minPrice = filter.minimumPrice, let maxPrice = filter.maximumPrice {
                ConfigItem(title: "Price Range", value: "$\(Int(minPrice)) - $\(Int(maxPrice))")
            }

            if let listingType = filter.listingType {
                ConfigItem(title: "Listing Type", value: listingType.displayName)
            }

            ConfigItem(title: "Sort Order", value: filter.sortOrder.displayName)

            if let shipping = filter.shippingOptions {
                ConfigItem(title: "Shipping", value: shipping.displayText)
            }

            if let seller = filter.sellerFilters {
                ConfigItem(title: "Seller Requirements", value: seller.displayText)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - Create Template View

struct CreateTemplateView: View {
    @ObservedObject var manager: SearchTemplateManager
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var description = ""
    @State private var selectedCategory: SearchTemplate.TemplateCategory = .electronics
    @State private var tags = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Template Details") {
                    TextField("Template Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SearchTemplate.TemplateCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }

                Section("Tags") {
                    TextField("Tags (comma separated)", text: $tags)
                        .autocapitalization(.none)
                }

                Section {
                    Text("Configure your search filters first, then create a template to save those settings for quick access.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Note")
                }
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createTemplate()
                    }
                    .disabled(name.isEmpty || description.isEmpty)
                }
            }
        }
    }

    private func createTemplate() {
        let tagArray = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }

        // Create a basic filter - in a real app, this would come from current search configuration
        let baseFilter = SearchFilter(
            name: name,
            categoryID: nil,
            listingType: .all,
            sortOrder: .bestMatch
        )

        let template = manager.createTemplate(
            from: baseFilter,
            name: name,
            description: description,
            category: selectedCategory,
            tags: tagArray
        )

        manager.saveTemplate(template)
        dismiss()
    }
}

// MARK: - Supporting Views

struct ConfigItem: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    SearchTemplateLibraryView(manager: SearchTemplateManager())
}