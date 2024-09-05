// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

class BlockedTrackerCell: UITableViewCell,
                          ReusableCell {
    private struct UX {
        static let imageMargins: CGFloat = 10
        static let textVerticalDistance: CGFloat = 11
    }

    private let trackerImageView: UIImageView = .build { image in
        image.contentMode = .scaleAspectFit
        image.clipsToBounds = true
        image.layer.masksToBounds = true
        image.layer.cornerRadius = 5
    }

    private let trackerLabel: UILabel = .build { label in
        label.font = FXFontStyles.Regular.subheadline.scaledFont()
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
    }

    public let dividerView: UIView = .build { _ in }
    private var trackerImageViewHeightConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        contentView.addSubview(trackerImageView)
        contentView.addSubview(trackerLabel)
        contentView.addSubview(dividerView)

        trackerImageViewHeightConstraint = trackerImageView.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.iconSize)
        NSLayoutConstraint.activate([
            trackerImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            trackerImageView.leadingAnchor.constraint(
                equalTo: contentView.leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            trackerImageView.heightAnchor.constraint(equalTo: trackerImageView.widthAnchor),
            trackerImageViewHeightConstraint!,

            trackerLabel.leadingAnchor.constraint(
                equalTo: trackerImageView.trailingAnchor,
                constant: UX.imageMargins
            ),
            trackerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            trackerLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            trackerLabel.topAnchor.constraint(
                equalTo: contentView.topAnchor,
                constant: UX.textVerticalDistance
            ),
            trackerLabel.bottomAnchor.constraint(
                equalTo: contentView.bottomAnchor,
                constant: -UX.textVerticalDistance
            ),

            dividerView.leadingAnchor.constraint(equalTo: trackerLabel.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: trackerLabel.trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            dividerView.heightAnchor.constraint(equalToConstant: TPMenuUX.UX.Line.height),
        ])
    }

    func configure(with item: BlockedTrackerItem, hideDivider: Bool) {
        trackerImageView.image = item.image
        trackerLabel.text = item.title
        dividerView.isHidden = hideDivider

        let iconSize = TPMenuUX.UX.iconSize
        let scaledIconSize = min(UIFontMetrics.default.scaledValue(for: iconSize), 2 * iconSize)

        trackerImageViewHeightConstraint?.constant = scaledIconSize
    }

    func applyTheme(theme: Theme) {
        trackerLabel.textColor = theme.colors.textPrimary
        trackerImageView.tintColor = theme.colors.iconPrimary
        dividerView.backgroundColor = theme.colors.borderPrimary
    }
}
