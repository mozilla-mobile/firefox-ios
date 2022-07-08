// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Shared

protocol CredentialPasscodeRequirementViewControllerDelegate: AnyObject {
    func credentialPasscodeRequirementViewControllerDidDismiss()
}

class CredentialPasscodeRequirementViewController: UIViewController {
    var delegate: CredentialPasscodeRequirementViewControllerDelegate?

    lazy private var logoImageView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "logo-glyph"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    lazy private var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .LoginsWelcomeViewTitle2
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    lazy private var taglineLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .LoginsWelcomeViewTagline
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    lazy private var warningLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 18)
        label.text = .LoginsPasscodeRequirementWarning
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    lazy private var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .systemRed
        button.layer.cornerRadius = 8
        button.setTitle(.CancelString, for: .normal)
        button.titleLabel?.font = DynamicFontHelper().MediumSizeBoldFontAS
        button.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.CredentialProvider.welcomeScreenBackgroundColor

        view.addSubviews(logoImageView, titleLabel, taglineLabel, warningLabel, cancelButton)

        NSLayoutConstraint.activate([
            logoImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            logoImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, multiplier: 0.4),

            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 35, priority: .defaultHigh),
            titleLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -35, priority: .defaultHigh),
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 440),

            taglineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            taglineLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            taglineLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 35, priority: .defaultHigh),
            taglineLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -35, priority: .defaultHigh),
            taglineLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 440),

            warningLabel.topAnchor.constraint(equalTo: taglineLabel.bottomAnchor, constant: 20),
            warningLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            warningLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 35, priority: .defaultHigh),
            warningLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -35, priority: .defaultHigh),
            warningLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 440),

            cancelButton.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -20),
            cancelButton.heightAnchor.constraint(equalToConstant: 44),
            cancelButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            cancelButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 35, priority: .defaultHigh),
            cancelButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -35, priority: .defaultHigh),
            cancelButton.widthAnchor.constraint(lessThanOrEqualToConstant: 360)
        ])
    }

    @objc func cancelButtonTapped(_ sender: UIButton) {
        delegate?.credentialPasscodeRequirementViewControllerDidDismiss()
    }
}
