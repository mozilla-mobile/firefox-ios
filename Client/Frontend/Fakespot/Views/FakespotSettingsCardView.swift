// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary

class FakespotSettingsCardViewModel {
    typealias a11yIds = AccessibilityIdentifiers.Shopping.SettingsCard
    private let prefs: Prefs
    private let tabManager: TabManager

    let cardA11yId: String = a11yIds.card
    let showProductsLabelTitle: String = .Shopping.SettingsCardRecommendedProductsLabel
    let showProductsLabelTitleA11yId: String = a11yIds.productsLabel
    let turnOffButtonTitle: String = .Shopping.SettingsCardTurnOffButton
    let turnOffButtonTitleA11yId: String = a11yIds.turnOffButton
    let recommendedProductsSwitchA11yId: String = a11yIds.recommendedProductsSwitch
    let footerTitle: String = ""
    let footerActionTitle: String = .Shopping.SettingsCardFooterAction
    let footerA11yTitleIdentifier: String = a11yIds.footerTitle
    let footerA11yActionIdentifier: String = a11yIds.footerAction
    let footerActionUrl = URL(string: "http://fakespot.com/")
    var dismissViewController: (() -> Void)?

    var isReviewQualityCheckOn: Bool {
        get { return prefs.boolForKey(PrefsKeys.Shopping2023OptIn) ?? true }
        set { prefs.setBool(newValue, forKey: PrefsKeys.Shopping2023OptIn) }
    }

    var areAdsEnabled: Bool {
        get { return prefs.boolForKey(PrefsKeys.Shopping2023EnableAds) ?? true }
        set { prefs.setBool(newValue, forKey: PrefsKeys.Shopping2023EnableAds) }
    }

    var footerModel: ActionFooterViewModel {
        return ActionFooterViewModel(title: footerTitle,
                                     actionTitle: footerActionTitle,
                                     a11yTitleIdentifier: footerA11yTitleIdentifier,
                                     a11yActionIdentifier: footerA11yActionIdentifier,
                                     onTap: { self.onTapButton() })
    }

    init(profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve()) {
        prefs = profile.prefs
        self.tabManager = tabManager
    }

    func onTapButton() {
        guard let footerActionUrl else { return }
        tabManager.addTabsForURLs([footerActionUrl], zombie: false, shouldSelectTab: true)
        dismissViewController?()
    }

    func recordTelemetryForShoppingOptedOut() {
        TelemetryWrapper.recordEvent(category: .action,
                                     method: .tap,
                                     object: .shoppingSettingsCardTurnOffButton)
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
        static let cardBottomSpace: CGFloat = 8
        static let footerHorizontalSpace: CGFloat = 8
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

    private lazy var footerView: ActionFooterView = .build()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(collapsibleContainer)
        addSubview(footerView)
        contentView.addSubviews(contentStackView, turnOffButton)

        [showProductsLabel, recommendedProductsSwitch].forEach(labelSwitchStackView.addArrangedSubview)

        // FXIOS-7369: https://mozilla-hub.atlassian.net/browse/FXIOS-7369
//        contentStackView.addArrangedSubview(labelSwitchStackView)

        NSLayoutConstraint.activate([
            collapsibleContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            collapsibleContainer.topAnchor.constraint(equalTo: topAnchor),
            collapsibleContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            collapsibleContainer.bottomAnchor.constraint(equalTo: footerView.topAnchor, constant: -UX.cardBottomSpace),

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

            footerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            footerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    func configure(_ viewModel: FakespotSettingsCardViewModel) {
        self.viewModel = viewModel
        recommendedProductsSwitch.isOn = viewModel.areAdsEnabled

        showProductsLabel.text = viewModel.showProductsLabelTitle
        showProductsLabel.accessibilityIdentifier = viewModel.showProductsLabelTitleA11yId

        turnOffButton.setTitle(viewModel.turnOffButtonTitle, for: .normal)
        turnOffButton.accessibilityIdentifier = viewModel.turnOffButtonTitleA11yId

        recommendedProductsSwitch.accessibilityIdentifier = viewModel.recommendedProductsSwitchA11yId

        let collapsibleCardViewModel = CollapsibleCardViewModel(
            contentView: contentView,
            cardViewA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.card,
            title: .Shopping.SettingsCardLabelTitle,
            titleA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.title,
            expandButtonA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.expandButton,
            expandButtonA11yLabelExpanded: .Shopping.SettingsCardExpandedAccessibilityLabel,
            expandButtonA11yLabelCollapsed: .Shopping.SettingsCardCollapsedAccessibilityLabel) { state in
                if state == .expanded {
                    TelemetryWrapper.recordEvent(category: .action,
                                                 method: .view,
                                                 object: .shoppingSettingsChevronButton)
                }
        }
        collapsibleContainer.configure(collapsibleCardViewModel)
        footerView.configure(viewModel: viewModel.footerModel)
    }

    @objc
    private func didToggleSwitch(_ sender: UISwitch) {
        viewModel?.areAdsEnabled = sender.isOn
    }

    @objc
    private func didTapTurnOffButton() {
        viewModel?.isReviewQualityCheckOn = false
        viewModel?.dismissViewController?()
        viewModel?.recordTelemetryForShoppingOptedOut()
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

        footerView.applyTheme(theme: theme)
    }
}
