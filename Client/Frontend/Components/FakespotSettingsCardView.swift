// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared
import ComponentLibrary

struct FakespotSettingsCardViewModel {
    let cardA11yId: String
    let showProductsLabelTitle: String
    let showProductsLabelTitleA11yId: String
    let turnOffButtonTitle: String
    let turnOffButtonTitleA11yId: String
}

final class FakespotSettingsCardView: UIView, ThemeApplicable {
    private struct UX {
        static let headerLabelFontSize: CGFloat = 17
        static let buttonLabelFontSize: CGFloat = 17
        static let buttonCornerRadius: CGFloat = 14
        static let contentStackViewSpacing: CGFloat = 16
        static let midSeparatorWidth: CGFloat = 12
        static let leftRighSeparatorWidth: CGFloat = 8
        static let contentInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        static let buttonInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
    }

    var onSwitchValueVhanged: ((Bool) -> Void)?

    private lazy var leftSeparator: UIView = .build()
    private lazy var midSeparator: UIView = .build()
    private lazy var rightSeparator: UIView = .build()
    private lazy var collapsibleContainer: CollapsibleCardContainer = .build()

    private lazy var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.spacing = UX.contentStackViewSpacing
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UX.contentInsets
    }

    private lazy var labelSwitchStackView: UIStackView = .build { stackView in
        stackView.alignment = .fill
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

    private lazy var turnOffButton: ActionButton = .build { button in
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.contentEdgeInsets = UX.buttonInsets
        button.titleLabel?.textAlignment = .center
        button.backgroundColor = .systemBlue
        button.clipsToBounds = true
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredFont(withTextStyle: .headline,
                                                                         size: UX.buttonLabelFontSize,
                                                                         weight: .semibold)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupSeparator(leftSeparator)
        setupSeparator(midSeparator, width: UX.midSeparatorWidth)
        setupSeparator(rightSeparator)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(collapsibleContainer)

        [leftSeparator, showProductsLabel, midSeparator, recommendedProductsSwitch, rightSeparator].forEach(labelSwitchStackView.addArrangedSubview)
        [labelSwitchStackView, turnOffButton].forEach(contentStackView.addArrangedSubview)

        NSLayoutConstraint.activate([
            collapsibleContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            collapsibleContainer.topAnchor.constraint(equalTo: topAnchor),
            collapsibleContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            collapsibleContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func setupSeparator(_ separator: UIView, width: CGFloat = UX.leftRighSeparatorWidth) {
        separator.widthAnchor.constraint(equalToConstant: width).isActive = true
    }

    func configure(_ viewModel: FakespotSettingsCardViewModel) {
        showProductsLabel.text = viewModel.showProductsLabelTitle
        showProductsLabel.accessibilityIdentifier = viewModel.showProductsLabelTitleA11yId

        turnOffButton.setTitle(viewModel.turnOffButtonTitle, for: .normal)
        turnOffButton.accessibilityIdentifier = viewModel.turnOffButtonTitleA11yId

        let viewModel = CollapsibleCardContainerModel(
            contentView: contentStackView,
            cardViewA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.card,
            title: .Shopping.SettingsCardLabelTitle,
            titleA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.title,
            expandButtonA11yId: AccessibilityIdentifiers.Shopping.SettingsCard.expandButton,
            expandButtonA11yLabelExpanded: AccessibilityIdentifiers.Shopping.SettingsCard.expandButtonLabelExpanded,
            expandButtonA11yLabelCollapsed: AccessibilityIdentifiers.Shopping.SettingsCard.expandButtonLabelCollapsed)
        collapsibleContainer.configure(viewModel)
    }

    @objc
    func didToggleSwitch(_ sender: UISwitch) {
        onSwitchValueVhanged?(sender.isOn)
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
