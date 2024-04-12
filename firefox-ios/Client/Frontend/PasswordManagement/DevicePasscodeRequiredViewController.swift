// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

enum ParentControllerType {
    case passwords
    case paymentMethods
}

class DevicePasscodeRequiredViewController: SettingsViewController {
    private var warningLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 17)
        label.text = .LoginsDevicePasscodeRequiredMessage
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var learnMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.LoginsDevicePasscodeRequiredLearnMoreButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(learnMoreButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 19)
        return button
    }()

    var parentType: ParentControllerType = .passwords

    override func viewDidLoad() {
        super.viewDidLoad()

        configureView()
        self.view.addSubviews(warningLabel, learnMoreButton)

        NSLayoutConstraint.activate(
            [
                warningLabel.leadingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                    constant: 20
                ),
                warningLabel.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -20
                ),
                warningLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                warningLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),

                learnMoreButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                learnMoreButton.topAnchor.constraint(
                    equalTo: warningLabel.safeAreaLayoutGuide.bottomAnchor,
                    constant: 20
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
}
