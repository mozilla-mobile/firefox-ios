// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary

// MARK: View Model

struct FakespotOptInCardViewModel {
    private let tabManager: TabManager
    private let prefs: Prefs
    let cardA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.card
    var productSitename: String?
    // MARK: Labels
    let headerTitleLabel: String = .Shopping.OptInCardHeaderTitle
    let headerLabelA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.headerTitle
    let bodyFirstParagraphLabel: String = .Shopping.OptInCardCopy
    let bodyFirstParagraphA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.optInCopy
    let disclaimerTextLabel: String = .Shopping.OptInCardDisclaimerText
    let disclaimerTextLabelA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.disclaimerText
    // MARK: Buttons
    let learnMoreButtonTitle: String = .Shopping.OptInCardLearnMoreButtonTitle
    let learnMoreButtonTitleA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.learnMoreButtonTitle
    let termsOfUseButtonTitle: String = .Shopping.OptInCardTermsOfUse
    let termsOfUseButtonTitleA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.termsOfUseButtonTitle
    let privacyPolicyButtonTitle: String = .Shopping.OptInCardPrivacyPolicy
    let privacyPolicyButtonTitleA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.privacyPolicyButtonTitle
    let mainButtonTitle: String = .Shopping.OptInCardMainButtonTitle
    let mainButtonTitleA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.mainButtonTitle
    let secondaryButtonTitle: String = .Shopping.OptInCardSecondaryButtonTitle
    let secondaryButtonTitleA11yId: String = AccessibilityIdentifiers.Shopping.OptInCard.secondaryButtonTitle
    // MARK: Actions
    func onTapLearnMore() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingLearnMoreButton)
//        tabManager.addTabsForURLs([], zombie: false, shouldSelectTab: true) // no urls yet, will be added in another task
    }

    func onTapTermsOfUse() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingTermsOfUseButton)
    }

    func onTapPrivacyPolicy() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingPrivacyPolicyButton)
    }

    func onTapMainButton() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingOptIn)
    }
    func onTapSecondaryButton() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingNotNowButton)
    }

    var shouldOptIn: Bool {
        get { return prefs.boolForKey(PrefsKeys.Shopping2023OptIn) ?? false }
        set { prefs.setBool(newValue, forKey: PrefsKeys.Shopping2023OptIn) }
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve()) {
        self.tabManager = tabManager
        prefs = profile.prefs
    }
}

// MARK: View
final class OptInCardView: UIView, ThemeApplicable {
    private struct UX {
        static let headerLabelFontSize: CGFloat = 28
        static let bodyFirstParagraphLabelFontSize: CGFloat = 15
        static let bodySecondParagraphLabelFontSize: CGFloat = 15
        static let learnMoreButtonFontSize: CGFloat = 15
        static let termsOfUseButtonInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let disclaimerTextLabelFontSize: CGFloat = 13
        static let disclaimerBlockInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        static let termsOfUseButtonTitleFontSize: CGFloat = 13
        static let privacyPolicyButtonTitleFontSize: CGFloat = 13
        static let mainButtonFontSize: CGFloat = 16
        static let mainButtonCornerRadius: CGFloat = 14
        static let mainButtonInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        static let secondaryButtonFontSize: CGFloat = 13
        static let contentStackViewSpacing: CGFloat = 12
        static let contentStackViewPadding: CGFloat = 16
        static let disclaimerStackViewSpacing: CGFloat = 3
    }

    private var viewModel: FakespotOptInCardViewModel?

    private lazy var cardContainer: ShadowCardView = .build()
    private lazy var mainView: UIView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.contentStackViewSpacing
    }

    private lazy var disclaimerStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.disclaimerStackViewSpacing
    }

    private lazy var optInImageView: UIImageView = .build { imageView in
        imageView.image = UIImage(named: ImageIdentifiers.shoppingOptInCardImage)
        imageView.contentMode = .scaleAspectFit
    }

    // MARK: Labels
    private lazy var headerLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                            size: UX.headerLabelFontSize,
                                                            weight: .medium)
    }

    private lazy var bodyFirstParagraphLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.bodyFirstParagraphLabelFontSize)
    }

    private lazy var disclaimerTextLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.disclaimerTextLabelFontSize)
    }

    // MARK: Buttons
    private lazy var learnMoreButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.buttonEdgeSpacing = 0
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.didTapLearnMore), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                         size: UX.learnMoreButtonFontSize)
    }

    private lazy var termsOfUseButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.buttonEdgeSpacing = 0
        button.contentEdgeInsets = UX.disclaimerBlockInsets
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.didTapTermsOfUse), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                         size: UX.termsOfUseButtonTitleFontSize)
    }

    private lazy var privacyPolicyButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .leading
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.buttonEdgeSpacing = 0
        button.contentEdgeInsets = UX.disclaimerBlockInsets
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.didTapPrivacyPolicy), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                         size: UX.privacyPolicyButtonTitleFontSize)
    }

    private lazy var mainButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .center
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.buttonEdgeSpacing = 0
        button.layer.cornerRadius = UX.mainButtonCornerRadius
        button.contentEdgeInsets = UX.mainButtonInsets
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.didTapMainButton), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                                         size: UX.mainButtonFontSize,
                                                                         weight: .semibold)
    }

    private lazy var secondaryButton: ResizableButton = .build { button in
        button.contentHorizontalAlignment = .center
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.buttonEdgeSpacing = 0
        button.titleLabel?.numberOfLines = 0
        button.addTarget(self, action: #selector(self.didTapSecondaryButton), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                                         size: UX.secondaryButtonFontSize)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Constraints Setup
    private func setupLayout() {
        addSubviews(cardContainer, mainView)
        mainView.addSubview(contentStackView)
        contentStackView.addArrangedSubview(headerLabel)

        contentStackView.addArrangedSubview(bodyFirstParagraphLabel)
        contentStackView.addArrangedSubview(learnMoreButton)

        contentStackView.addArrangedSubview(optInImageView)

        disclaimerStackView.addArrangedSubview(disclaimerTextLabel)
        disclaimerStackView.addArrangedSubview(privacyPolicyButton)
        disclaimerStackView.addArrangedSubview(termsOfUseButton)
        contentStackView.addArrangedSubview(disclaimerStackView)

        contentStackView.addArrangedSubview(mainButton)
        contentStackView.addArrangedSubview(secondaryButton)

        NSLayoutConstraint.activate([
            cardContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardContainer.topAnchor.constraint(equalTo: topAnchor),
            cardContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: mainView.topAnchor,
                                                  constant: UX.contentStackViewPadding),
            contentStackView.bottomAnchor.constraint(equalTo: mainView.bottomAnchor,
                                                     constant: -UX.contentStackViewPadding),
            contentStackView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor,
                                                      constant: UX.contentStackViewPadding),
            contentStackView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor,
                                                       constant: -UX.contentStackViewPadding),
        ])
    }

    // MARK: Button Actions
    @objc
    private func didTapLearnMore() {
        viewModel?.onTapLearnMore()
    }

    @objc
    private func didTapTermsOfUse() {
        viewModel?.onTapTermsOfUse()
    }

    @objc
    private func didTapPrivacyPolicy() {
        viewModel?.onTapPrivacyPolicy()
    }

    @objc
    private func didTapMainButton() {
        viewModel?.shouldOptIn = true
        viewModel?.onTapMainButton()
    }

    @objc
    private func didTapSecondaryButton() {
        
        viewModel?.onTapSecondaryButton()
    }

    // MARK: View Setup
    func configure(_ viewModel: FakespotOptInCardViewModel) {
        self.viewModel = viewModel

        headerLabel.text = viewModel.headerTitleLabel
        headerLabel.accessibilityIdentifier = viewModel.headerLabelA11yId

        bodyFirstParagraphLabel.attributedText = getFirstParagraphText()
        bodyFirstParagraphLabel.accessibilityIdentifier = viewModel.bodyFirstParagraphA11yId

        disclaimerTextLabel.attributedText = getDisclaimerText()
        disclaimerTextLabel.accessibilityIdentifier = viewModel.disclaimerTextLabelA11yId

        learnMoreButton.setTitle(viewModel.learnMoreButtonTitle, for: .normal)
        learnMoreButton.accessibilityIdentifier = viewModel.learnMoreButtonTitleA11yId

        termsOfUseButton.setTitle(viewModel.termsOfUseButtonTitle, for: .normal)
        termsOfUseButton.accessibilityIdentifier = viewModel.termsOfUseButtonTitleA11yId

        privacyPolicyButton.setTitle(viewModel.privacyPolicyButtonTitle, for: .normal)
        privacyPolicyButton.accessibilityIdentifier = viewModel.privacyPolicyButtonTitleA11yId

        mainButton.setTitle(viewModel.mainButtonTitle, for: .normal)
        mainButton.accessibilityIdentifier = viewModel.mainButtonTitleA11yId

        secondaryButton.setTitle(viewModel.secondaryButtonTitle, for: .normal)
        secondaryButton.accessibilityIdentifier = viewModel.secondaryButtonTitleA11yId

        let cardModel = ShadowCardViewModel(view: mainView, a11yId: viewModel.cardA11yId)
        cardContainer.configure(cardModel)
    }

    func getFirstParagraphText() -> NSAttributedString {
        let websites = self.getFirstParagraphWebsites()
        let font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                          size: UX.bodyFirstParagraphLabelFontSize)
        let plainText = String.localizedStringWithFormat(viewModel?.bodyFirstParagraphLabel ?? "", websites[0], websites[1], websites[2])
        return plainText.attributedText(boldStrings: websites, font: font)
    }

    func getFirstParagraphWebsites() -> [String] {
        let lowercasedName = self.viewModel?.productSitename?.lowercased() ?? "amazon"
        var currentPartnerWebsites = ["amazon", "walmart", "bestbuy"]

        // just in case this card will be shown from an unpartnered website in the future
        guard currentPartnerWebsites.contains(lowercasedName) else {
            currentPartnerWebsites[2] = "Best Buy"
            return currentPartnerWebsites.map { $0.capitalized }
        }

        var websitesOrder = currentPartnerWebsites.filter { $0 != lowercasedName }
        if lowercasedName == "bestbuy" {
            websitesOrder.insert("Best Buy", at: 0)
        } else {
            websitesOrder.insert(lowercasedName.capitalized, at: 0)
        }

        return websitesOrder.map { $0.capitalized }
    }

    func getDisclaimerText() -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.firstLineHeadIndent = UX.contentStackViewPadding
        paragraphStyle.headIndent = UX.contentStackViewPadding

        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle
        ]

        return NSAttributedString(string: viewModel?.disclaimerTextLabel ?? "", attributes: attributes)
    }

    // MARK: - Theming System
    func applyTheme(theme: Theme) {
        cardContainer.applyTheme(theme: theme)
        let colors = theme.colors
        headerLabel.textColor = colors.textPrimary
        bodyFirstParagraphLabel.textColor = colors.textPrimary
        disclaimerTextLabel.textColor = colors.textSecondary
        learnMoreButton.setTitleColor(colors.textAccent, for: .normal)
        termsOfUseButton.setTitleColor(colors.textAccent, for: .normal)
        privacyPolicyButton.setTitleColor(colors.textAccent, for: .normal)
        mainButton.setTitleColor(colors.textInverted, for: .normal)
        mainButton.backgroundColor = colors.actionPrimary
        secondaryButton.setTitleColor(colors.textAccent, for: .normal)
        let themedImage = UIImage(named: theme.type.getThemedImageName(name: ImageIdentifiers.shoppingOptInCardImage))
        optInImageView.image = themedImage
    }
}
