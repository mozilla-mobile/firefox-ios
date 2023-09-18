// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = .Settings.Passwords.Title

        self.view.addSubviews(warningLabel, learnMoreButton)

        NSLayoutConstraint.activate([
            warningLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            warningLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            warningLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),

            learnMoreButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            learnMoreButton.topAnchor.constraint(equalTo: warningLabel.safeAreaLayoutGuide.bottomAnchor, constant: 20)
        ])
    }

    @objc
    func learnMoreButtonTapped(_ sender: UIButton) {
        let viewController = SettingsContentViewController()
        viewController.url = SupportUtils.URLForTopic("manage-saved-passwords-firefox-ios")
        navigationController?.pushViewController(viewController, animated: true)
    }
}
