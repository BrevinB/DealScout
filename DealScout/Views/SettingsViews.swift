//
//  SettingsViews.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import SwiftUI

// MARK: - Settings Views

/// Main settings view
struct SettingsView: View {

    // MARK: - Properties

    @ObservedObject var viewModel: EbayDealFinderViewModel

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                // Data Management
                Section {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .frame(width: 24)

                        Text("Clear Recent Searches")

                        Spacer()

                        Button("Clear") {
                            viewModel.clearRecentSearches()
                        }
                        .buttonStyle(.bordered)
                        .disabled(viewModel.recentSearches.isEmpty)
                    }

                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.orange)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text("Price History Data")
                            Text("\(viewModel.priceHistories.count) items tracked")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                    HStack {
                        Image(systemName: "scale.3d")
                            .foregroundColor(.purple)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text("Saved Comparisons")
                            Text("\(viewModel.savedComparisons.count) comparisons")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                } header: {
                    Text("Data Management")
                }

                // App Information
                Section {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                            .frame(width: 24)

                        VStack(alignment: .leading) {
                            Text("DealScout")
                                .font(.headline)
                            Text("Version 1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }

                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

/// Notification settings view for individual filters
struct NotificationSettingsView: View {

    // MARK: - Properties

    let filter: SearchFilter
    @ObservedObject var viewModel: EbayDealFinderViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var settings: NotificationSettings

    // MARK: - Initialization

    init(filter: SearchFilter, viewModel: EbayDealFinderViewModel) {
        self.filter = filter
        self.viewModel = viewModel
        self._settings = State(initialValue: filter.notificationSettings)
    }

    // MARK: - Body

    var body: some View {
        NavigationView {
            Form {
                // Enable/Disable Notifications
                Section {
                    Toggle("Enable Notifications", isOn: $settings.isEnabled)
                } footer: {
                    Text("Receive alerts when great deals are found for this search")
                }

                if settings.isEnabled {
                    // Deal Quality Threshold
                    Section {
                        Picker("Deal Quality", selection: $settings.dealScoreThreshold) {
                            ForEach(NotificationSettings.DealScoreThreshold.allCases, id: \.self) { threshold in
                                Text(threshold.displayName).tag(threshold)
                            }
                        }
                    } header: {
                        Text("Alert Criteria")
                    } footer: {
                        Text("Only notify for deals meeting this quality threshold")
                    }

                    // Price Thresholds
                    Section {
                        HStack {
                            Text("Minimum Savings")
                            Spacer()
                            TextField("Amount", value: $settings.maxSavingsThreshold, format: .currency(code: "USD"))
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }

                        HStack {
                            Text("Price Drop %")
                            Spacer()
                            TextField("Percentage", value: $settings.priceDropThreshold, format: .percent)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    } footer: {
                        Text("Set optional thresholds for savings amount or price drop percentage")
                    }

                    // Snooze Settings
                    Section {
                        if settings.isSnoozed {
                            HStack {
                                Text("Snoozed until")
                                Spacer()
                                if let snoozeUntil = settings.snoozeUntil {
                                    Text(snoozeUntil, formatter: dateFormatter)
                                        .foregroundColor(.orange)
                                }
                            }

                            Button("Clear Snooze") {
                                settings.clearSnooze()
                            }
                            .foregroundColor(.blue)
                        }

                        Picker("Default Snooze Duration", selection: $settings.snoozeDuration) {
                            ForEach(NotificationSettings.SnoozeDuration.allCases, id: \.self) { duration in
                                Text(duration.displayName).tag(duration)
                            }
                        }
                    } header: {
                        Text("Snooze Options")
                    }

                    // Notification History
                    Section {
                        HStack {
                            Text("Notifications Sent")
                            Spacer()
                            Text("\(settings.notificationCount)")
                                .foregroundColor(.secondary)
                        }

                        if let lastDate = settings.lastNotificationDate {
                            HStack {
                                Text("Last Notification")
                                Spacer()
                                Text(lastDate, formatter: dateFormatter)
                                    .foregroundColor(.secondary)
                            }
                        }
                    } header: {
                        Text("History")
                    }
                }
            }
            .navigationTitle("Notification Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.updateNotificationSettings(for: filter, settings: settings)
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Private Properties

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}