// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

// MARK: - AddressAutofillSettingsViewController
class AddressAutofillSettingsViewController: SensitiveViewController, Themeable {
    // MARK: Properties

    // ViewModel for managing address autofill settings
    var viewModel: AddressAutofillSettingsViewModel

    // Observer for theme changes
    var themeObserver: NSObjectProtocol?

    // Manager responsible for handling themes
    var themeManager: ThemeManager

    // NotificationCenter for handling notifications
    var notificationCenter: NotificationProtocol

    // Logger for logging messages and events
    private let logger: Logger

    // MARK: Initializers

    /// Initialize the AddressAutofillSettingsViewController.
    /// - Parameters:
    ///   - addressAutofillViewModel: The ViewModel for address autofill settings.
    ///   - themeManager: The ThemeManager for managing app themes.
    ///   - notificationCenter: The NotificationCenter for handling notifications.
    ///   - logger: The Logger for logging messages and events.
    init(addressAutofillViewModel: AddressAutofillSettingsViewModel,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared) {
        self.viewModel = addressAutofillViewModel
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger
        // ... initialize other dependencies
        super.init(nibName: nil, bundle: nil)
    }

    /// Not implemented for this view controller. Raises a fatal error.
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    /// Called after the controller's view is loaded into memory.
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        applyTheme()
    }

    // MARK: Themeable Protocol

    /// Applies the current theme to the view.
    func applyTheme() {
        let theme = themeManager.currentTheme
        view.backgroundColor = theme.colors.layer1
    }
}
