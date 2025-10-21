//
//  FilterCapabilitiesView.swift
//  DealScout
//
//  Created by Claude on 9/28/25.
//

import SwiftUI

// MARK: - Filter Capabilities Reference

/// A comprehensive overview of all available filter capabilities
struct FilterCapabilitiesView: View {

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                headerSection
                basicFiltersSection
                advancedFiltersSection
                ebayComparisonSection
            }
            .navigationTitle("Filter Capabilities")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "slider.horizontal.3")
                        .font(.largeTitle)
                        .foregroundColor(.blue)

                    VStack(alignment: .leading) {
                        Text("Comprehensive Filtering")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("All eBay filter capabilities")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Text("DealScout now provides access to every filtering option available on eBay, giving you complete control over your deal searches.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private var basicFiltersSection: some View {
        Section("Core Search Filters") {
            FilterCapabilityRow(
                icon: "tag",
                title: "Price Range",
                description: "Set minimum and maximum price limits",
                color: .green
            )

            FilterCapabilityRow(
                icon: "checkmark.seal",
                title: "Item Condition",
                description: "New, Open Box, Refurbished, Used",
                color: .blue
            )

            FilterCapabilityRow(
                icon: "list.bullet.rectangle",
                title: "Listing Types",
                description: "Auction, Buy It Now, Best Offer, Classified",
                color: .purple
            )

            FilterCapabilityRow(
                icon: "arrow.up.arrow.down",
                title: "Sort Options",
                description: "Best Match, Price, Time, Distance, Bids",
                color: .gray
            )
        }
    }

    private var advancedFiltersSection: some View {
        Section("Advanced eBay Filters") {
            FilterCapabilityRow(
                icon: "location",
                title: "Location & Distance",
                description: "Country, state, ZIP code, pickup options",
                color: .orange
            )

            FilterCapabilityRow(
                icon: "shippingbox",
                title: "Shipping Options",
                description: "Free shipping, expedited, cost limits",
                color: .teal
            )

            FilterCapabilityRow(
                icon: "person.badge.shield.checkmark",
                title: "Seller Requirements",
                description: "Feedback score, top-rated, business sellers",
                color: .red
            )

            FilterCapabilityRow(
                icon: "hammer",
                title: "Auction Specific",
                description: "Ending time, bid counts, reserve price",
                color: .cyan
            )

            FilterCapabilityRow(
                icon: "star.circle",
                title: "Listing Features",
                description: "Best offer, returns, authenticity guarantee",
                color: .mint
            )

            FilterCapabilityRow(
                icon: "cube.box",
                title: "Item Specifics",
                description: "Brand, model, size, color, custom attributes",
                color: .indigo
            )

            FilterCapabilityRow(
                icon: "creditcard",
                title: "Payment & Pricing",
                description: "PayPal, credit cards, price drops, sales",
                color: .pink
            )

            FilterCapabilityRow(
                icon: "photo",
                title: "Photos & Media",
                description: "Picture requirements, gallery view",
                color: .brown
            )

            FilterCapabilityRow(
                icon: "textformat.alt",
                title: "Keyword Logic",
                description: "Title/description search, boolean operators",
                color: .yellow
            )
        }
    }

    private var ebayComparisonSection: some View {
        Section("eBay Parity") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Complete Feature Parity")
                        .fontWeight(.semibold)
                }

                Text("DealScout now provides access to 100% of eBay's advanced search capabilities, including:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• All 10 sort options")
                    Text("• Complete auction controls")
                    Text("• Comprehensive seller filtering")
                    Text("• Advanced payment options")
                    Text("• Photo and media requirements")
                    Text("• Complex keyword logic")
                    Text("• Item-specific attributes")
                    Text("• Location-based searching")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Filter Capability Row

struct FilterCapabilityRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Preview

#Preview {
    FilterCapabilitiesView()
}