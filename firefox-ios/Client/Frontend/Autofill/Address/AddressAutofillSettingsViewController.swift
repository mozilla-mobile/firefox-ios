// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import SwiftUI

// MARK: - AddressAutofillSettingsViewController

/// View controller responsible for managing address autofill settings.
class AddressAutofillSettingsViewController: SensitiveViewController, Themeable {
    // MARK: Properties

    /// ViewModel for handling address autofill settings.
    var viewModel: AddressAutofillSettingsViewModel

    /// Observer for theme changes.
    var themeObserver: NSObjectProtocol?

    /// Manager responsible for handling themes.
    var themeManager: ThemeManager

    /// NotificationCenter for handling notifications.
    var notificationCenter: NotificationProtocol

    /// Logger for logging messages and events.
    private let logger: Logger

    let windowUUID: WindowUUID
    var currentWindowUUID: UUID? { return windowUUID }

    // MARK: Views

    /// Hosting controller for the empty state view in address autofill settings.
    var addressAutofillSettingsPageView: UIHostingController<AddressAutofillSettingsView>

    private lazy var addAddressButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus),
                                     style: .plain,
                                     target: self,
                                     action: #selector(addAddress))
        button.accessibilityLabel = .Addresses.Settings.Edit.AutofillAddAddressTitle
        return button
    }()

    // MARK: Initializers

    /// Initializes the AddressAutofillSettingsViewController.
    /// - Parameters:
    ///   - addressAutofillViewModel: The ViewModel for address autofill settings.
    ///   - themeManager: The ThemeManager for managing app themes.
    ///   - notificationCenter: The NotificationCenter for handling notifications.
    ///   - logger: The Logger for logging messages and events.
    init(addressAutofillViewModel: AddressAutofillSettingsViewModel,
         windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationCenter = NotificationCenter.default,
         logger: Logger = DefaultLogger.shared) {
        self.viewModel = addressAutofillViewModel
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        self.logger = logger

        // Initialize the AddressAutofillSettingsView and its hosting controller
        let addressAutofillSettingsVC = AddressAutofillSettingsView(
            windowUUID: windowUUID,
            toggleModel: viewModel.toggleModel,
            addressListViewModel: viewModel.addressListViewModel)
        self.addressAutofillSettingsPageView = UIHostingController(rootView: addressAutofillSettingsVC)

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
        setupView()
        listenForThemeChange(view)
        applyTheme()
        viewModel.addressListViewModel.presentToast = { [weak self] status in
            guard let self else { return }
            switch status {
            case let .error(errorType):
                ActionToast(
                    text: errorType.message,
                    bottomContainer: view,
                    theme: themeManager.getCurrentTheme(for: windowUUID),
                    buttonTitle: errorType.actionTitle,
                    buttonAction: errorType.action
                ).show()
            default:
                SimpleToast().showAlertWithText(
                    status.message,
                    bottomContainer: view,
                    theme: themeManager.getCurrentTheme(for: windowUUID)
                )
            }
        }
    }

    // MARK: View Setup

    /// Sets up the view hierarchy and initial configurations.
    func setupView() {
        if viewModel.addressListViewModel.isEditingFeatureEnabled {
            navigationItem.rightBarButtonItem = addAddressButton
        }

        guard let emptyAddressAutofillView = addressAutofillSettingsPageView.view else { return }
        emptyAddressAutofillView.translatesAutoresizingMaskIntoConstraints = false

        addChild(addressAutofillSettingsPageView)
        view.addSubview(emptyAddressAutofillView)
        self.title = .SettingsAddressAutofill

        NSLayoutConstraint.activate([
            emptyAddressAutofillView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyAddressAutofillView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyAddressAutofillView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyAddressAutofillView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
    }

    // MARK: Themeable Protocol

    /// Applies the current theme to the view.
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer1
    }

    @objc
    func addAddress() {
        self.viewModel.addressListViewModel.addAddressButtonTap()
    }

    deinit {
        addressAutofillSettingsPageView.removeFromParent()
        addressAutofillSettingsPageView.view.removeFromSuperview()
    }
}
