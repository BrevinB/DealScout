//
//  DealScoutApp.swift
//  DealScout
//
//  Created by Brevin Blalock on 9/1/25.
//

import SwiftUI
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    weak var viewModel: EbayDealFinderViewModel?

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {

        let userInfo = response.notification.request.content.userInfo
        guard let filterIdString = userInfo["filterId"] as? String,
              let filterId = UUID(uuidString: filterIdString) else {
            completionHandler()
            return
        }

        switch response.actionIdentifier {
        case "VIEW_DEALS":
            // Navigate to deals view for this filter
            DispatchQueue.main.async {
                if let filter = self.viewModel?.filters.first(where: { $0.id == filterId }) {
                    self.viewModel?.selectFilterForMarketAnalysis(filter)
                }
            }

        case "SNOOZE_1H":
            // Snooze notifications for 1 hour
            DispatchQueue.main.async {
                if let filter = self.viewModel?.filters.first(where: { $0.id == filterId }) {
                    self.viewModel?.snoozeNotifications(for: filter, duration: .oneHour)
                }
            }

        case "DISABLE_ALERTS":
            // Disable notifications for this filter
            DispatchQueue.main.async {
                if let filter = self.viewModel?.filters.first(where: { $0.id == filterId }) {
                    self.viewModel?.disableNotifications(for: filter)
                }
            }

        default:
            break
        }

        completionHandler()
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}

@main
struct DealScoutApp: App {
    @StateObject private var viewModel = EbayDealFinderViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .onAppear {
                    setupNotifications()
                }
        }
    }

    private func setupNotifications() {
        NotificationDelegate.shared.viewModel = viewModel
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
}
