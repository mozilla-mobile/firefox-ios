// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

class BlockedTrackersHeaderView: UITableViewHeaderFooterView,
                                 ReusableCell {
    let totalTrackersBlockedLabel: UILabel = .build { label in
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .left
        label.font = FXFontStyles.Regular.caption1.scaledFont()
        label.numberOfLines = 2
        label.accessibilityTraits.insert(.header)
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        accessibilityIdentifier = AccessibilityIdentifiers.EnhancedTrackingProtection.BlockedTrackers.headerView
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(totalTrackersBlockedLabel)

        NSLayoutConstraint.activate([
            totalTrackersBlockedLabel.leadingAnchor.constraint(
                equalTo: leadingAnchor,
                constant: TPMenuUX.UX.horizontalMargin
            ),
            totalTrackersBlockedLabel.trailingAnchor.constraint(
                equalTo: trailingAnchor,
                constant: -TPMenuUX.UX.horizontalMargin
            ),
            totalTrackersBlockedLabel.topAnchor.constraint(
                equalTo: topAnchor,
                constant: TPMenuUX.UX.connectionDetailsHeaderMargins
            ),
            totalTrackersBlockedLabel.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: -TPMenuUX.UX.connectionDetailsHeaderMargins
            )
        ])
    }

    func applyTheme(theme: Theme) {
        totalTrackersBlockedLabel.textColor = theme.colors.textSecondary
    }
}
