// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class PasswordManagerSetting: Setting {
    private weak var settingsDelegate: PrivacySettingsDelegate?
    private let profile: Profile
    private var tabManager: TabManager!
    private let appAuthenticator: AppAuthenticationProtocol
    private weak var navigationController: UINavigationController?
    private weak var settings: AppSettingsTableViewController?

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Logins.title
    }

    init(settings: SettingsTableViewController,
         settingsDelegate: PrivacySettingsDelegate?,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        self.appAuthenticator = appAuthenticator
        self.navigationController = settings.navigationController
        self.settings = settings as? AppSettingsTableViewController
        self.settingsDelegate = settingsDelegate

        super.init(
            title: NSAttributedString(
                string: .Settings.Passwords.Title,
                attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
            )
        )
    }

    func deselectRow () {
        if let selectedRow = self.settings?.tableView.indexPathForSelectedRow {
            self.settings?.tableView.deselectRow(at: selectedRow, animated: true)
        }
    }

    override func onClick(_: UINavigationController?) {
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedPasswords()
            return
        }

        deselectRow()

        guard let navController = navigationController else { return }
        let navigationHandler: (_ url: URL?) -> Void = { url in
            guard let url = url else { return }
            UIWindow.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
            self.delegate?.settingsOpenURLInNewTab(url)
        }

        if appAuthenticator.canAuthenticateDeviceOwner {
            if LoginOnboarding.shouldShow() {
                let loginOnboardingViewController = PasswordManagerOnboardingViewController(
                    profile: profile,
                    tabManager: tabManager
                )

                loginOnboardingViewController.doneHandler = {
                    loginOnboardingViewController.dismiss(animated: true)
                }

                loginOnboardingViewController.proceedHandler = {
                    PasswordManagerListViewController.create(
                        didShowFromAppMenu: false,
                        authenticateInNavigationController: navController,
                        profile: self.profile,
                        webpageNavigationHandler: navigationHandler
                    ) { loginsVC in
                        guard let loginsVC = loginsVC else { return }
                        navController.pushViewController(loginsVC, animated: true)
                        // Remove the onboarding from the navigation stack so that we go straight back to settings
                        navController.viewControllers.removeAll { viewController in
                            viewController == loginOnboardingViewController
                        }
                    }
                }

                navigationController?.pushViewController(loginOnboardingViewController, animated: true)

                LoginOnboarding.setShown()
            } else {
                PasswordManagerListViewController.create(
                    didShowFromAppMenu: false,
                    authenticateInNavigationController: navController,
                    profile: profile,
                    webpageNavigationHandler: navigationHandler
                ) { loginsVC in
                    guard let loginsVC = loginsVC else { return }
                    navController.pushViewController(loginsVC, animated: true)
                }
            }
        } else {
            let viewController = DevicePasscodeRequiredViewController()
            viewController.profile = profile
            viewController.tabManager = tabManager
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
}
