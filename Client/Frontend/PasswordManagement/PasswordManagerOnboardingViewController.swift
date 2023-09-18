// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class PasswordManagerOnboardingViewController: SettingsViewController {
    private var onboardingMessageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = .Settings.Passwords.OnboardingMessage
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 19)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var learnMoreButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(.LoginsOnboardingLearnMoreButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(learnMoreButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: 19)
        return button
    }()

    private lazy var continueButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.layer.cornerRadius = 8
        button.setTitle(.LoginsOnboardingContinueButtonTitle, for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Passwords.onboardingContinue
        button.titleLabel?.font = LegacyDynamicFontHelper().MediumSizeBoldFontAS
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(proceedButtonTapped), for: .touchUpInside)
        return button
    }()

    weak var coordinator: PasswordManagerFlowDelegate?
    private var appAuthenticator: AppAuthenticationProtocol

    init(profile: Profile? = nil,
         tabManager: TabManager? = nil,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()) {
        self.appAuthenticator = appAuthenticator
        super.init(profile: profile, tabManager: tabManager)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = .Settings.Passwords.Title

        self.view.addSubviews(onboardingMessageLabel, learnMoreButton, continueButton)

        NSLayoutConstraint.activate([
            onboardingMessageLabel.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            onboardingMessageLabel.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            onboardingMessageLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            onboardingMessageLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),

            learnMoreButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            learnMoreButton.topAnchor.constraint(equalTo: onboardingMessageLabel.safeAreaLayoutGuide.bottomAnchor, constant: 20),

            continueButton.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor, constant: -20),
            continueButton.heightAnchor.constraint(equalToConstant: 44),
            continueButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            continueButton.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor, constant: 35, priority: .defaultHigh),
            continueButton.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor, constant: -35, priority: .defaultHigh),
            continueButton.widthAnchor.constraint(lessThanOrEqualToConstant: 360)
        ])
    }

    @objc
    func learnMoreButtonTapped(_ sender: UIButton) {
        let viewController = SettingsContentViewController()
        viewController.url = SupportUtils.URLForTopic("set-passcode-and-touch-id-firefox")
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc
    func proceedButtonTapped(_ sender: UIButton) {
        continueFromOnboarding()
    }

    private func continueFromOnboarding() {
        appAuthenticator.getAuthenticationState { state in
            switch state {
            case .deviceOwnerAuthenticated:
                self.coordinator?.continueFromOnboarding()
            case .deviceOwnerFailed:
                break // Keep showing the main settings page
            case .passCodeRequired:
                self.coordinator?.showDevicePassCode()
            }
        }
    }

    override func applyTheme() {
        super.applyTheme()
        continueButton.backgroundColor = themeManager.currentTheme.colors.actionPrimary
    }
}
