// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit

class ClearHistoryHelper {

    private let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    /// Present a prompt that will enable the user to choose how he wants to clear his recent history
    /// - Parameters:
    ///   - viewController: The view controller the clear history prompt is shown on
    ///   - didComplete: Did complete a recent history clear up action
    func showClearRecentHistory(onViewController viewController: UIViewController, didComplete: @escaping () -> Void) {
        func remove(hoursAgo: Int) {
            if let date = Calendar.current.date(byAdding: .hour, value: -hoursAgo, to: Date()) {
                let types = WKWebsiteDataStore.allWebsiteDataTypes()
                WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: date, completionHandler: {})

                self.profile.history.removeHistoryFromDate(date).uponQueue(.main) { _ in
                    didComplete()
                }
            }
        }

        let alert = UIAlertController(title: .ClearHistoryMenuTitle, message: nil, preferredStyle: .actionSheet)

        // This will run on the iPad-only, and sets the alert to be centered with no arrow.
        guard let view = viewController.view else { return }
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }

        [(String.ClearHistoryMenuOptionTheLastHour, 1),
         (String.ClearHistoryMenuOptionToday, 24),
         (String.ClearHistoryMenuOptionTodayAndYesterday, 48)].forEach {
            (name, time) in
            let action = UIAlertAction(title: name, style: .destructive) { _ in
                remove(hoursAgo: time)
            }
            alert.addAction(action)
        }
        alert.addAction(UIAlertAction(title: .ClearHistoryMenuOptionEverything, style: .destructive, handler: { _ in
            let types = WKWebsiteDataStore.allWebsiteDataTypes()
            WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: .distantPast, completionHandler: {})
            self.profile.history.clearHistory().uponQueue(.main) { _ in
                didComplete()
            }
            self.profile.recentlyClosedTabs.clearTabs()
        }))
        let cancelAction = UIAlertAction(title: .CancelString, style: .cancel)
        alert.addAction(cancelAction)
        viewController.present(alert, animated: true)
    }
}
