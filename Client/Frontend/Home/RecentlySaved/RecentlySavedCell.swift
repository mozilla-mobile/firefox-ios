// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A cell used in FxHomeScreen's Recently Saved section. It holds bookmarks and reading list items.
class RecentlySavedCell: UICollectionViewCell, ReusableCell, NotificationThemeable {

    private struct UX {
        static let generalCornerRadius: CGFloat = 12
        static let bookmarkTitleFontSize: CGFloat = 12
        static let generalSpacing: CGFloat = 8
        static let containerSpacing: CGFloat = 16
        static let heroImageSize: CGSize = CGSize(width: 150, height: 92)
        static let shadowRadius: CGFloat = 4
        static let shadowOffset: CGFloat = 2
    }

    // MARK: - UI Elements
    // Contains the hero image
    private var rootContainer: UIView = .build { view in
        view.backgroundColor = .white
    }

    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = UX.generalCornerRadius
        imageView.backgroundColor = .systemBackground
    }

    let itemTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: UX.bookmarkTitleFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.textColor = .label
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default

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

    func configure(site: Site, image: UIImage?) {
        itemTitle.text = site.tileURL.shortDisplayString.capitalized // site.title
        heroImage.image = image

        adjustLayout()
    }

    // MARK: - Helpers

    private func setupLayout() {
        rootContainer.layer.cornerRadius = UX.generalCornerRadius
        rootContainer.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                      cornerRadius: UX.generalCornerRadius).cgPath
        rootContainer.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        rootContainer.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        rootContainer.layer.shadowOffset = CGSize(width: 0, height: UX.shadowOffset)
        rootContainer.layer.shadowRadius = UX.shadowRadius

        contentView.addSubview(rootContainer)
        rootContainer.addSubviews(heroImage, itemTitle)

        NSLayoutConstraint.activate([
            rootContainer.topAnchor.constraint(equalTo: contentView.topAnchor),
            rootContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            rootContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            rootContainer.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            heroImage.topAnchor.constraint(equalTo: rootContainer.topAnchor, constant: UX.containerSpacing),
            heroImage.leadingAnchor.constraint(equalTo: rootContainer.leadingAnchor, constant: UX.containerSpacing),
            heroImage.trailingAnchor.constraint(equalTo: rootContainer.trailingAnchor, constant: -UX.containerSpacing),
            heroImage.heightAnchor.constraint(equalToConstant: UX.heroImageSize.height),
            heroImage.widthAnchor.constraint(equalToConstant: UX.heroImageSize.width),

            itemTitle.topAnchor.constraint(equalTo: heroImage.bottomAnchor, constant: UX.generalSpacing),
            itemTitle.leadingAnchor.constraint(equalTo: heroImage.leadingAnchor),
            itemTitle.trailingAnchor.constraint(equalTo: heroImage.trailingAnchor),
            itemTitle.bottomAnchor.constraint(equalTo: rootContainer.bottomAnchor, constant: -UX.generalSpacing)
        ])
        adjustLayout()
    }

    func adjustLayout() {
        rootContainer.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
    }

    func applyTheme() {
        if LegacyThemeManager.instance.currentName == .dark {
            itemTitle.textColor = UIColor.Photon.LightGrey10
            rootContainer.backgroundColor = UIColor.Photon.DarkGrey40
        } else {
            itemTitle.textColor = UIColor.Photon.DarkGrey90
            rootContainer.backgroundColor = .white
        }
    }
}

// MARK: - Notifiable
extension RecentlySavedCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default:
            break
        }
    }
}
