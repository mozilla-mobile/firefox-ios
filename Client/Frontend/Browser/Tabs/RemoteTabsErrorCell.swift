// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class RemoteTabsErrorCell: UITableViewCell, ReusableCell, ThemeApplicable {

    struct UX {
        static let topPaddingInBetweenItems: CGFloat = 15
    }

    var theme: Theme
    private var error: RemoteTabsError

    // MARK: - UI
    private let emptyStateImageView: UIImageView = build { imageView in
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.emptySyncImageName)
    }

    private let titleLabel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.DeviceFont
        label.text = .EmptySyncedTabsPanelStateTitle
        label.textAlignment = .center
    }

    private let instructionsLabel: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.DeviceFontSmallLight
        label.textAlignment = .center
        label.numberOfLines = 0
    }

    init(error: RemoteTabsError,
         theme: Theme) {
        self.theme = theme
        self.error = error
        super.init(style: .default, reuseIdentifier: RemoteTabsErrorCell.cellIdentifier)
        selectionStyle = .none

        setupLayout()
        applyTheme(theme: theme)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        contentView.addSubviews(emptyStateImageView, titleLabel, instructionsLabel)

        NSLayoutConstraint.activate([
            emptyStateImageView.topAnchor.constraint(equalTo: contentView.topAnchor,
                                                     constant: UX.topPaddingInBetweenItems),
            emptyStateImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyStateImageView.widthAnchor.constraint(equalToConstant: 80),
            emptyStateImageView.heightAnchor.constraint(equalToConstant: 80),

            titleLabel.topAnchor.constraint(equalTo: emptyStateImageView.bottomAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            instructionsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor,
                                                  constant: 20),
            instructionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            instructionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            instructionsLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

        instructionsLabel.text = error.localizedString()
    }

    func applyTheme(theme: Theme) {
        emptyStateImageView.tintColor = theme.colors.textPrimary
        titleLabel.textColor = theme.colors.textPrimary
        instructionsLabel.textColor = theme.colors.textPrimary
        backgroundColor = theme.colors.layer3
    }
}
