// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

class SearchBarCell: UICollectionViewCell, ReusableCell, ThemeApplicable {
    struct UX {
        static let shadowRadius: CGFloat = 14
        static let shadowOffset = CGSize(width: 0, height: 2)
        static let shadowOpacity: Float = 1
        static let cornerRadius: CGFloat = 32
        static let borderWidth: CGFloat = 1
        static let heightPadding: CGFloat = 20
        static let widthPadding: CGFloat = 16
        static let containerPadding: CGFloat = 4
        static let contentSpacing: CGFloat = 8
        static let searchImageSize = CGSize(width: 22, height: 22)
    }

    private let container: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.layer.borderWidth = UX.borderWidth
    }

    private lazy var contentStackView: UIStackView = .build { view in
        view.alignment = .center
        view.spacing = UX.contentSpacing
    }

    private lazy var placeholderLabel: UILabel = .build { view in
        view.text = .FirefoxHomepage.SearchBar.PlaceholderTitle
        view.font = FXFontStyles.Regular.body.scaledFont()
        view.textAlignment = .center
        view.numberOfLines = 0
        view.adjustsFontForContentSizeCategory = true
    }

    private lazy var searchImageView: UIImageView = .build { view in
        view.image = UIImage.templateImageNamed(StandardImageIdentifiers.Large.search)
        view.contentMode = .scaleAspectFit
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupAccessibility()
        setupView()
    }

    private func setupAccessibility() {
        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.SearchBar.itemCell
        accessibilityTraits.insert(.button)
        accessibilityLabel = .FirefoxHomepage.SearchBar.PlaceholderTitle
    }

    private func setupView() {
        contentStackView.addArrangedSubview(searchImageView)
        contentStackView.addArrangedSubview(placeholderLabel)
        container.addSubview(contentStackView)
        contentView.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: UX.containerPadding),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.containerPadding),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.containerPadding),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.containerPadding),

            searchImageView.heightAnchor.constraint(equalToConstant: UX.searchImageSize.height),
            searchImageView.widthAnchor.constraint(equalToConstant: UX.searchImageSize.width),

            contentStackView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            contentStackView.topAnchor.constraint(equalTo: container.topAnchor, constant: UX.heightPadding),
            contentStackView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -UX.heightPadding),
            contentStackView.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, constant: -UX.widthPadding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.layer.shadowPath = UIBezierPath(
            roundedRect: contentView.bounds,
            cornerRadius: UX.cornerRadius
        ).cgPath
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: Theme) {
        placeholderLabel.textColor = theme.colors.textSecondary
        container.backgroundColor = theme.colors.layer2
        container.layer.borderColor = theme.colors.borderPrimary.cgColor
        searchImageView.tintColor = theme.colors.iconSecondary
        setupShadow(theme: theme)
    }

    func setupShadow(theme: Theme) {
        contentView.layer.shadowRadius = UX.shadowRadius
        contentView.layer.shadowOffset = UX.shadowOffset
        contentView.layer.shadowColor = theme.colors.shadowStrong.cgColor
        contentView.layer.shadowOpacity = UX.shadowOpacity
    }
}
