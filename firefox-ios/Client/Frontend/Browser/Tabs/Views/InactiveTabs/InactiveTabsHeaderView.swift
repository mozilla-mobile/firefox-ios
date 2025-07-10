// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

class InactiveTabsHeaderView: UICollectionReusableView, ReusableCell, ThemeApplicable {
    private struct UX {
        static let titleMinimumScaleFactor: CGFloat = 0.7
        static let verticalPadding: CGFloat = 19
        static let horizontalPadding: CGFloat = 16
        static let buttonBottomPadding: CGFloat = 28
    }

    var state: ExpandButtonState? {
        willSet(state) {
            moreButton.setImage(state?.image, for: .normal)
        }
    }

    lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.font = FXFontStyles.Bold.headline.scaledFont()
        titleLabel.text = String.TabsTrayInactiveTabsSectionTitle
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.InactiveTabs.headerLabel
        titleLabel.minimumScaleFactor = UX.titleMinimumScaleFactor
        titleLabel.adjustsFontSizeToFitWidth = true
    }

    lazy var moreButton: UIButton = .build { button in
        button.isHidden = true
        button.setImage(self.state?.image, for: .normal)
        button.accessibilityIdentifier = AccessibilityIdentifiers.TabTray.InactiveTabs.headerButton
        button.contentHorizontalAlignment = .trailing
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        addSubview(titleLabel)
        addSubview(moreButton)
        moreButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityIdentifier = AccessibilityIdentifiers.TabTray.InactiveTabs.headerView

        NSLayoutConstraint.activate(
            [
                titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
                titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: UX.verticalPadding),
                titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.verticalPadding),
                titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor,
                                                    constant: UX.horizontalPadding),
                titleLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor,
                                                     constant: -UX.horizontalPadding),

                moreButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
                moreButton.trailingAnchor.constraint(
                    equalTo: safeAreaLayoutGuide.trailingAnchor,
                    constant: -UX.buttonBottomPadding
                )
            ]
        )
    }

    func applyTheme(theme: Theme) {
        backgroundColor = theme.colors.layer2
        titleLabel.textColor = theme.colors.textPrimary
        moreButton.tintColor = theme.colors.textPrimary
    }
}
