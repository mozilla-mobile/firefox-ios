// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import ComponentLibrary

class PasswordManagerOnboardingViewController: SettingsViewController {
    private struct UX {
        static let fontSize: CGFloat = 19
        static let maxLabelLines: Int = 0
        static let buttonCornerRadius: CGFloat = 8
        static let defaultContentSize: CGFloat = 0
        static let leadingContentSize: CGFloat = 15
        static let standardSpacing: CGFloat = 20
        static let continueButtonHeight: CGFloat = 44
        static let buttonHorizontalPadding: CGFloat = 35
        static let continueButtonMaxWidth: CGFloat = 360
    }

    private var onboardingMessageLabel: UILabel = . build { label in
        label.text = .Settings.Passwords.OnboardingMessage
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: UX.fontSize)
        label.textAlignment = .center
        label.numberOfLines = UX.maxLabelLines
    }

    private lazy var learnMoreButton: LinkButton = .build { button in
        button.setTitle(.LoginsOnboardingLearnMoreButtonTitle, for: .normal)
        button.addTarget(self, action: #selector(self.learnMoreButtonTapped), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body, size: UX.fontSize)
    }

    private lazy var continueButton: PrimaryRoundedButton = .build { button in
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.setTitle(.LoginsOnboardingContinueButtonTitle, for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.Settings.Passwords.onboardingContinue
        button.titleLabel?.font = LegacyDynamicFontHelper().MediumSizeBoldFontAS
        button.configuration?.contentInsets = NSDirectionalEdgeInsets(top: UX.defaultContentSize,
                                                                      leading: UX.leadingContentSize,
                                                                      bottom: UX.defaultContentSize,
                                                                      trailing: UX.defaultContentSize)
        button.addTarget(self, action: #selector(self.proceedButtonTapped), for: .touchUpInside)
    }

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

        NSLayoutConstraint.activate(
            [
                onboardingMessageLabel.leadingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                    constant: UX.standardSpacing
                ),
                onboardingMessageLabel.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -UX.standardSpacing
                ),
                onboardingMessageLabel.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                onboardingMessageLabel.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),

                learnMoreButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                learnMoreButton.topAnchor.constraint(
                    equalTo: onboardingMessageLabel.safeAreaLayoutGuide.bottomAnchor,
                    constant: UX.standardSpacing
                ),

                continueButton.bottomAnchor.constraint(
                    equalTo: self.view.layoutMarginsGuide.bottomAnchor,
                    constant: -UX.standardSpacing
                ),
                continueButton.heightAnchor.constraint(equalToConstant: UX.continueButtonHeight),
                continueButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                continueButton.leadingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.leadingAnchor,
                    constant: UX.buttonHorizontalPadding,
                    priority: .defaultHigh
                ),
                continueButton.trailingAnchor.constraint(
                    equalTo: self.view.safeAreaLayoutGuide.trailingAnchor,
                    constant: -UX.buttonHorizontalPadding,
                    priority: .defaultHigh
                ),
                continueButton.widthAnchor.constraint(lessThanOrEqualToConstant: UX.continueButtonMaxWidth)
            ]
        )
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
        let currentTheme = themeManager.currentTheme.colors
        learnMoreButton.setTitleColor(currentTheme.actionPrimary, for: .normal)
        continueButton.backgroundColor = currentTheme.actionPrimary
        continueButton.applyTheme(theme: themeManager.currentTheme)
    }
}
