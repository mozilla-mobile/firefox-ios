// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class TabTraySelectorCell: UICollectionViewCell,
                           ReusableCell,
                           ThemeApplicable {
    private let label = UILabel()
    private let padding = UIEdgeInsets(
        top: TabTraySelectorUX.cellVerticalPadding,
        left: TabTraySelectorUX.cellHorizontalPadding,
        bottom: TabTraySelectorUX.cellVerticalPadding,
        right: TabTraySelectorUX.cellHorizontalPadding
    )

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(label)
        contentView.layer.cornerRadius = TabTraySelectorUX.cornerRadius
        contentView.layer.masksToBounds = true

        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding.top),
            label.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -padding.bottom),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding.left),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding.right)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(title: String, selected: Bool, theme: Theme?) {
        isSelected = selected
        label.text = title
        label.font = selected ? FXFontStyles.Bold.body.scaledFont() : FXFontStyles.Regular.body.scaledFont()
        applyTheme(theme: theme ?? LightTheme())
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        label.textColor = theme.colors.textPrimary
        contentView.backgroundColor = isSelected ? theme.colors.layer4 : .clear
    }
}
