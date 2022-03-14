// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import SDWebImage
import Storage

/// The TopSite cell that appears in the ASHorizontalScrollView.
class TopSiteItemCell: UICollectionViewCell {

    struct UX {
        static let titleHeight: CGFloat = 20
        static let cellCornerRadius: CGFloat = 8
        static let titleOffset: CGFloat = 4
        static let overlayColor = UIColor(white: 0.0, alpha: 0.25)
        static let iconSize = CGSize(width: 36, height: 36)
        static let iconCornerRadius: CGFloat = 4
        static let backgroundSize = CGSize(width: 60, height: 60)
        static let shadowRadius: CGFloat = 6
        static let borderColor = UIColor(white: 0, alpha: 0.1)
        static let borderWidth: CGFloat = 0.5
        static let pinIconSize: CGSize = CGSize(width: 12, height: 12)
        static let cellSize: CGSize = CGSize(width: 65, height: 80)
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.layer.cornerRadius = UX.iconCornerRadius
        imageView.layer.masksToBounds = true
    }

    private lazy var titleWrapper: UIView = .build { view in
        view.backgroundColor = .clear
    }

    private lazy var pinViewHolder: UIView = .build { view in
        view.isHidden = true
    }

    private lazy var pinImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.pinSmall)
    }

    lazy private var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        titleLabel.preferredMaxLayoutWidth = UX.backgroundSize.width + TopSiteItemCell.UX.shadowRadius
        titleLabel.numberOfLines = 0
    }

    lazy private var faviconBG: UIView = .build { view in
        view.layer.cornerRadius = UX.cellCornerRadius
        view.layer.borderWidth = UX.borderWidth
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = UX.shadowRadius
    }

    private lazy var selectedOverlay: UIView = .build { selectedOverlay in
        selectedOverlay.isHidden = true
        selectedOverlay.layer.cornerRadius = UX.cellCornerRadius
    }

    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell
        contentView.addSubview(titleWrapper)
        titleWrapper.addSubview(titleLabel)
        titleWrapper.addSubview(pinViewHolder)
        contentView.addSubview(faviconBG)
        faviconBG.addSubview(imageView)
        contentView.addSubview(selectedOverlay)

        NSLayoutConstraint.activate([
            titleWrapper.topAnchor.constraint(equalTo: faviconBG.bottomAnchor, constant: 8),
            titleWrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleWrapper.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleWrapper.widthAnchor.constraint(lessThanOrEqualToConstant: UX.backgroundSize.width + 20),

            faviconBG.topAnchor.constraint(equalTo: contentView.topAnchor),
            faviconBG.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            faviconBG.widthAnchor.constraint(equalToConstant: UX.backgroundSize.width),
            faviconBG.heightAnchor.constraint(equalToConstant: UX.backgroundSize.height),

            imageView.widthAnchor.constraint(equalToConstant: UX.iconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: UX.iconSize.height),
            imageView.centerXAnchor.constraint(equalTo: faviconBG.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: faviconBG.centerYAnchor),

            selectedOverlay.topAnchor.constraint(equalTo: faviconBG.topAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: faviconBG.leadingAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: faviconBG.trailingAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: faviconBG.bottomAnchor),

            pinViewHolder.leadingAnchor.constraint(equalTo: titleWrapper.leadingAnchor),
            pinViewHolder.topAnchor.constraint(equalTo: titleWrapper.topAnchor),

            titleLabel.topAnchor.constraint(equalTo: titleWrapper.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: pinViewHolder.trailingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleWrapper.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: titleWrapper.bottomAnchor)
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        contentView.backgroundColor = UIColor.clear
        imageView.image = nil
        imageView.backgroundColor = UIColor.clear
        faviconBG.backgroundColor = UIColor.clear

        pinViewHolder.isHidden = true
        pinImageView.removeFromSuperview()
        imageView.sd_cancelCurrentImageLoad()
        titleLabel.text = ""
    }

    func configure(_ topSite: HomeTopSite) {
        titleLabel.text = topSite.title
        accessibilityLabel = titleLabel.text

        imageView.image = topSite.image
        topSite.imageLoaded = { image in
            self.imageView.image = image
        }

        configurePinnedSite(topSite)
        applyTheme()
    }

    private func configurePinnedSite(_ topSite: HomeTopSite) {
        guard topSite.isPinned else { return }
        pinViewHolder.addSubview(pinImageView)
        pinViewHolder.isHidden = false

        NSLayoutConstraint.activate([
            pinViewHolder.leadingAnchor.constraint(equalTo: pinImageView.leadingAnchor),
            pinViewHolder.trailingAnchor.constraint(equalTo: pinImageView.trailingAnchor, constant: UX.titleOffset),
            pinViewHolder.topAnchor.constraint(equalTo: pinImageView.topAnchor),

            pinImageView.widthAnchor.constraint(equalToConstant: UX.pinIconSize.width),
            pinImageView.heightAnchor.constraint(equalToConstant: UX.pinIconSize.height),
        ])
    }
}

// MARK: NotificationThemeable
extension TopSiteItemCell: NotificationThemeable {
    func applyTheme() {
        pinImageView.tintColor = UIColor.theme.homePanel.topSitePin
        titleLabel.textColor = UIColor.theme.homePanel.topSiteDomain
        faviconBG.backgroundColor = UIColor.theme.homePanel.shortcutBackground
        faviconBG.layer.borderColor = UX.borderColor.cgColor
        faviconBG.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        faviconBG.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        selectedOverlay.backgroundColor = UX.overlayColor
        titleLabel.backgroundColor = UIColor.clear
    }
}
