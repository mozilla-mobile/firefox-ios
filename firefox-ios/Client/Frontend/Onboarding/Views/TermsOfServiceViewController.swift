// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit
import ComponentLibrary

class TermsOfServiceViewController: UIViewController, Themeable {
	enum LinkType: Int {
		case termsOfService
		case privacyNotice
		case manage
	}

    struct UX {
        static let horizontalMargin: CGFloat = 24
        static let logoIconSize: CGFloat = 160
        static let margin: CGFloat = 20
        static let agreementContentSpacing: CGFloat = 15
        static let distanceBetweenViews = 2 * margin
    }

    struct Links {
        static let termsOfService = "https://www.mozilla.org/about/legal/terms/firefox/"
        static let privacyNotice = "https://www.mozilla.org/privacy/firefox/"
    }

    // MARK: - Properties
    var windowUUID: WindowUUID
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?
    var currentWindowUUID: UUID? { windowUUID }
    var notificationCenter: NotificationProtocol
    var didFinishFlow: (() -> Void)?

    // MARK: - UI elements
    private lazy var contentScrollView: UIScrollView = .build()

    private lazy var contentView: UIView = .build()

    private lazy var titleLabel: UILabel = .build { label in
        label.text = String(format: .Onboarding.TermsOfService.Title, AppName.shortName.rawValue)
        label.font = FXFontStyles.Regular.title1.scaledFont()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfService.title
    }

    private lazy var logoImage: UIImageView = .build { logoImage in
        logoImage.image = UIImage(named: ImageIdentifiers.logo)
        logoImage.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfService.logo
    }

    private lazy var confirmationButton: PrimaryRoundedButton = .build { button in
        let viewModel = PrimaryRoundedButtonViewModel(
            title: .Onboarding.TermsOfService.AgreementButtonTitle,
            a11yIdentifier: AccessibilityIdentifiers.TermsOfService.agreeAndContinueButton)
        button.configure(viewModel: viewModel)
        button.addTarget(self, action: #selector(self.acceptTermsOfService), for: .touchUpInside)
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

    // MARK: - Button actions
    @objc
    private func acceptTermsOfService() {
        didFinishFlow?()
    }

    // MARK: - View setup
    private func configure() {
        agreementContent.removeAllArrangedViews()
        let termsOfServiceLink = String(format: .Onboarding.TermsOfService.TermsOfServiceLink, AppName.shortName.rawValue)
        let termsOfServiceAgreement = String(format: .Onboarding.TermsOfService.TermsOfServiceAgreement, termsOfServiceLink)
        setupAgreementTextView(with: termsOfServiceAgreement,
                               linkTitle: termsOfServiceLink,
                               linkType: .termsOfService,
                               and: AccessibilityIdentifiers.TermsOfService.termsOfServiceAgreement)

        let privacyNoticeLink = String.Onboarding.TermsOfService.PrivacyNoticeLink
        let privacyNoticeText = String.Onboarding.TermsOfService.PrivacyNoticeAgreement
        let privacyAgreement = String(format: privacyNoticeText, AppName.shortName.rawValue, privacyNoticeLink)
        setupAgreementTextView(with: privacyAgreement,
                               linkTitle: privacyNoticeLink,
                               linkType: .privacyNotice,
                               and: AccessibilityIdentifiers.TermsOfService.privacyNoticeAgreement)

        let manageLink = String.Onboarding.TermsOfService.ManageLink
        let manageText = String.Onboarding.TermsOfService.ManagePreferenceAgreement
        let manageAgreement = String(format: manageText, AppName.shortName.rawValue, MozillaName.shortName.rawValue, manageLink)
        setupAgreementTextView(with: manageAgreement,
                               linkTitle: manageLink,
                               linkType: .manage,
                               and: AccessibilityIdentifiers.TermsOfService.manageDataCollectionAgreement)
    }

    private func setupLayout() {
        view.addSubview(contentScrollView)
        contentScrollView.addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(logoImage)
        contentView.addSubview(confirmationButton)
        contentView.addSubview(agreementContent)

        let topMargin = view.frame.size.height / 3 - UX.logoIconSize - UX.margin

        NSLayoutConstraint.activate([
            contentScrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentScrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            contentScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            contentView.topAnchor.constraint(equalTo: contentScrollView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: contentScrollView.bottomAnchor),
            contentView.leadingAnchor.constraint(equalTo: contentScrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentScrollView.trailingAnchor),
            contentView.widthAnchor.constraint(equalTo: contentScrollView.frameLayoutGuide.widthAnchor),
            contentView.heightAnchor.constraint(equalTo: contentScrollView.heightAnchor).priority(.defaultLow),

            logoImage.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoImage.heightAnchor.constraint(equalToConstant: UX.logoIconSize),
            logoImage.widthAnchor.constraint(equalToConstant: UX.logoIconSize),
            logoImage.topAnchor.constraint(equalTo: contentView.topAnchor, constant: topMargin),

            titleLabel.topAnchor.constraint(equalTo: logoImage.bottomAnchor, constant: UX.margin),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalMargin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalMargin),

            agreementContent.topAnchor.constraint(
                greaterThanOrEqualTo: titleLabel.bottomAnchor,
                constant: UX.distanceBetweenViews
            ),
            agreementContent.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalMargin),
            agreementContent.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalMargin),

            confirmationButton.topAnchor.constraint(
                equalTo: agreementContent.bottomAnchor,
                constant: UX.distanceBetweenViews
            ),
            confirmationButton.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -UX.distanceBetweenViews
            ),
            confirmationButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.horizontalMargin),
            confirmationButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.horizontalMargin)
        ])
    }

    private func setupAgreementTextView(with title: String, linkTitle: String, linkType: LinkType, and a11yId: String) {
        let agreementLabel: UILabel = .build()
        agreementLabel.accessibilityIdentifier = a11yId
        agreementLabel.numberOfLines = 0
        agreementLabel.textAlignment = .center
        agreementLabel.adjustsFontForContentSizeCategory = true

        let linkedAgreementDescription = NSMutableAttributedString(string: title)
        let linkedText = (title as NSString).range(of: linkTitle)
        linkedAgreementDescription.addAttribute(.font,
                                                value: FXFontStyles.Regular.caption1.scaledFont(),
                                                range: NSRange(location: 0, length: title.count))
        linkedAgreementDescription.addAttribute(.foregroundColor,
                                                value: themeManager.getCurrentTheme(for: windowUUID).colors.textSecondary,
                                                range: NSRange(location: 0, length: title.count))
        linkedAgreementDescription.addAttribute(.foregroundColor,
                                                value: themeManager.getCurrentTheme(for: windowUUID).colors.textAccent,
                                                range: linkedText)

        agreementLabel.isUserInteractionEnabled = true

        switch linkType {
        case .termsOfService:
            let gesture = UITapGestureRecognizer(target: self, action: #selector(presentTermsOfService))
            agreementLabel.addGestureRecognizer(gesture)
        case .privacyNotice:
            let gesture = UITapGestureRecognizer(target: self, action: #selector(presentPrivacyNotice))
            agreementLabel.addGestureRecognizer(gesture)
        case .manage:
            let gesture = UITapGestureRecognizer(target: self, action: #selector(presentManagePreferences))
            agreementLabel.addGestureRecognizer(gesture)
        }

        agreementLabel.attributedText = linkedAgreementDescription
        agreementContent.addArrangedSubview(agreementLabel)
    }

    private func presentLink(with url: URL?) {
        guard let url else { return }
        let presentLinkVC = PrivacyPolicyViewController(url: url, windowUUID: windowUUID)
        let buttonItem = UIBarButtonItem(
            title: .SettingsSearchDoneButton,
            style: .plain,
            target: self,
            action: #selector(dismissPresentedLinkVC))
        buttonItem.accessibilityIdentifier = AccessibilityIdentifiers.TermsOfService.doneButton

        presentLinkVC.navigationItem.rightBarButtonItem = buttonItem
        let controller = DismissableNavigationViewController(rootViewController: presentLinkVC)
        present(controller, animated: true)
    }

    // MARK: - Button actions
    @objc
    private func presentTermsOfService(_ gesture: UIGestureRecognizer) {
        presentLink(with: URL(string: Links.termsOfService))
    }

    @objc
    private func presentPrivacyNotice(_ gesture: UIGestureRecognizer) {
        presentLink(with: URL(string: Links.privacyNotice))
    }

    @objc
    private func presentManagePreferences(_ gesture: UIGestureRecognizer) {
        let managePreferencesVC = PrivacyPreferencesViewController(windowUUID: windowUUID)
        if UIDevice.current.userInterfaceIdiom != .phone {
            managePreferencesVC.modalPresentationStyle = .formSheet
        }
        present(managePreferencesVC, animated: true)
    }

    @objc
    private func dismissPresentedLinkVC() {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Themable
    func applyTheme() {
        let theme = themeManager.getCurrentTheme(for: windowUUID)
        view.backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        confirmationButton.applyTheme(theme: theme)
        configure()
    }
}
