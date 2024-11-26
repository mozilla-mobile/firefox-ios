// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

protocol CredentialWelcomeViewControllerDelegate: AnyObject {
    func credentialWelcomeViewControllerDidCancel()
    func credentialWelcomeViewControllerDidProceed()
}

class CredentialWelcomeViewController: UIViewController {
    weak var delegate: CredentialWelcomeViewControllerDelegate?

    private lazy var logoImageView: UIImageView = {
        let image = UIImageView(image: UIImage(named: "logo-glyph"))
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .LoginsWelcomeViewTitle2
        label.font = UIFont.systemFont(ofSize: 32, weight: .bold)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var taglineLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .LoginsWelcomeViewTagline
        label.font = UIFont.systemFont(ofSize: 20)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.CancelString, for: .normal)
        button.addTarget(self, action: #selector(self.cancelButtonTapped(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var proceedButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.Photon.Blue50
        button.layer.cornerRadius = 8
        button.setTitle(String.LoginsWelcomeTurnOnAutoFillButtonTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        button.addTarget(self, action: #selector(proceedButtonTapped), for: .touchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.CredentialProvider.welcomeScreenBackgroundColor

        view.addSubviews(cancelButton, logoImageView, titleLabel, taglineLabel, proceedButton)

        NSLayoutConstraint.activate(
            [
                cancelButton.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 10),
                cancelButton.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -20
                ),

                logoImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                logoImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor, multiplier: 0.4),

                titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 40),
                titleLabel.centerXAnchor.constraint(
                    equalTo: self.view.centerXAnchor
                ),
                titleLabel.leadingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                    constant: 35,
                    priority: .defaultHigh
                ),
                titleLabel.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -35,
                    priority: .defaultHigh
                ),
                titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 440),

                taglineLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
                taglineLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                taglineLabel.leadingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                    constant: 35,
                    priority: .defaultHigh
                ),
                taglineLabel.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -35,
                    priority: .defaultHigh
                ),
                taglineLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 440),

                proceedButton.bottomAnchor.constraint(
                    equalTo: self.view.layoutMarginsGuide.bottomAnchor,
                    constant: -20
                ),
                proceedButton.heightAnchor.constraint(equalToConstant: 44),
                proceedButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                proceedButton.leadingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                    constant: 35,
                    priority: .defaultHigh
                ),
                proceedButton.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -35,
                    priority: .defaultHigh
                ),
                proceedButton.widthAnchor.constraint(lessThanOrEqualToConstant: 360)
            ]
        )
    }

    @objc
    func cancelButtonTapped(_ sender: UIButton) {
        delegate?.credentialWelcomeViewControllerDidCancel()
    }

    @objc
    func proceedButtonTapped(_ sender: UIButton) {
        delegate?.credentialWelcomeViewControllerDidProceed()
    }
}
