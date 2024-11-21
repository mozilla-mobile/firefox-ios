// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import UIKit
import ComponentLibrary

class ToSViewController: UIViewController, Themeable {
    struct UX {
        static let leftRightMargin: CGFloat = 20
        static let logoIconSize: CGFloat = 160
        static let margin: CGFloat = 20
        static let agreementContentSpacing: CGFloat = 15
    }

    // MARK: - Properties
    var windowUUID: WindowUUID
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var currentWindowUUID: UUID? { windowUUID }

    // MARK: - UI elements
    private lazy var contentScrollView: UIScrollView = .build { scrollView in
        scrollView.showsVerticalScrollIndicator = false
    }

    private lazy var contentView: UIView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.text = String(format: .Onboarding.TermsOfService.Title, AppName.shortName.rawValue)
        label.font = FXFontStyles.Regular.title1.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isAccessibilityElement = true
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var logoImage: UIImageView = .build { logoImage in
        logoImage.image = UIImage(named: ImageIdentifiers.logo)
    }

    private lazy var confirmationButton: PrimaryRoundedButton = .build { [weak self] button in
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .Onboarding.TermsOfService.AgreementButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.TermsOfService.agreeAndContinueButton)
        button.configure(viewModel: viewModel)
        button.titleLabel?.textAlignment = .center
    }

    private lazy var agreementContent: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.agreementContentSpacing
    }

    // MARK: - Initializers
    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager = AppContainer.shared.resolve(),
        notificationCenter: NotificationProtocol = NotificationCenter.default
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter
        super.init(nibName: nil, bundle: nil)

        setupLayout()
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        listenForThemeChange(view)
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - View setup
    private func setupLayout() {
        view.addSubview(contentScrollView)
        contentScrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(logoImage)
        contentView.addSubview(confirmationButton)
        contentView.addSubview(agreementContent)

        let termsOfServiceLink = String(format: .Onboarding.TermsOfService.TermsOfServiceLink, AppName.shortName.rawValue)
        let termsOfServiceAgreement = String(format: .Onboarding.TermsOfService.TermsOfServiceAgreement, termsOfServiceLink)
        setupAgreementTextView(with: termsOfServiceAgreement, and: termsOfServiceLink)

        let privacyNoticeLink = String.Onboarding.TermsOfService.PrivacyNoticeLink
        let privacyNoticeText = String.Onboarding.TermsOfService.PrivacyNoticeAgreement
        let privacyAgreement = String(format: privacyNoticeText, AppName.shortName.rawValue, privacyNoticeLink)
        setupAgreementTextView(with: privacyAgreement, and: privacyNoticeLink)

        let manageLink = String.Onboarding.TermsOfService.ManageLink
        let manageText = String.Onboarding.TermsOfService.ManagePreferenceAgreement
        let manageAgreement = String(format: manageText, AppName.shortName.rawValue, manageLink)
        setupAgreementTextView(with: manageAgreement, and: manageLink)

        let topMargin = view.frame.size.height / 3 - UX.logoIconSize - UX.margin

        NSLayoutConstraint.activate([
            contentScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
            contentView.centerXAnchor.constraint(equalTo: contentScrollView.centerXAnchor),
            contentView.widthAnchor.constraint(equalTo: contentScrollView.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: contentScrollView.heightAnchor).priority(.defaultLow),

            logoImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImage.heightAnchor.constraint(equalToConstant: UX.logoIconSize),
            logoImage.widthAnchor.constraint(equalToConstant: UX.logoIconSize),
            logoImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topMargin),

            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: logoImage.bottomAnchor, constant: UX.margin),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.leftRightMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.leftRightMargin),

            agreementContent.topAnchor.constraint(greaterThanOrEqualTo: titleLabel.bottomAnchor, constant: 2 * UX.margin),
            agreementContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.leftRightMargin),
            agreementContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.leftRightMargin),

            confirmationButton.topAnchor.constraint(equalTo: agreementContent.bottomAnchor, constant: 2 * UX.margin),
            confirmationButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2 * UX.margin),
            confirmationButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.leftRightMargin),
            confirmationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.leftRightMargin)
        ])
    }

    // TODO: FXIOS-10347 Firefox iOS: Manage Privacy Preferences during Onboarding
    private func setupAgreementTextView(with title: String, and linkTitle: String) {
        let agreementLabel: UILabel = .build()
        agreementLabel.numberOfLines = 0
        agreementLabel.textAlignment = .center
        agreementLabel.adjustsFontForContentSizeCategory = true

        let linkedAgreementDescription = NSMutableAttributedString(string: title)
        let linkedText = (title as NSString).range(of: linkTitle)
        linkedAgreementDescription.addAttribute(.font,
                                                value: FXFontStyles.Regular.caption1.scaledFont(),
                                                range: NSRange(location: 0, length: title.count))
        linkedAgreementDescription.addAttribute(.foregroundColor,
                                                value: getCurrentTheme().colors.textSecondary,
                                                range: NSRange(location: 0, length: title.count))
        linkedAgreementDescription.addAttribute(.foregroundColor,
                                                value: getCurrentTheme().colors.textAccent,
                                                range: linkedText)

        agreementLabel.attributedText = linkedAgreementDescription
        agreementContent.addArrangedSubview(agreementLabel)
    }

    // MARK: - Themable
    private func getCurrentTheme() -> Theme {
        themeManager.getCurrentTheme(for: currentWindowUUID)
    }

    func applyTheme() {
        let theme = getCurrentTheme()
        view.backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        confirmationButton.applyTheme(theme: theme)
    }
}
