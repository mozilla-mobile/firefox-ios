// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class LegacyInactiveTabHeader: UITableViewHeaderFooterView, ReusableCell {
    var state: ExpandButtonState? {
        willSet(state) {
            moreButton.setImage(state?.image, for: .normal)
        }
    }

    lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.text = self.title
        titleLabel.font = FXFontStyles.Regular.headline.systemFont()
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.minimumScaleFactor = 0.6
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
    }

    lazy var moreButton: UIButton = .build { button in
        button.isHidden = true
        button.setImage(self.state?.image, for: .normal)
        button.contentHorizontalAlignment = .trailing
    }

    var title: String? {
        willSet(newTitle) {
            titleLabel.text = newTitle
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        moreButton.setTitle(nil, for: .normal)
        moreButton.accessibilityIdentifier = nil
        titleLabel.text = nil
        moreButton.removeTarget(nil, action: nil, for: .allEvents)
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        contentView.addSubview(titleLabel)
        contentView.addSubview(moreButton)
        moreButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        isAccessibilityElement = true
        accessibilityTraits = .button
        accessibilityIdentifier = AccessibilityIdentifiers.TabTray.InactiveTabs.headerView

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 19),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -19),
            titleLabel.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: moreButton.leadingAnchor, constant: -16),

            moreButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -28),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func applyTheme(theme: Theme) {
        titleLabel.textColor = theme.colors.textPrimary
        moreButton.tintColor = theme.colors.textPrimary
    }
}
