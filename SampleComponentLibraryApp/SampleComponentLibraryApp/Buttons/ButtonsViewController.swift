// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import UIKit

class ButtonsViewController: UIViewController, Themeable {
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    private lazy var primaryButton: PrimaryRoundedButton = .build { _ in }
    private lazy var primaryButtonDisabled: PrimaryRoundedButton = .build { _ in }
    private lazy var secondaryButton: SecondaryRoundedButton = .build { _ in }
    private lazy var linkButton: LinkButton = .build { _ in }
    private lazy var closeButton: CloseButton = .build { _ in }
    private lazy var enabledOnSwitch: PaddedSwitch = .build { _ in }
    private lazy var enabledOffSwitch: PaddedSwitch = .build { _ in }
    private lazy var disabledOnSwitch: PaddedSwitch = .build { _ in }
    private lazy var disabledOffSwitch: PaddedSwitch = .build { _ in }

    private lazy var buttonStackView: UIStackView = .build { stackView in
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.axis = .vertical
        stackView.spacing = 16
    }

    private lazy var offSwitchView: UIView = .build { _ in }

    private lazy var onSwitchView: UIView = .build { _ in }

    init(themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.themeManager = themeManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
        applyTheme()

        setupView()

        let primaryViewModel = PrimaryRoundedButtonViewModel(title: "Primary",
                                                             a11yIdentifier: "a11yPrimary")
        primaryButton.configure(viewModel: primaryViewModel)

        let primaryViewModelDisabled = PrimaryRoundedButtonViewModel(
            title: "Primary Disabled",
            a11yIdentifier: "a11yPrimaryDisabled"
        )
        primaryButtonDisabled.configure(viewModel: primaryViewModelDisabled)
        primaryButtonDisabled.isEnabled = false

        let secondaryViewModel = SecondaryRoundedButtonViewModel(title: "Secondary",
                                                                 a11yIdentifier: "a11ySecondary")
        secondaryButton.configure(viewModel: secondaryViewModel)

        let linkButtonViewModel = LinkButtonViewModel(title: "This is a link",
                                                      a11yIdentifier: "a11yLink")
        linkButton.configure(viewModel: linkButtonViewModel)

        let closeButtonViewModel = CloseButtonViewModel(
            a11yLabel: "This is a close button",
            a11yIdentifier: "a11yCloseButton")
        closeButton.configure(viewModel: closeButtonViewModel)

        let paddedSwitchViewModelOnEnabled = PaddedSwitchViewModel(theme: themeManager.currentTheme,
                                                                   isEnabled: true,
                                                                   isOn: true,
                                                                   a11yIdentifier: "paddedSwitchOnEnabled",
                                                                   valueChangedClosure: {})
        enabledOnSwitch.configure(with: paddedSwitchViewModelOnEnabled)

        let paddedSwitchViewModelOffEnabled = PaddedSwitchViewModel(theme: themeManager.currentTheme,
                                                                    isEnabled: true,
                                                                    isOn: false,
                                                                    a11yIdentifier: "paddedSwitchOffEnabled",
                                                                    valueChangedClosure: {})
        enabledOffSwitch.configure(with: paddedSwitchViewModelOffEnabled)

        let paddedSwitchViewModelOnDisabled = PaddedSwitchViewModel(theme: themeManager.currentTheme,
                                                                    isEnabled: false,
                                                                    isOn: true,
                                                                    a11yIdentifier: "paddedSwitchOnDisabled",
                                                                    valueChangedClosure: {})
        disabledOnSwitch.configure(with: paddedSwitchViewModelOnDisabled)

        let paddedSwitchViewModelOffDisabled = PaddedSwitchViewModel(theme: themeManager.currentTheme,
                                                                     isEnabled: false,
                                                                     isOn: false,
                                                                     a11yIdentifier: "paddedSwitchOffDisabled",
                                                                     valueChangedClosure: {})
        disabledOffSwitch.configure(with: paddedSwitchViewModelOffDisabled)

        primaryButton.applyTheme(theme: themeManager.currentTheme)
        primaryButtonDisabled.applyTheme(theme: themeManager.currentTheme)
        secondaryButton.applyTheme(theme: themeManager.currentTheme)
        linkButton.applyTheme(theme: themeManager.currentTheme)
    }

    private func setupView() {
        view.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(primaryButton)
        buttonStackView.addArrangedSubview(primaryButtonDisabled)
        buttonStackView.addArrangedSubview(secondaryButton)
        buttonStackView.addArrangedSubview(linkButton)
        buttonStackView.addArrangedSubview(closeButton)

        buttonStackView.addArrangedSubview(offSwitchView)
        offSwitchView.addSubview(enabledOffSwitch)
        offSwitchView.addSubview(disabledOffSwitch)

        buttonStackView.addArrangedSubview(onSwitchView)
        onSwitchView.addSubview(enabledOnSwitch)
        onSwitchView.addSubview(disabledOnSwitch)

        NSLayoutConstraint.activate([
            buttonStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            buttonStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            buttonStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            enabledOffSwitch.leadingAnchor.constraint(equalTo: offSwitchView.leadingAnchor, constant: 0),
            enabledOffSwitch.topAnchor.constraint(equalTo: offSwitchView.topAnchor, constant: 0),
            enabledOffSwitch.bottomAnchor.constraint(equalTo: offSwitchView.bottomAnchor, constant: 0),
            disabledOffSwitch.leadingAnchor.constraint(equalTo: enabledOffSwitch.trailingAnchor, constant: 24),
            disabledOffSwitch.topAnchor.constraint(equalTo: offSwitchView.topAnchor, constant: 0),
            disabledOffSwitch.bottomAnchor.constraint(equalTo: offSwitchView.bottomAnchor, constant: 0),
            disabledOffSwitch.trailingAnchor.constraint(lessThanOrEqualTo: offSwitchView.trailingAnchor),

            enabledOnSwitch.leadingAnchor.constraint(equalTo: onSwitchView.leadingAnchor, constant: 0),
            enabledOnSwitch.topAnchor.constraint(equalTo: onSwitchView.topAnchor, constant: 0),
            enabledOnSwitch.bottomAnchor.constraint(equalTo: onSwitchView.bottomAnchor, constant: 0),
            disabledOnSwitch.leadingAnchor.constraint(equalTo: enabledOnSwitch.trailingAnchor, constant: 24),
            disabledOnSwitch.topAnchor.constraint(equalTo: onSwitchView.topAnchor, constant: 0),
            disabledOnSwitch.bottomAnchor.constraint(equalTo: onSwitchView.bottomAnchor, constant: 0),
            disabledOnSwitch.trailingAnchor.constraint(lessThanOrEqualTo: onSwitchView.trailingAnchor)
        ])
    }

    // MARK: Themeable

    func applyTheme() {
        view.backgroundColor = themeManager.currentTheme.colors.layer1
        buttonStackView.backgroundColor = .clear
    }
}
