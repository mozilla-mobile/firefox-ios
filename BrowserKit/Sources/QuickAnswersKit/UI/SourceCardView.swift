// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

/// Displays a single source reference card with a website thumbnail, favicon, and title.
/// Corresponds to the "Tab Card" component in Figma.
final class SourceCardView: UIView, ThemeApplicable {
    struct Item {
        let title: String
        let url: URL?
        let favicon: UIImage?
        let thumbnail: UIImage?
    }

    private struct UX {
        static let thumbnailCornerRadius: CGFloat = 10.0
        static let thumbnailHeight: CGFloat = 123.0
        static let faviconSize: CGFloat = 16.0
        static let faviconCornerRadius: CGFloat = 3.0
        static let titleSpacing: CGFloat = 4.0
        static let titleTopPadding: CGFloat = 8.0
    }

    private let thumbnailImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerRadius = UX.thumbnailCornerRadius
    }
    private let faviconImageView: UIImageView = .build {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
        $0.layer.cornerRadius = UX.faviconCornerRadius
    }
    private let titleLabel: UILabel = .build {
        $0.font = .preferredFont(forTextStyle: .caption1)
        $0.numberOfLines = 1
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with item: Item) {
        thumbnailImageView.image = item.thumbnail
        faviconImageView.image = item.favicon
        titleLabel.text = item.title.isEmpty ? item.url?.host : item.title
    }

    private func setupSubviews() {
        addSubviews(thumbnailImageView, faviconImageView, titleLabel)

        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: topAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            thumbnailImageView.heightAnchor.constraint(equalToConstant: UX.thumbnailHeight),

            faviconImageView.topAnchor.constraint(
                equalTo: thumbnailImageView.bottomAnchor,
                constant: UX.titleTopPadding
            ),
            faviconImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            faviconImageView.widthAnchor.constraint(equalToConstant: UX.faviconSize),
            faviconImageView.heightAnchor.constraint(equalToConstant: UX.faviconSize),
            faviconImageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),

            titleLabel.centerYAnchor.constraint(equalTo: faviconImageView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(
                equalTo: faviconImageView.trailingAnchor,
                constant: UX.titleSpacing
            ),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])
    }

    // MARK: - ThemeApplicable
    func applyTheme(theme: any Theme) {
        thumbnailImageView.backgroundColor = theme.colors.layer3
        faviconImageView.backgroundColor = theme.colors.layer3
        titleLabel.textColor = theme.colors.textSecondary
    }
}
