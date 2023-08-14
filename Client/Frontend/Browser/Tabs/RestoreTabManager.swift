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
    /// If the restore tabs is showing, we cannot do any deeplink actions since this would trigger a preserve tabs to happen
    /// which would effectively prevent the tab to be restored
    var isRestoreTabsAlertShowing: Bool { get }

    /// CrashedLastLaunch is sticky and doesn't get reset, so we need to remember its value so that we do not keep asking the user to restore their tabs
    /// But we only set this to true once the user has made his choice whether they want to restore their tabs or not, otherwise we keep showing the alert.
    var alertNeedsToShow: Bool { get }

    /// Shows the restore tab alert on the view controller. Make sure to call `alertNeedsToShow` beforehand
    /// - Parameter viewController: The view controller this alert will be presented on
    func showAlert(on viewController: UIViewController)
}

class DefaultRestoreTabManager: RestoreTabManager {
    private var logger: Logger
    private var userDefaults: UserDefaultsInterface
    private var hasTabsToRestoreAtStartup: Bool
    private var delegate: RestoreTabManagerDelegate?

    private(set) var isRestoreTabsAlertShowing = false

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

        // TODO: Laurie test + comment this
        if logger.crashedLastLaunch && !alertNeedsToShow {
            logger.log("The application crashed in a previous session and need to show the restore alert",
                       level: .warning,
                       category: .tabs)
            alertNeedsToShow = true
        }
    }

    func showAlert(on viewController: UIViewController) {
        guard hasTabsToRestoreAtStartup else {
            logger.log("There is no tabs to restore",
                       level: .debug,
                       category: .tabs)
            self.delegate?.needsNewTabOpened()
            return
        }

        let alert = UIAlertController.restoreTabsAlert(
            okayCallback: { _ in
                self.alertNeedsToShow = false
                self.isRestoreTabsAlertShowing = false
                self.logger.log("The user selected to restore tabs",
                                level: .debug,
                                category: .tabs)

                self.delegate?.needsTabRestore()
            },
            noCallback: { _ in
                self.alertNeedsToShow = false
                self.isRestoreTabsAlertShowing = false
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
        isRestoreTabsAlertShowing = true
    }
}
