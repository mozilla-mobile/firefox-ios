// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

final class MenuInfoCell: UITableViewCell, ReusableCell, ThemeApplicable {
    private struct UX {
        static let contentMargin: CGFloat = 16
        static let infoLabelHorizontalMargin: CGFloat = 8
        static let infoLabelVerticalPadding: CGFloat = 7
        static let infoLabelHorizontalPadding: CGFloat = 14
    }

    // MARK: - UI Elements
    private var titleLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.body.scaledFont()
        label.numberOfLines = 0
    }

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
        setupView(hasInfoTitle: model?.infoTitle != nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        infoLabelView.layer.cornerRadius = infoLabelView.frame.height / 2
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        infoLabelView.text = nil
    }

    func configureCellWith(model: MenuElement) {
        self.model = model
        self.titleLabel.text = model.title
        self.infoLabelView.text = model.infoTitle
        self.isAccessibilityElement = true
        self.isUserInteractionEnabled = !model.isEnabled ? false : true
        self.accessibilityIdentifier = model.a11yId
        self.accessibilityLabel = model.a11yLabel
        self.accessibilityHint = model.a11yHint
        self.accessibilityTraits = .button
        self.separatorInset = .zero
    }

    private func setupView(hasInfoTitle: Bool) {
        self.addSubview(titleLabel)
        self.addSubview(infoLabelView)
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: UX.contentMargin),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: UX.contentMargin),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -UX.contentMargin),

            titleLabel.trailingAnchor.constraint(
                equalTo: infoLabelView.leadingAnchor,
                constant: -UX.infoLabelHorizontalMargin
            ),
            infoLabelView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -UX.infoLabelHorizontalMargin),
            infoLabelView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        infoLabelView.setContentCompressionResistancePriority(.required, for: .horizontal)
        infoLabelView.setContentHuggingPriority(.required, for: .horizontal)

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    // MARK: - Theme Applicable
    func applyTheme(theme: Theme) {
        guard let model else { return }
        backgroundColor = theme.colors.layer2
        if model.isActive {
            titleLabel.textColor = theme.colors.textAccent
            infoLabelView.textColor = theme.colors.textPrimary
            infoLabelView.backgroundColor = theme.colors.layerInformation
        } else if !model.isEnabled {
            titleLabel.textColor = theme.colors.textDisabled
            infoLabelView.textColor = theme.colors.textDisabled
            infoLabelView.backgroundColor = theme.colors.layer3
        } else {
            titleLabel.textColor = theme.colors.textPrimary
            infoLabelView.textColor = theme.colors.textPrimary
            infoLabelView.backgroundColor = theme.colors.layer3
        }
    }
}
