// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import ComponentLibrary

class PasswordManagerOnboardingViewController: SettingsViewController {
    private struct UX {
        static let maxLabelLines: Int = 0
        static let standardSpacing: CGFloat = 20
        static let buttonHorizontalPadding: CGFloat = 35
        static let continueButtonMaxWidth: CGFloat = 360
    }

    private var onboardingMessageLabel: UILabel = . build { label in
        label.text = .Settings.Passwords.OnboardingMessage
        label.font = FXFontStyles.Regular.callout.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = UX.maxLabelLines
    }

    private lazy var learnMoreButton: LinkButton = .build { button in
        let buttonViewModel = LinkButtonViewModel(
            title: .LoginsOnboardingLearnMoreButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.Settings.Passwords.onboardingLearnMore)
        button.configure(viewModel: buttonViewModel)
        button.addTarget(self, action: #selector(self.learnMoreButtonTapped), for: .touchUpInside)
    }

    private lazy var continueButton: PrimaryRoundedButton = .build { button in
        let buttonViewModel = PrimaryRoundedButtonViewModel(
            title: .LoginsOnboardingContinueButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.Settings.Passwords.onboardingContinue)
        button.configure(viewModel: buttonViewModel)
        button.addTarget(self, action: #selector(self.proceedButtonTapped), for: .touchUpInside)
    }

    private lazy var contentView: UIView = .build()

    private lazy var scrollView: UIScrollView = .build()

    private lazy var infoContainer: UIView = .build()

    weak var coordinator: PasswordManagerFlowDelegate?
    private var appAuthenticator: AppAuthenticationProtocol

    init(profile: Profile? = nil,
         tabManager: TabManager? = nil,
         windowUUID: WindowUUID,
         appAuthenticator: AppAuthenticationProtocol = AppAuthenticator()) {
        self.appAuthenticator = appAuthenticator
        super.init(windowUUID: windowUUID, profile: profile, tabManager: tabManager)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = .Settings.Passwords.Title

        setupLayout()
    }

    @objc
    func learnMoreButtonTapped(_ sender: UIButton) {
        let viewController = SettingsContentViewController(windowUUID: windowUUID)
        viewController.url = SupportUtils.URLForTopic("set-passcode-and-touch-id-firefox")
        navigationController?.pushViewController(viewController, animated: true)
    }

    @objc
    func proceedButtonTapped(_ sender: UIButton) {
        continueFromOnboarding()
    }

    private func setupLayout() {
        view.addSubviews(scrollView)

        scrollView.addSubview(contentView)
        infoContainer.addSubviews(onboardingMessageLabel, learnMoreButton)
        contentView.addSubviews(infoContainer, continueButton)

        NSLayoutConstraint.activate(
            [
                scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

                contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
                contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.frameLayoutGuide.heightAnchor),

                infoContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                infoContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                infoContainer.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor),
                infoContainer.centerYAnchor.constraint(
                    equalTo: contentView.centerYAnchor,
                    constant: -continueButton.frame.height - UX.standardSpacing,
                    priority: .defaultLow
                ),

                onboardingMessageLabel.leadingAnchor.constraint(
                    equalTo: infoContainer.leadingAnchor,
                    constant: UX.standardSpacing
                ),
                onboardingMessageLabel.trailingAnchor.constraint(
                    equalTo: infoContainer.trailingAnchor,
                    constant: -UX.standardSpacing
                ),
                onboardingMessageLabel.topAnchor.constraint(
                    equalTo: infoContainer.topAnchor,
                    constant: UX.standardSpacing
                ),

                learnMoreButton.centerXAnchor.constraint(
                    equalTo: infoContainer.centerXAnchor
                ),
                learnMoreButton.topAnchor.constraint(
                    equalTo: onboardingMessageLabel.bottomAnchor,
                    constant: UX.standardSpacing
                ),
                learnMoreButton.leadingAnchor.constraint(
                    greaterThanOrEqualTo: infoContainer.leadingAnchor,
                    constant: UX.buttonHorizontalPadding
                ),
                learnMoreButton.bottomAnchor.constraint(equalTo: infoContainer.bottomAnchor),
                learnMoreButton.trailingAnchor.constraint(
                    lessThanOrEqualTo: infoContainer.trailingAnchor,
                    constant: -UX.buttonHorizontalPadding
                ),

                continueButton.leadingAnchor.constraint(
                    equalTo: contentView.leadingAnchor,
                    constant: UX.buttonHorizontalPadding
                ),
                continueButton.trailingAnchor.constraint(
                    equalTo: contentView.trailingAnchor,
                    constant: -UX.buttonHorizontalPadding
                ),
                continueButton.centerXAnchor.constraint(
                    equalTo: contentView.centerXAnchor
                ),
                continueButton.widthAnchor.constraint(
                    lessThanOrEqualToConstant: UX.continueButtonMaxWidth
                ),
                continueButton.bottomAnchor.constraint(
                     equalTo: contentView.bottomAnchor,
                     constant: -UX.standardSpacing
                ),
                continueButton.topAnchor.constraint(
                    greaterThanOrEqualTo: infoContainer.bottomAnchor,
                    constant: UX.standardSpacing
                ),
            ])
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

        let currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        learnMoreButton.applyTheme(theme: currentTheme)
        continueButton.applyTheme(theme: currentTheme)
    }
}
