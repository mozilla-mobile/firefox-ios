// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

class ThemedCenteredTableViewCell: ThemedTableViewCell {
    private struct UX {
        static let labelMargin: CGFloat = 15
    }

    lazy var centeredLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = FXFontStyles.Regular.body.scaledFont()
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(centeredLabel)
    }

    func setTitle(to title: String) {
        centeredLabel.text = title
    }

    func setAccessibilities(traits: UIAccessibilityTraits, identifier: String) {
        accessibilityTraits = traits
        accessibilityIdentifier = identifier
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            centeredLabel.topAnchor.constraint(
                greaterThanOrEqualTo: contentView.topAnchor,
                constant: UX.labelMargin),
            centeredLabel.bottomAnchor.constraint(
                greaterThanOrEqualTo: contentView.bottomAnchor,
                constant: -UX.labelMargin),
            centeredLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            centeredLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            centeredLabel.leadingAnchor.constraint(
                greaterThanOrEqualTo: contentView.leadingAnchor,
                constant: UX.labelMargin),
            centeredLabel.trailingAnchor.constraint(
                lessThanOrEqualTo: contentView.trailingAnchor,
                constant: -UX.labelMargin)
        ])
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setConstraints()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.addSubview(centeredLabel)
    }

    override func applyTheme(theme: Theme) {
        super.applyTheme(theme: theme)
        centeredLabel.textColor = theme.colors.textWarning
    }
}
