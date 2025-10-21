//
//  FormViews.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import SwiftUI

// MARK: - Form Views

/// View for adding a new search filter
struct AddSearchFilterView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: EbayDealFinderViewModel
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name = ""
    @State private var selectedCategory: SearchFilter.EbayCategory?
    @State private var condition: SearchFilter.ItemCondition?
    @State private var minimumPrice = ""
    @State private var maximumPrice = ""
    @State private var listingType: SearchFilter.ListingType = .all
    @State private var sortOrder: SearchFilter.SortOrder = .bestMatch
    @State private var keywords = ""
    @State private var showingTemplates = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                Section("Search Details") {
                    TextField("Search Name", text: $name)
                    TextField("Keywords", text: $keywords)
                        .autocapitalization(.none)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Any Category").tag(SearchFilter.EbayCategory?.none)
                        ForEach(SearchFilter.EbayCategory.categories) { category in
                            Text(category.name).tag(SearchFilter.EbayCategory?.some(category))
                        }
                    }
                }

                Section("Filters") {
                    Picker("Condition", selection: $condition) {
                        Text("Any Condition").tag(SearchFilter.ItemCondition?.none)
                        ForEach(SearchFilter.ItemCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(SearchFilter.ItemCondition?.some(condition))
                        }
                    }

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
                }

                Section {
                    Button("Use Template") {
                        showingTemplates = true
                    }
                }
            }
            .navigationTitle("Add Search Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFilter()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .sheet(isPresented: $showingTemplates) {
                SearchTemplatesView(viewModel: viewModel, onTemplateSelected: { template in
                    applyTemplate(template)
                    showingTemplates = false
                })
            }
        }
    }

    // MARK: - Private Methods

    private func saveFilter() {
        let filter = SearchFilter(
            name: name.isEmpty ? "New Search" : name,
            categoryID: selectedCategory?.id,
            minimumPrice: Double(minimumPrice),
            maximumPrice: Double(maximumPrice),
            condition: condition,
            listingType: listingType,
            sortOrder: sortOrder,
            excludeKeywords: keywords.isEmpty ? nil : keywords
        )

        viewModel.addFilter(filter)
        dismiss()
    }

    private func applyTemplate(_ template: PresetSearchTemplate) {
        name = template.name
        keywords = template.keywords
        selectedCategory = SearchFilter.EbayCategory.categories.first { $0.id == template.categoryID }
        condition = template.condition
        minimumPrice = template.priceRange.minimumPrice != nil ? String(template.priceRange.minimumPrice!) : ""
        maximumPrice = template.priceRange.maximumPrice != nil ? String(template.priceRange.maximumPrice!) : ""
    }
}

/// View for editing an existing search filter
struct EditSearchFilterView: View {

    // MARK: - Properties

    let filter: SearchFilter
    @ObservedObject var viewModel: EbayDealFinderViewModel
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var name = ""
    @State private var selectedCategory: SearchFilter.EbayCategory?
    @State private var condition: SearchFilter.ItemCondition?
    @State private var minimumPrice = ""
    @State private var maximumPrice = ""
    @State private var listingType: SearchFilter.ListingType = .all
    @State private var sortOrder: SearchFilter.SortOrder = .bestMatch
    @State private var keywords = ""

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                Section("Search Details") {
                    TextField("Search Name", text: $name)
                    TextField("Keywords", text: $keywords)
                        .autocapitalization(.none)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        Text("Any Category").tag(SearchFilter.EbayCategory?.none)
                        ForEach(SearchFilter.EbayCategory.categories) { category in
                            Text(category.name).tag(SearchFilter.EbayCategory?.some(category))
                        }
                    }
                }

                Section("Filters") {
                    Picker("Condition", selection: $condition) {
                        Text("Any Condition").tag(SearchFilter.ItemCondition?.none)
                        ForEach(SearchFilter.ItemCondition.allCases, id: \.self) { condition in
                            Text(condition.displayName).tag(SearchFilter.ItemCondition?.some(condition))
                        }
                    }

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
                }
            }
            .navigationTitle("Edit Search Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveFilter()
                    }
                }
            }
            .onAppear {
                loadFilterData()
            }
        }
    }

    // MARK: - Private Methods

    private func loadFilterData() {
        name = filter.name
        selectedCategory = SearchFilter.EbayCategory.categories.first { $0.id == filter.categoryID }
        condition = filter.condition
        minimumPrice = filter.minimumPrice != nil ? String(filter.minimumPrice!) : ""
        maximumPrice = filter.maximumPrice != nil ? String(filter.maximumPrice!) : ""
        listingType = filter.listingType ?? .all
        sortOrder = filter.sortOrder
        keywords = filter.excludeKeywords ?? ""
    }

    private func saveFilter() {
        var updatedFilter = filter
        updatedFilter.name = name.isEmpty ? "Updated Search" : name
        updatedFilter.categoryID = selectedCategory?.id
        updatedFilter.minimumPrice = Double(minimumPrice)
        updatedFilter.maximumPrice = Double(maximumPrice)
        updatedFilter.condition = condition
        updatedFilter.listingType = listingType
        updatedFilter.sortOrder = sortOrder
        updatedFilter.excludeKeywords = keywords.isEmpty ? nil : keywords

        viewModel.updateFilter(updatedFilter)
        dismiss()
    }
}

/// View for API setup and configuration
struct APISetupView: View {

    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var clientID = ""
    @State private var clientSecret = ""
    @State private var isTestingConnection = false
    @State private var testResult = ""
    @State private var showingResult = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Text("Configure your eBay Developer API credentials to start finding deals.")
                        .foregroundColor(.secondary)
                } header: {
                    Text("eBay API Setup")
                }

                Section {
                    TextField("Client ID", text: $clientID)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    SecureField("Client Secret", text: $clientSecret)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                } header: {
                    Text("API Credentials")
                } footer: {
                    Text("Get your API credentials from the eBay Developer Program website.")
                        .foregroundColor(.secondary)
                }

                Section {
                    Button(action: testConnection) {
                        HStack {
                            if isTestingConnection {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isTestingConnection ? "Testing..." : "Test Connection")
                        }
                    }
                    .disabled(clientID.isEmpty || clientSecret.isEmpty || isTestingConnection)
                }
            }
            .navigationTitle("API Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCredentials()
                    }
                    .disabled(clientID.isEmpty || clientSecret.isEmpty)
                }
            }
            .alert("Connection Test", isPresented: $showingResult) {
                Button("OK") {}
            } message: {
                Text(testResult)
            }
            .onAppear {
                loadCredentials()
            }
        }
    }

    // MARK: - Private Methods

    private func loadCredentials() {
        clientID = UserDefaults.standard.string(forKey: "EbayClientId") ?? ""
        clientSecret = UserDefaults.standard.string(forKey: "EbayClientSecret") ?? ""
    }

    private func saveCredentials() {
        UserDefaults.standard.set(clientID, forKey: "EbayClientId")
        UserDefaults.standard.set(clientSecret, forKey: "EbayClientSecret")

        // Post notification to update UI
        NotificationCenter.default.post(name: .ebayCredentialsUpdated, object: nil)

        dismiss()
    }

    private func testConnection() {
        isTestingConnection = true

        // Save credentials temporarily for testing
        UserDefaults.standard.set(clientID, forKey: "EbayClientId")
        UserDefaults.standard.set(clientSecret, forKey: "EbayClientSecret")

        Task {
            let apiService = EbayAPIService()
            let result = await apiService.testConnection()

            DispatchQueue.main.async {
                self.isTestingConnection = false
                self.testResult = result.message
                self.showingResult = true
            }
        }
    }
}
