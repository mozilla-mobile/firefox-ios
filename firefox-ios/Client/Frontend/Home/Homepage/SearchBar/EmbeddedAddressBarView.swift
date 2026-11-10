// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

final class EmbeddedAddressBarView: UIView, ThemeApplicable {
    private enum UX {
        static let horizontalPadding: CGFloat = 16
        static let verticalPadding: CGFloat = 14
        static let contentSpacing: CGFloat = 8
        static let searchIconSize = CGSize(width: 20, height: 20)
    }

    private lazy var searchIconView: UIImageView = .build { view in
        view.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.search)
        view.contentMode = .scaleAspectFit
    }

    private lazy var placeholderLabel: UILabel = .build { label in
        label.text = .AddressToolbar.LocationPlaceholder
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    private lazy var glassView: UIVisualEffectView = .build { view in
        view.layer.cornerCurve = .continuous
        if #available(iOS 26.0, *) {
            view.effect = UIGlassEffect()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupAccessibility()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let radius = bounds.height / 2
        layer.cornerRadius = radius
        glassView.layer.cornerRadius = radius
    }

    private func setupView() {
        addSubview(glassView)
        addSubviews(searchIconView, placeholderLabel)

        NSLayoutConstraint.activate([
            glassView.topAnchor.constraint(equalTo: topAnchor),
            glassView.leadingAnchor.constraint(equalTo: leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: trailingAnchor),
            glassView.bottomAnchor.constraint(equalTo: bottomAnchor),

            searchIconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.horizontalPadding),
            searchIconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            searchIconView.widthAnchor.constraint(equalToConstant: UX.searchIconSize.width),
            searchIconView.heightAnchor.constraint(equalToConstant: UX.searchIconSize.height),

            placeholderLabel.leadingAnchor.constraint(
                equalTo: searchIconView.trailingAnchor,
                constant: UX.contentSpacing
            ),
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: UX.verticalPadding),
            bottomAnchor.constraint(equalTo: placeholderLabel.bottomAnchor, constant: UX.verticalPadding),
            trailingAnchor.constraint(
                greaterThanOrEqualTo: placeholderLabel.trailingAnchor,
                constant: UX.horizontalPadding
            )
        ])
    }

    private func setupAccessibility() {
        isAccessibilityElement = false
        accessibilityElementsHidden = true
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        if #available(iOS 26.0, *) {
            backgroundColor = .clear
        } else {
            backgroundColor = theme.colors.layerSurfaceMedium
        }
        placeholderLabel.textColor = theme.colors.textSecondary
        searchIconView.tintColor = theme.colors.iconPrimary
    }
}
