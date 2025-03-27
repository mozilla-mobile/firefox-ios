// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Common

class ClearHistorySheetProvider {
    private let profile: Profile
    private let windowManager: WindowManager

    init(profile: Profile, windowManager: WindowManager = AppContainer.shared.resolve()) {
        self.profile = profile
        self.windowManager = windowManager
    }

    /// Present a prompt that will enable the user to choose how he wants to clear his recent history
    /// - Parameters:
    ///   - viewController: The view controller the clear history prompt is shown on
    ///   - didComplete: Did complete a recent history clear up action
    func showClearRecentHistory(
        onViewController viewController: UIViewController,
        didComplete: ((HistoryDeletionUtilityDateOptions) -> Void)? = nil
    ) {
        let alert = createAlertAndConfigureWithArrowIfNeeded(from: viewController)
        setupActions(for: alert, didComplete: didComplete)

        viewController.present(alert, animated: true)
    }

    func createAlertAndConfigureWithArrowIfNeeded(from viewController: UIViewController) -> UIAlertController {
        let alert = UIAlertController(title: .LibraryPanel.History.ClearHistorySheet.Title,
                                      message: nil,
                                      preferredStyle: .actionSheet)

        // This will run on the iPad-only, and sets the alert to be centered with no arrow.
        guard let view = viewController.view else { return alert }
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = view
            popoverController.sourceRect = CGRect(x: view.bounds.midX,
                                                  y: view.bounds.midY,
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }

        return alert
    }

    func setupActions(
        for alert: UIAlertController,
        didComplete: ((HistoryDeletionUtilityDateOptions) -> Void)? = nil
    ) {
        addDeleteSomeData(to: alert, didComplete: didComplete)
        addDeleteEverythingOption(to: alert, didComplete: didComplete)
        addCancelAction(to: alert)
    }

    func addDeleteSomeData(
        to alert: UIAlertController,
        didComplete: ((HistoryDeletionUtilityDateOptions) -> Void)? = nil
    ) {
        typealias DateOptions = HistoryDeletionUtilityDateOptions
        [
            // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-4187
            (String.LibraryPanel.History.ClearHistorySheet.LastHourOption, DateOptions.lastHour),
            (String.LibraryPanel.History.ClearHistorySheet.LastTwentyFourHoursOption, DateOptions.lastTwentyFourHours),
            (String.LibraryPanel.History.ClearHistorySheet.LastSevenDaysOption, DateOptions.lastSevenDays),
            (String.LibraryPanel.History.ClearHistorySheet.LastFourWeeksOption, DateOptions.lastFourWeeks)
        ].forEach { (name, timeRange) in
            let action = UIAlertAction(title: name, style: .destructive) { _ in
                let deletionUtility = HistoryDeletionUtility(with: self.profile)
                deletionUtility.deleteHistoryFrom(timeRange) { dateOption in
                    NotificationCenter.default.post(name: .TopSitesUpdated, object: self)
                    didComplete?(dateOption)
                    DispatchQueue.main.async {
                        deletionUtility.deleteHistoryMetadataOlderThan(dateOption)
                    }
                }
            }

            alert.addAction(action)
        }
    }

    func addDeleteEverythingOption(
        to alert: UIAlertController,
        didComplete: ((HistoryDeletionUtilityDateOptions) -> Void)? = nil
    ) {
        alert.addAction(UIAlertAction(title: .LibraryPanel.History.ClearHistorySheet.AllTimeOption,
                                      style: .destructive) { _ in
            let deletionUtilitiy = HistoryDeletionUtility(with: self.profile)
            deletionUtilitiy.deleteHistoryFrom(.allTime) { dateOption in
                DispatchQueue.main.async {
                    // Clear and reset tab history for all windows / tab managers
                    self.windowManager.allWindowTabManagers().forEach { $0.clearAllTabsHistory() }
                }
                NotificationCenter.default.post(name: .PrivateDataClearedHistory, object: nil)
                didComplete?(dateOption)
                // perform history metadata deletion that sends a notification and updates
                // the data and the UI for recently visited section, which can only happen on main thread
                DispatchQueue.main.async {
                    deletionUtilitiy.deleteHistoryMetadataOlderThan(dateOption)
                }
            }
        })
    }

    func addCancelAction(to alert: UIAlertController) {
        let cancelAction = UIAlertAction(title: .CancelString, style: .cancel)
        alert.addAction(cancelAction)
    }
}
