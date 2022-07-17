// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

class ClearHistoryHelper {

    enum DateOptions {
        // case hour
        case today
        case yesterday
    }

    private let profile: Profile
    private let tabManager: TabManager

    init(profile: Profile, tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
    }

    /// Present a prompt that will enable the user to choose how he wants to clear his recent history
    /// - Parameters:
    ///   - viewController: The view controller the clear history prompt is shown on
    ///   - didComplete: Did complete a recent history clear up action
    func showClearRecentHistory(onViewController viewController: UIViewController, didComplete: ((Date?) -> Void)? = nil) {
        func remove(dateOption: DateOptions) {
            var date: Date?
            switch dateOption {
            case .today:
                date = Date()
            case .yesterday:
                date = Calendar.current.date(byAdding: .hour, value: -24, to: Date())
            }

            if let date = date {
                let startOfDay = Calendar.current.startOfDay(for: date)
                let types = WKWebsiteDataStore.allWebsiteDataTypes()
                WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: startOfDay, completionHandler: {})

                self.profile.history.removeHistoryFromDate(date).uponQueue(.global(qos: .userInteractive)) { result in
                    guard let completion = didComplete else { return }
                    self.profile.recentlyClosedTabs.removeTabsFromDate(startOfDay)
                    completion(startOfDay)
                }
            }
        }

        let alert = UIAlertController(title: .LibraryPanel.History.ClearHistoryMenuTitle, message: nil, preferredStyle: .actionSheet)

        // This will run on the iPad-only, and sets the alert to be centered with no arrow.
        guard let view = viewController.view else { return }
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-4187
        [(String.ClearHistoryMenuOptionToday, DateOptions.today),
         (String.ClearHistoryMenuOptionTodayAndYesterday, DateOptions.yesterday)].forEach {
            (name, time) in
            let action = UIAlertAction(title: name, style: .destructive) { _ in
                remove(dateOption: time)
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: .ClearHistoryMenuOptionEverything, style: .destructive, handler: { _ in
            let types = WKWebsiteDataStore.allWebsiteDataTypes()
            WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast, completionHandler: {})
            self.profile.history.clearHistory().uponQueue(.global(qos: .userInteractive)) { _ in
                // INT64_MAX represents the oldest possible time that AS would have
                self.profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).uponQueue(.global(qos: .userInteractive)) { _ in
                    guard let completion = didComplete else { return }
                    completion(nil)
                }
            }
            self.profile.recentlyClosedTabs.clearTabs()
            self.tabManager.clearAllTabsHistory()
            NotificationCenter.default.post(name: .PrivateDataClearedHistory, object: nil)
        }))
        let cancelAction = UIAlertAction(title: .CancelString, style: .cancel)
        alert.addAction(cancelAction)
        viewController.present(alert, animated: true)
    }
}
