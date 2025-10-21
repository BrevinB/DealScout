//
//  NotificationSettings.swift
//  DealScout
//
//  Created by Claude on 9/27/25.
//

import Foundation

// MARK: - Notification Models

/// Settings for deal notifications and alerts
struct NotificationSettings: Codable {

    // MARK: - Properties

    var isEnabled: Bool = true
    var dealScoreThreshold: DealScoreThreshold = .excellent
    var priceDropThreshold: Double? // Percentage drop to trigger alert
    var maxSavingsThreshold: Double? // Minimum savings amount to trigger alert
    var snoozeUntil: Date?
    var snoozeDuration: SnoozeDuration = .oneHour
    var lastNotificationDate: Date?
    var notificationCount: Int = 0

    // MARK: - Nested Types

    /// Threshold for deal quality to trigger notifications
    enum DealScoreThreshold: String, CaseIterable, Codable {
        case any = "any"
        case fair = "fair"
        case good = "good"
        case excellent = "excellent"

        var displayName: String {
            switch self {
            case .any: return "Any Deal"
            case .fair: return "Fair Deals or Better"
            case .good: return "Good Deals or Better"
            case .excellent: return "Excellent Deals Only"
            }
        }

        func shouldNotify(for dealScore: EbayListing.DealScore?) -> Bool {
            guard let score = dealScore else { return self == .any }

            switch self {
            case .any: return true
            case .fair: return true // All deals are fair or better
            case .good: return score == .good || score == .excellent
            case .excellent: return score == .excellent
            }
        }
    }

    /// Duration options for snoozing notifications
    enum SnoozeDuration: String, CaseIterable, Codable {
        case fifteenMinutes = "15m"
        case thirtyMinutes = "30m"
        case oneHour = "1h"
        case twoHours = "2h"
        case fourHours = "4h"
        case oneDay = "1d"
        case threeDays = "3d"
        case oneWeek = "1w"

        var displayName: String {
            switch self {
            case .fifteenMinutes: return "15 minutes"
            case .thirtyMinutes: return "30 minutes"
            case .oneHour: return "1 hour"
            case .twoHours: return "2 hours"
            case .fourHours: return "4 hours"
            case .oneDay: return "1 day"
            case .threeDays: return "3 days"
            case .oneWeek: return "1 week"
            }
        }

        var timeInterval: TimeInterval {
            switch self {
            case .fifteenMinutes: return 15 * 60
            case .thirtyMinutes: return 30 * 60
            case .oneHour: return 60 * 60
            case .twoHours: return 2 * 60 * 60
            case .fourHours: return 4 * 60 * 60
            case .oneDay: return 24 * 60 * 60
            case .threeDays: return 3 * 24 * 60 * 60
            case .oneWeek: return 7 * 24 * 60 * 60
            }
        }
    }

    // MARK: - Computed Properties

    var isSnoozed: Bool {
        guard let snoozeUntil = snoozeUntil else { return false }
        return snoozeUntil > Date()
    }

    // MARK: - Methods

    mutating func snooze(for duration: SnoozeDuration) {
        snoozeUntil = Date().addingTimeInterval(duration.timeInterval)
        snoozeDuration = duration
    }

    mutating func clearSnooze() {
        snoozeUntil = nil
    }
}