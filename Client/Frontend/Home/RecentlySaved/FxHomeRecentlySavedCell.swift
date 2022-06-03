// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A cell used in FxHomeScreen's Recently Saved section. It holds bookmarks and reading list items.
class FxHomeRecentlySavedCell: UICollectionViewCell, ReusableCell, NotificationThemeable {

    private struct UX {
        static let generalCornerRadius: CGFloat = 12
        static let bookmarkTitleMaxFontSize: CGFloat = 43
        static let generalSpacing: CGFloat = 8
        static let heroImageSize: CGSize = CGSize(width: 150, height: 92)
        static let shadowRadius: CGFloat = 4
        static let shadowOffset: CGFloat = 2
    }

    // MARK: - UI Elements
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = UX.generalCornerRadius
        imageView.backgroundColor = .systemBackground
    }

    let itemTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   maxSize: UX.bookmarkTitleMaxFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
    }

    // MARK: - Variables
    var notificationCenter: NotificationCenter = NotificationCenter.default

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        setupLayout()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
        applyTheme()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        heroImage.image = nil
        itemTitle.text = nil
        applyTheme()
    }

    // MARK: - Helpers

    private func setupLayout() {
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        contentView.layer.shadowOffset = CGSize(width: 0, height: UX.shadowOffset)
        contentView.layer.cornerRadius = UX.generalCornerRadius
        let shadowRect = CGRect(width: UX.heroImageSize.width, height: UX.heroImageSize.height)
        contentView.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
        contentView.layer.shadowRadius = UX.shadowRadius

        contentView.addSubviews(heroImage, itemTitle)

        NSLayoutConstraint.activate([
            heroImage.topAnchor.constraint(equalTo: contentView.topAnchor),
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            heroImage.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heroImage.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            heroImage.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            itemTitle.topAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: UX.generalSpacing),
            itemTitle.leadingAnchor.constraint(equalTo: heroImage.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: heroImage.trailingAnchor),
            itemTitle.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            itemTitle.textColor = UIColor.Photon.LightGrey10
        } else {
            itemTitle.textColor = UIColor.Photon.DarkGrey90
        }
    }

}

// MARK: - Notifiable
extension FxHomeRecentlySavedCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }
}
