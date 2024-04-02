// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import UIKit
import Shared

class CustomizeHomepageSectionCell: UICollectionViewCell, ReusableCell {
    typealias a11y = AccessibilityIdentifiers.FirefoxHomepage.OtherButtons

    // MARK: - UI Elements
    private lazy var goToSettingsButton: SecondaryRoundedButton = .build { button in
        button.addTarget(self, action: #selector(self.touchUpInside), for: .touchUpInside)
    }

    private var touchUpAction: ((UIButton) -> Void)?

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

        NSLayoutConstraint.activate(
            [
                goToSettingsButton.topAnchor.constraint(equalTo: contentView.topAnchor),
                goToSettingsButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
                goToSettingsButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                goToSettingsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
            ]
        )

        goToSettingsButton.setContentHuggingPriority(.required, for: .vertical)

        // Needed so the button sizes correctly
        setNeedsLayout()
        layoutIfNeeded()
    }

    func configure(onTapAction: ((UIButton) -> Void)?, theme: Theme) {
        touchUpAction = onTapAction
        let goToSettingsButtonViewModel = SecondaryRoundedButtonViewModel(
            title: .FirefoxHomepage.CustomizeHomepage.ButtonTitle,
            a11yIdentifier: a11y.customizeHome)
        goToSettingsButton.configure(viewModel: goToSettingsButtonViewModel)
        applyTheme(theme: theme)
    }

    @objc
    func touchUpInside(sender: UIButton) {
        touchUpAction?(sender)
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
        goToSettingsButton.applyTheme(theme: theme)
        adjustBlur(theme: theme)
    }
}
