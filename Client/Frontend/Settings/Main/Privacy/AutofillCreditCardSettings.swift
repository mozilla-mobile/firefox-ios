// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class AutofillCreditCardSettings: Setting, FeatureFlaggable {
    private weak var settingsDelegate: PrivacySettingsDelegate?
    private let profile: Profile
    private let appAuthenticator: AppAuthenticationProtocol
    weak var navigationController: UINavigationController?
    weak var settings: AppSettingsTableViewController?

    override var accessoryView: UIImageView? {
        return SettingDisclosureUtility.buildDisclosureIndicator(theme: theme)
    }

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.CreditCard.title
    }

    init(settings: SettingsTableViewController,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator(),
         settingsDelegate: PrivacySettingsDelegate?) {
        self.profile = settings.profile
        self.appAuthenticator = appAuthenticator
        self.navigationController = settings.navigationController
        self.settings = settings as? AppSettingsTableViewController
        self.settingsDelegate = settingsDelegate

        super.init(
            title: NSAttributedString(
                string: .SettingsAutofillCreditCard,
                attributes: [NSAttributedString.Key.foregroundColor: settings.themeManager.currentTheme.colors.textPrimary]
            )
        )
    }

    override func onClick(_ navigationController: UINavigationController?) {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .creditCardAutofillSettings)
        if CoordinatorFlagManager.isSettingsCoordinatorEnabled {
            settingsDelegate?.pressedCreditCard()
            return
        }

        let viewModel = CreditCardSettingsViewModel(profile: profile)
        let viewController = CreditCardSettingsViewController(creditCardViewModel: viewModel)

        guard let navController = navigationController else { return }
        if appAuthenticator.canAuthenticateDeviceOwner {
            appAuthenticator.authenticateWithDeviceOwnerAuthentication { result in
                switch result {
                case .success:
                    navController.pushViewController(viewController,
                                                     animated: true)
                case .failure:
                    break
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
