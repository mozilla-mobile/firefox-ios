// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

// MARK: - FxHomePocketDiscoverMoreCell
/// A cell to be placed at the last position in the Pocket section
class PocketDiscoverCell: UICollectionViewCell, ReusableCell {
    struct UX {
        static let horizontalMargin: CGFloat = 16
    }

    // MARK: - UI Elements
    let itemTitle: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.font = FXFontStyles.Bold.title3.scaledFont()
        label.numberOfLines = 0
        label.textAlignment = .left
        label.accessibilityTraits.insert(.button)
    }

    // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        itemTitle.text = nil
    }

    func configure(text: String, theme: Theme) {
        itemTitle.text = text
        applyTheme(theme: theme)
    }

    // MARK: - Helpers

    private func setupLayout() {
        contentView.addSubviews(itemTitle)

        NSLayoutConstraint.activate([
            itemTitle.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                               constant: UX.horizontalMargin),
            itemTitle.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                constant: -UX.horizontalMargin),
            itemTitle.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    private func setupShadow(theme: Theme) {
        contentView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: HomepageViewModel.UX.generalCornerRadius).cgPath
        contentView.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
        contentView.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowDefault.cgColor
        contentView.layer.shadowOpacity = HomepageViewModel.UX.shadowOpacity
    }
}

// MARK: - ThemeApplicable
extension PocketDiscoverCell: ThemeApplicable {
    func applyTheme(theme: Theme) {
        itemTitle.textColor = theme.colors.textPrimary
        adjustBlur(theme: theme)
    }
}

// MARK: - ThemeApplicable
extension PocketDiscoverCell: Blurrable {
    func adjustBlur(theme: Theme) {
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
            contentView.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = theme.colors.layer5
            setupShadow(theme: theme)
        }
    }
}
