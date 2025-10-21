//
//  ContentView.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import SwiftUI

// MARK: - Main Content View

/// Main tab-based navigation view for the DealScout app
struct ContentView: View {

    // MARK: - Properties

    @EnvironmentObject var viewModel: EbayDealFinderViewModel
    @State private var selectedTab = 0

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            SearchFiltersView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "magnifyingglass.circle")
                    Text("Searches")
                }
                .tag(0)

            DealsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "tag.fill")
                    Text("Deals")
                }
                .tag(1)

            MarketInsightsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Market")
                }
                .tag(2)

            ComparisonView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "scale.3d")
                    Text("Compare")
                }
                .tag(3)
                .badge(viewModel.activeComparison?.listings.count ?? 0)

            SettingsView(viewModel: viewModel)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(4)
        }
        .accentColor(.blue)
    }
}