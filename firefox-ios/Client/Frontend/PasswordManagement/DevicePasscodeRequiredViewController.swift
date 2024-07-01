// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import ComponentLibrary

enum ParentControllerType {
    case passwords
    case paymentMethods
}

class DevicePasscodeRequiredViewController: SettingsViewController {
    private struct UX {
        static let maxLabelLines: Int = 0
        static let standardSpacing: CGFloat = 20
    }

    private var warningLabel: UILabel = .build { label in
        label.text = .LoginsDevicePasscodeRequiredMessage
        label.font = FXFontStyles.Regular.callout.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = UX.maxLabelLines
    }

    private lazy var learnMoreButton: LinkButton = .build { button in
        button.setTitle(.LoginsDevicePasscodeRequiredLearnMoreButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(self.learnMoreButtonTapped), for: .touchUpInside)
    }

    var parentType: ParentControllerType = .passwords

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        self.view.addSubviews(warningLabel, learnMoreButton)

        NSLayoutConstraint.activate(
            [
                warningLabel.leadingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                    constant: UX.standardSpacing
                ),
                warningLabel.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -UX.standardSpacing
                ),
                warningLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                warningLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),

                learnMoreButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                learnMoreButton.topAnchor.constraint(
                    equalTo: warningLabel.safeAreaLayoutGuide.bottomAnchor,
                    constant: UX.standardSpacing
                )
            ]
        )
    }

    private func configureView() {
        switch parentType {
        case .passwords:
            self.title = .Settings.Passwords.Title
            warningLabel.text = .LoginsDevicePasscodeRequiredMessage
        case .paymentMethods:
            self.title = .SettingsAutofillCreditCard
            warningLabel.text = .PaymentMethodsDevicePasscodeRequiredMessage
        }
    }

    @objc
    func learnMoreButtonTapped(_ sender: UIButton) {
        let viewController = SettingsContentViewController(windowUUID: windowUUID)
        viewController.url = SupportUtils.URLForTopic("manage-saved-passwords-firefox-ios")
        navigationController?.pushViewController(viewController, animated: true)
    }

    override func applyTheme() {
        super.applyTheme()

        let currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        learnMoreButton.applyTheme(theme: currentTheme)
    }
}
