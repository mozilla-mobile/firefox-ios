// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol RestoreTabManagerDelegate: AnyObject {
    /// The user has chosen to restore their tabs
    func needsTabRestore()

    /// If there's no tabs to restore, or the user doesn't want their tab restored, then we open a new tab so the user always has at least one tab
    func needsNewTabOpened()
}

protocol RestoreTabManager {
    /// CrashedLastLaunch is sticky and doesn't get reset, so we need to remember its value so that we do not keep asking the user to restore their tabs
    /// But we only set this to true once the user has made his choice whether they want to restore their tabs or not, otherwise we keep showing the alert.
    var alertNeedsToShow: Bool { get }

    /// Shows the restore tab alert on the view controller. Make sure to call `alertNeedsToShow` beforehand
    /// - Parameters:
    ///   - viewController: The view controller this alert will be presented on
    ///   - alertCreator: The restore alert creatr which will build the UI Alert for us
    func showAlert(on viewController: Presenter,
                   alertCreator: RestoreAlertCreator)
}

extension RestoreTabManager {
    func showAlert(on viewController: Presenter,
                   alertCreator: RestoreAlertCreator = DefaultRestoreAlertCreator()) {
        showAlert(on: viewController, alertCreator: alertCreator)
    }
}

class DefaultRestoreTabManager: RestoreTabManager {
    private var logger: Logger
    private var userDefaults: UserDefaultsInterface
    private var hasTabsToRestoreAtStartup: Bool
    private var delegate: RestoreTabManagerDelegate?

    private enum UserDefaultsKey: String {
        case keyRestoreTabsAlertNeedsToBeShown = "restoreTabsAlertNeedsToBeShown"
    }

    private(set) var alertNeedsToShow: Bool {
        get { userDefaults.object(forKey: UserDefaultsKey.keyRestoreTabsAlertNeedsToBeShown.rawValue) as? Bool ?? false }
        set { userDefaults.set(newValue, forKey: UserDefaultsKey.keyRestoreTabsAlertNeedsToBeShown.rawValue) }
    }

    init(
        hasTabsToRestoreAtStartup: Bool,
        delegate: RestoreTabManagerDelegate?,
        logger: Logger = DefaultLogger.shared,
        userDefaults: UserDefaultsInterface = UserDefaults.standard
    ) {
        self.logger = logger
        self.userDefaults = userDefaults
        self.hasTabsToRestoreAtStartup = hasTabsToRestoreAtStartup
        self.delegate = delegate

        // We persist the alert to show even if the logger might not see anymore that we crashed in a previous session
        if logger.crashedLastLaunch || alertNeedsToShow {
            logger.log("The application crashed in a previous session and need to show the restore alert",
                       level: .warning,
                       category: .tabs)
            alertNeedsToShow = true
        }
    }

    func showAlert(on viewController: Presenter,
                   alertCreator: RestoreAlertCreator = DefaultRestoreAlertCreator()) {
        guard hasTabsToRestoreAtStartup else {
            logger.log("There is no tabs to restore",
                       level: .debug,
                       category: .tabs)
            self.delegate?.needsNewTabOpened()
            return
        }

        let alert = alertCreator.restoreTabsAlert(
            okayCallback: { [weak self] in
                guard let self = self else { return }
                self.alertNeedsToShow = false
                self.logger.log("The user selected to restore tabs",
                                level: .debug,
                                category: .tabs)

                self.delegate?.needsTabRestore()
            },
            noCallback: { [weak self] in
                guard let self = self else { return }
                self.alertNeedsToShow = false
                self.logger.log("The user selected to not restore any tabs",
                                level: .debug,
                                category: .tabs)

                self.delegate?.needsNewTabOpened()
            }
        )

        logger.log("The restore tab alert will be shown",
                   level: .debug,
                   category: .tabs)
        viewController.present(alert, animated: true)
    }
}
