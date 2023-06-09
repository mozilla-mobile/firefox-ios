// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Account
import LocalAuthentication

// Show the current version of Firefox
class VersionSetting: Setting {
    unowned let settings: SettingsTableViewController

    override var accessibilityIdentifier: String? { return "FxVersion" }
    weak var appSettingsDelegate: AppSettingsDelegate?

    init(settings: SettingsTableViewController,
         appSettingsDelegate: AppSettingsDelegate) {
        self.settings = settings
        self.appSettingsDelegate = appSettingsDelegate
        super.init(title: nil)
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: "\(AppName.shortName) \(AppInfo.appVersion) (\(AppInfo.buildNumber))", attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onConfigureCell(_ cell: UITableViewCell, theme: Theme) {
        super.onConfigureCell(cell, theme: theme)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        appSettingsDelegate?.clickedVersion()
    }

    override func onLongPress(_ navigationController: UINavigationController?) {
        copyAppVersionAndPresentAlert(by: navigationController)
    }

    func copyAppVersionAndPresentAlert(by navigationController: UINavigationController?) {
        let alertTitle: String = .SettingsCopyAppVersionAlertTitle
        let alert = AlertController(title: alertTitle, message: nil, preferredStyle: .alert)
        getSelectedCell(by: navigationController)?.setSelected(false, animated: true)
        UIPasteboard.general.string = self.title?.string
        navigationController?.topViewController?.present(alert, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                alert.dismiss(animated: true)
            }
        }
    }

    func getSelectedCell(by navigationController: UINavigationController?) -> UITableViewCell? {
        let controller = navigationController?.topViewController
        let tableView = (controller as? AppSettingsTableViewController)?.tableView
        guard let indexPath = tableView?.indexPathForSelectedRow else { return nil }
        return tableView?.cellForRow(at: indexPath)
    }
}

// Opens the license page in a new tab
class LicenseAndAcknowledgementsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsLicenses, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "\(InternalURL.baseUrl)/\(AboutLicenseHandler.path)")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

// Opens the App Store review page of this app
class AppStoreReviewSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .Settings.About.RateOnAppStore, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        RatingPromptManager.goToAppStoreReview()
    }
}

// Opens about:rights page in the content view controller
class YourRightsSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsYourRights,
                                  attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/about/legal/terms/firefox/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

// Opens the on-boarding screen again
class ShowIntroductionSetting: Setting {
    let profile: Profile

    override var accessibilityIdentifier: String? { return "ShowTour" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        let attributes = [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
        super.init(title: NSAttributedString(string: .AppSettingsShowTour,
                                             attributes: attributes))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true, completion: {
            NotificationCenter.default.post(name: .PresentIntroView, object: self)

            TelemetryWrapper.recordEvent(
                category: .action,
                method: .tap,
                object: .settingsMenuShowTour
            )
        })
    }
}

class SendFeedbackSetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsSendFeedback, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "https://connect.mozilla.org/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class SendAnonymousUsageDataSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?, theme: Theme) {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: .SendUsageSettingMessage, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: .SendUsageSettingLink, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))

        super.init(
            prefs: prefs,
            prefKey: AppConstants.prefSendUsageData,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SendUsageSettingTitle),
            attributedStatusText: statusText,
            settingDidChange: {
                AdjustHelper.setEnabled($0)
                DefaultGleanWrapper.shared.setUpload(isEnabled: $0)
                Experiments.setTelemetrySetting($0)
            }
        )
        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setTelemetrySetting(prefs.boolForKey(AppConstants.prefSendUsageData) ?? true)
    }

    override var accessibilityIdentifier: String? { return "SendAnonymousUsageData" }

    override var url: URL? {
        return SupportUtils.URLForTopic("adjust")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class StudiesToggleSetting: BoolSetting {
    init(prefs: Prefs, delegate: SettingsDelegate?, theme: Theme) {
        let statusText = NSMutableAttributedString()
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleMessage, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textSecondary]))
        statusText.append(NSAttributedString(string: " "))
        statusText.append(NSAttributedString(string: .SettingsStudiesToggleLink, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.actionPrimary]))

        super.init(
            prefs: prefs,
            prefKey: AppConstants.prefStudiesToggle,
            defaultValue: true,
            attributedTitleText: NSAttributedString(string: .SettingsStudiesToggleTitle),
            attributedStatusText: statusText,
            settingDidChange: {
                Experiments.setStudiesSetting($0)
            }
        )
        // We make sure to set this on initialization, in case the setting is turned off
        // in which case, we would to make sure that users are opted out of experiments
        Experiments.setStudiesSetting(prefs.boolForKey(AppConstants.prefStudiesToggle) ?? true)
    }

    override var accessibilityIdentifier: String? { return "StudiesToggle" }

    override var url: URL? {
        return SupportUtils.URLForTopic("ios-studies")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

// Opens the SUMO page in a new tab
class OpenSupportPageSetting: Setting {
    init(delegate: SettingsDelegate?, theme: Theme) {
        super.init(title: NSAttributedString(string: .AppSettingsHelp, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]),
                   delegate: delegate)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        navigationController?.dismiss(animated: true) {
            if let url = URL(string: "https://support.mozilla.org/products/ios") {
                self.delegate?.settingsOpenURLInNewTab(url)
            }
        }
    }
}

class LoginsSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    private let appAuthenticator: AppAuthenticationProtocol
    weak var navigationController: UINavigationController?
    weak var settings: AppSettingsTableViewController?

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "Logins" }

    init(settings: SettingsTableViewController,
         delegate: SettingsDelegate?,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        self.appAuthenticator = appAuthenticator
        self.navigationController = settings.navigationController
        self.settings = settings as? AppSettingsTableViewController

        super.init(
            title: NSAttributedString(
                string: .Settings.Passwords.Title,
                attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
            ),
            delegate: delegate
        )
    }

    func deselectRow () {
        if let selectedRow = self.settings?.tableView.indexPathForSelectedRow {
            self.settings?.tableView.deselectRow(at: selectedRow, animated: true)
        }
    }

    override func onClick(_: UINavigationController?) {
        deselectRow()

        guard let navController = navigationController else { return }
        let navigationHandler: (_ url: URL?) -> Void = { url in
            guard let url = url else { return }
            UIWindow.keyWindow?.rootViewController?.dismiss(animated: true, completion: nil)
            self.delegate?.settingsOpenURLInNewTab(url)
        }

        if appAuthenticator.canAuthenticateDeviceOwner() {
            if LoginOnboarding.shouldShow() {
                let loginOnboardingViewController = LoginOnboardingViewController(profile: profile, tabManager: tabManager)

                loginOnboardingViewController.doneHandler = {
                    loginOnboardingViewController.dismiss(animated: true)
                }

                loginOnboardingViewController.proceedHandler = {
                    LoginListViewController.create(
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
                LoginListViewController.create(
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

class ContentBlockerSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }
    override var accessibilityIdentifier: String? { return "TrackingProtection" }

    override var status: NSAttributedString? {
        let isOn = profile.prefs.boolForKey(ContentBlockingConfig.Prefs.EnabledKey) ?? ContentBlockingConfig.Defaults.NormalBrowsing

        if isOn {
            let currentBlockingStrength = profile
                .prefs
                .stringForKey(ContentBlockingConfig.Prefs.StrengthKey)
                .flatMap(BlockingStrength.init(rawValue:)) ?? .basic
            return NSAttributedString(string: currentBlockingStrength.settingStatus)
        } else {
            return NSAttributedString(string: .Settings.Homepage.Shortcuts.ToggleOff)
        }
    }

    override var style: UITableViewCell.CellStyle { return .value1 }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager
        super.init(title: NSAttributedString(string: .SettingsTrackingProtectionSectionName, attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = ContentBlockerSettingViewController(prefs: profile.prefs)
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class ClearPrivateDataSetting: Setting {
    let profile: Profile
    var tabManager: TabManager!

    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return "ClearPrivateData" }

    init(settings: SettingsTableViewController) {
        self.profile = settings.profile
        self.tabManager = settings.tabManager

        let clearTitle: String = .SettingsDataManagementSectionName
        super.init(title: NSAttributedString(string: clearTitle, attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = ClearPrivateDataTableViewController()
        viewController.profile = profile
        viewController.tabManager = tabManager
        navigationController?.pushViewController(viewController, animated: true)
    }
}

class AutofillCreditCardSettings: Setting, FeatureFlaggable {
    private let profile: Profile
    private let appAuthenticator: AppAuthenticationProtocol
    weak var navigationController: UINavigationController?
    weak var settings: AppSettingsTableViewController?
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }
    override var accessibilityIdentifier: String? { return "AutofillCreditCard" }

    init(settings: SettingsTableViewController,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()) {
        self.profile = settings.profile
        self.appAuthenticator = appAuthenticator
        self.navigationController = settings.navigationController
        self.settings = settings as? AppSettingsTableViewController

        super.init(
            title: NSAttributedString(
                string: .SettingsAutofillCreditCard,
                attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardAutofillSettings)
        let viewModel = CreditCardSettingsViewModel(profile: profile)
        let viewController = CreditCardSettingsViewController(
            creditCardViewModel: viewModel)

        guard let navController = navigationController else { return }
        if appAuthenticator.canAuthenticateDeviceOwner() {
            AppAuthenticator().authenticateWithDeviceOwnerAuthentication { result in
                switch result {
                case .success:
                    navController.pushViewController(viewController,
                                                     animated: true)
                case .failure:
                    viewController.dismissVC()
                }
            }
        } else {
            let passcodeViewController = DevicePasscodeRequiredViewController()
            passcodeViewController.profile = profile
            navController.pushViewController(passcodeViewController,
                                             animated: true)
        }
    }
}

class PrivacyPolicySetting: Setting {
    override var title: NSAttributedString? {
        return NSAttributedString(string: .AppSettingsPrivacyPolicy, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary])
    }

    override var url: URL? {
        return URL(string: "https://www.mozilla.org/privacy/firefox/")
    }

    override func onClick(_ navigationController: UINavigationController?) {
        setUpAndPushSettingsContentViewController(navigationController, self.url)
    }
}

class NotificationsSetting: Setting {
    override var accessoryView: UIImageView? { return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme) }

    override var accessibilityIdentifier: String? { return AccessibilityIdentifiers.Setting.notifications }

    let profile: Profile

    init(theme: Theme, profile: Profile) {
        self.profile = profile
        super.init(title: NSAttributedString(string: .Settings.Notifications.Title,
                                             attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]))
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let viewController = NotificationsSettingsViewController(prefs: profile.prefs, hasAccount: profile.hasAccount())
        navigationController?.pushViewController(viewController, animated: true)
    }
}
