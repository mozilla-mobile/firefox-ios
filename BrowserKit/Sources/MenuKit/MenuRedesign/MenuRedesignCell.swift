// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

final class MenuRedesignCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let contentMargin: CGFloat = 16
        static let infoLabelHorizontalMargin: CGFloat = 8
        static let infoLabelVerticalPadding: CGFloat = 7
        static let infoLabelHorizontalPadding: CGFloat = 14
        static let iconSize: CGFloat = 24
        static let largeIconSize: CGFloat = 48
        static let contentSpacing: CGFloat = 3
        static let noDescriptionContentSpacing: CGFloat = 0
    }

    // MARK: - UI Elements
    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
    }

    private var descriptionLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.caption1.scaledFont()
    }

    private var contentStackView: UIStackView = .build { stackView in
        stackView.axis = .vertical
        stackView.distribution = .fillProportionally
    }

    private var iconImageView: UIImageView = .build()

    private var infoLabelView: MenuPaddedLabel = .build { label in
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.textInsets = UIEdgeInsets(
            top: UX.infoLabelVerticalPadding,
            left: UX.infoLabelHorizontalPadding,
            bottom: UX.infoLabelVerticalPadding,
            right: UX.infoLabelHorizontalPadding
        )
    }

    // MARK: - Properties
    var model: MenuElement?

    // MARK: - Initializers
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        infoLabelView.text = nil
        iconImageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        infoLabelView.layer.cornerRadius = infoLabelView.frame.height / 2
    }

    func configureCellWith(model: MenuElement) {
        self.model = model
        self.titleLabel.text = model.title
        self.descriptionLabel.text = model.description
        self.contentStackView.spacing = model.description != nil ? UX.contentSpacing : UX.noDescriptionContentSpacing
        if let infoTitle = model.infoTitle {
            infoLabelView.text = infoTitle
        } else {
            self.iconImageView.image = UIImage(named: model.iconName)?.withRenderingMode(.alwaysTemplate)
        }
        self.isAccessibilityElement = true
        self.isUserInteractionEnabled = !model.isEnabled ? false : true
        self.accessibilityIdentifier = model.a11yId
        self.accessibilityLabel = model.a11yLabel
        self.accessibilityHint = model.a11yHint
        self.accessibilityTraits = .button
        self.separatorInset = .zero
        setupView(hasInfoTitle: model.infoTitle != nil)
    }

    private func setupView(hasInfoTitle: Bool) {
        self.addSubview(contentStackView)
        self.addSubview(hasInfoTitle ? infoLabelView : iconImageView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        NSLayoutConstraint.activate([
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.contentMargin),
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: UX.contentMargin),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.contentMargin)
        ])

        if hasInfoTitle {
            NSLayoutConstraint.activate([
                contentStackView.trailingAnchor.constraint(
                    equalTo: infoLabelView.leadingAnchor,
                    constant: -UX.infoLabelHorizontalMargin
                ),
                infoLabelView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.infoLabelHorizontalMargin),
                infoLabelView.centerYAnchor.constraint(equalTo: centerYAnchor)
            ])
            infoLabelView.setContentCompressionResistancePriority(.required, for: .horizontal)
            infoLabelView.setContentHuggingPriority(.required, for: .horizontal)

            contentStackView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            contentStackView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        } else {
            NSLayoutConstraint.activate([
                iconImageView.leadingAnchor.constraint(equalTo: contentStackView.trailingAnchor,
                                                       constant: UX.contentMargin),
                iconImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.contentMargin),
                iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: UX.iconSize),
                iconImageView.heightAnchor.constraint(equalToConstant: UX.iconSize)
            ])
        }
        adjustLayout(isAccessibilityCategory: UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory)
    }

    private func adjustLayout(isAccessibilityCategory: Bool) {
        let iconSize = isAccessibilityCategory ? UX.largeIconSize : UX.iconSize
        iconImageView.widthAnchor.constraint(equalToConstant: iconSize).isActive = true
        iconImageView.heightAnchor.constraint(equalToConstant: iconSize).isActive = true
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        guard let model else { return }
        backgroundColor = theme.colors.layer2
        if model.infoTitle != nil {
            infoLabelView.textColor = theme.colors.textPrimary
            infoLabelView.backgroundColor = model.isActive ? theme.colors.layerInformation : theme.colors.layer3
            titleLabel.textColor = model.isActive ? theme.colors.textAccent : theme.colors.textPrimary
        } else if model.isActive {
            titleLabel.textColor = theme.colors.textAccent
            descriptionLabel.textColor = theme.colors.textSecondary
            iconImageView.tintColor = theme.colors.iconAccentBlue
        } else if !model.isEnabled {
            titleLabel.textColor = theme.colors.textDisabled
            descriptionLabel.textColor = theme.colors.textDisabled
            iconImageView.tintColor = theme.colors.iconDisabled
        } else {
            titleLabel.textColor = theme.colors.textPrimary
            descriptionLabel.textColor = theme.colors.textSecondary
            iconImageView.tintColor = theme.colors.iconPrimary
        }
    }
}
