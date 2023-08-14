// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

class CustomizeHomepageSectionCell: UICollectionViewCell, ReusableCell {
    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    private struct UX {
        static let buttonFontSize: CGFloat = 15
        static let buttonTrailingSpace: CGFloat = 12
        static let buttonVerticalInset: CGFloat = 11
        static let buttonCornerRadius: CGFloat = 4
    }

    // MARK: - UI Elements
    private let goToSettingsButton: ActionButton = .build { button in
        button.setTitle(.FirefoxHomepage.CustomizeHomepage.ButtonTitle, for: .normal)
        button.titleLabel?.font = DefaultDynamicFontHelper.preferredBoldFont(withTextStyle: .subheadline,
                                                                             size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.accessibilityIdentifier = a11y.customizeHome
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: ResizableButton.UX.buttonEdgeSpacing,
                                                bottom: UX.buttonVerticalInset,
                                                right: ResizableButton.UX.buttonEdgeSpacing)
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    func setupView() {
        contentView.backgroundColor = .clear
        contentView.addSubview(goToSettingsButton)

        NSLayoutConstraint.activate([
            goToSettingsButton.topAnchor.constraint(equalTo: contentView.topAnchor),
            goToSettingsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            goToSettingsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            goToSettingsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.buttonTrailingSpace)
        ])

        goToSettingsButton.setContentHuggingPriority(.required, for: .vertical)

        // Needed so the button sizes correctly
        setNeedsLayout()
        layoutIfNeeded()
    }

    func configure(onTapAction: ((UIButton) -> Void)?, theme: Theme) {
        goToSettingsButton.touchUpAction = onTapAction
        applyTheme(theme: theme)
    }
}

// MARK: - Blurrable
extension CustomizeHomepageSectionCell: Blurrable {
    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            goToSettingsButton.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            goToSettingsButton.removeVisualEffectView()
        }
    }
}

// MARK: - ThemeApplicable
extension CustomizeHomepageSectionCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        goToSettingsButton.backgroundColor = theme.colors.layer4
        goToSettingsButton.setTitleColor(theme.colors.textPrimary, for: .normal)

        adjustBlur(theme: theme)
    }
}
