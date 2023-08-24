// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary

class FakespotSettingsCardViewModel {
    let prefs: Prefs
    let cardA11yId: String
    let showProductsLabelTitle: String
    let showProductsLabelTitleA11yId: String
    let turnOffButtonTitle: String
    let turnOffButtonTitleA11yId: String
    let recommendedProductsSwitchA11yId: String

    var isReviewQualityCheckOn: Bool {
        get { return prefs.boolForKey(PrefsKeys.Shopping2023OptIn) ?? true }
        set { prefs.setBool(newValue, forKey: PrefsKeys.Shopping2023OptIn) }
    }

    var areAdsEnabled: Bool {
        get { return prefs.boolForKey(PrefsKeys.Shopping2023EnableAds) ?? true }
        set { prefs.setBool(newValue, forKey: PrefsKeys.Shopping2023EnableAds) }
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         cardA11yId: String,
         showProductsLabelTitle: String,
         showProductsLabelTitleA11yId: String,
         turnOffButtonTitle: String,
         turnOffButtonTitleA11yId: String,
         recommendedProductsSwitchA11yId: String) {
        prefs = profile.prefs
        self.cardA11yId = cardA11yId
        self.showProductsLabelTitle = showProductsLabelTitle
        self.showProductsLabelTitleA11yId = showProductsLabelTitleA11yId
        self.turnOffButtonTitle = turnOffButtonTitle
        self.turnOffButtonTitleA11yId = turnOffButtonTitleA11yId
        self.recommendedProductsSwitchA11yId = recommendedProductsSwitchA11yId
    }
}

final class FakespotSettingsCardView: UIView, ThemeApplicable {
    private struct UX {
        static let headerLabelFontSize: CGFloat = 17
        static let buttonLabelFontSize: CGFloat = 17
        static let buttonCornerRadius: CGFloat = 14
        static let buttonLeadingTrailingPadding: CGFloat = 8
        static let buttonTopPadding: CGFloat = 16
        static let contentStackViewSpacing: CGFloat = 16
        static let labelSwitchStackViewSpacing: CGFloat = 12
        static let contentInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        static let buttonInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }

    private var isReviewQualityCheckOn = true {
        didSet {
            #warning("TODO: Update Turn Off button title")
        }
    }

    private var viewModel: FakespotSettingsCardViewModel?

    private lazy var collapsibleContainer: CollapsibleCardView = .build()
    private lazy var contentView: UIView = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.contentStackViewSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.contentInsets
    }

    private lazy var labelSwitchStackView: UIStackView = .build { stackView in
        stackView.alignment = .center
        stackView.spacing = UX.labelSwitchStackViewSpacing
    }

    private lazy var showProductsLabel: UILabel = .build { label in
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.clipsToBounds = true
        label.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .body,
                                                            size: UX.headerLabelFontSize)
    }

    private lazy var recommendedProductsSwitch: UISwitch = .build { uiSwitch in
        uiSwitch.setContentCompressionResistancePriority(.required, for: .horizontal)
        uiSwitch.clipsToBounds = true
        uiSwitch.addTarget(self, action: #selector(self.didToggleSwitch), for: .valueChanged)
    }

    private lazy var turnOffButton: ResizableButton = .build { button in
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.contentEdgeInsets = UX.buttonInsets
        button.titleLabel?.textAlignment = .center
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(self.didTapTurnOffButton), for: .touchUpInside)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                                         size: UX.buttonLabelFontSize,
                                                                         weight: .semibold)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(collapsibleContainer)
        contentView.addSubviews(contentStackView, turnOffButton)

        [showProductsLabel, recommendedProductsSwitch].forEach(labelSwitchStackView.addArrangedSubview)
        contentStackView.addArrangedSubview(labelSwitchStackView)

        NSLayoutConstraint.activate([
            collapsibleContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            collapsibleContainer.topAnchor.constraint(equalTo: topAnchor),
            collapsibleContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            collapsibleContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            turnOffButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                                   constant: -UX.buttonLeadingTrailingPadding),
            turnOffButton.topAnchor.constraint(equalTo: contentStackView.bottomAnchor,
                                               constant: UX.buttonTopPadding),
            turnOffButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                    constant: UX.buttonLeadingTrailingPadding),
            turnOffButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    func configure(_ viewModel: FakespotSettingsCardViewModel) {
        self.viewModel = viewModel
        recommendedProductsSwitch.isOn = viewModel.areAdsEnabled
        isReviewQualityCheckOn = viewModel.isReviewQualityCheckOn

        showProductsLabel.text = viewModel.showProductsLabelTitle
        showProductsLabel.accessibilityIdentifier = viewModel.showProductsLabelTitleA11yId

        turnOffButton.setTitle(viewModel.turnOffButtonTitle, for: .normal)
        turnOffButton.accessibilityIdentifier = viewModel.turnOffButtonTitleA11yId

        recommendedProductsSwitch.accessibilityIdentifier = viewModel.recommendedProductsSwitchA11yId

        let viewModel = CollapsibleCardViewModel(
            contentView: contentView,
            cardViewA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.card,
            title: .Shopping.SettingsCardLabelTitle,
            titleA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.title,
            expandButtonA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.expandButton,
            expandButtonA11yLabelExpanded: .Shopping.SettingsCardExpandedAccessibilityLabel,
            expandButtonA11yLabelCollapsed: .Shopping.SettingsCardCollapsedAccessibilityLabel)
        collapsibleContainer.configure(viewModel)
    }

    @objc
    func didToggleSwitch(_ sender: UISwitch) {
        viewModel?.areAdsEnabled = sender.isOn
    }

    @objc
    private func didTapTurnOffButton() {
        viewModel?.isReviewQualityCheckOn = false
    }

    // MARK: - Theming System
    func applyTheme(theme: Theme) {
        collapsibleContainer.applyTheme(theme: theme)
        let colors = theme.colors
        showProductsLabel.textColor = colors.textPrimary

        recommendedProductsSwitch.onTintColor = colors.actionPrimary
        recommendedProductsSwitch.tintColor = colors.formKnob

        turnOffButton.backgroundColor = colors.actionSecondary
        turnOffButton.setTitleColor(colors.textPrimary, for: .normal)
    }
}
