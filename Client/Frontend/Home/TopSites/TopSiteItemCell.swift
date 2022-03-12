// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import SDWebImage
import Storage

/// The TopSite cell that appears in the ASHorizontalScrollView.
class TopSiteItemCell: UICollectionViewCell, NotificationThemeable {

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

    lazy var imageView: UIImageView = .build { imageView in
        imageView.layer.cornerRadius = UX.iconCornerRadius
        imageView.layer.masksToBounds = true
    }

    lazy var titleWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.axis = .horizontal
        stackView.spacing = UX.titleOffset
    }

    lazy var pinViewHolder: UIView = .build { _ in }

    lazy var pinImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.pinSmall)
    }

    lazy fileprivate var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
        titleLabel.preferredMaxLayoutWidth = UX.backgroundSize.width + TopSiteItemCell.UX.shadowRadius
    }

    lazy private var faviconBG: UIView = .build { view in
        view.layer.cornerRadius = UX.cellCornerRadius
        view.layer.borderWidth = UX.borderWidth
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = UX.shadowRadius
    }

    lazy var selectedOverlay: UIView = .build { selectedOverlay in
        selectedOverlay.isHidden = true
    }

    override var isSelected: Bool {
        didSet {
            self.selectedOverlay.isHidden = !isSelected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        // TODO: Laurie - identifier
        accessibilityIdentifier = "TopSite"
        contentView.addSubview(titleWrapper)
        titleWrapper.addArrangedSubview(titleLabel)
        pinViewHolder.addSubview(pinImageView)
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

            // TODO: Laurie - Fix selected overlay
            selectedOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),

            pinViewHolder.leadingAnchor.constraint(equalTo: pinImageView.leadingAnchor),
            pinViewHolder.trailingAnchor.constraint(equalTo: pinImageView.trailingAnchor),
            pinViewHolder.centerYAnchor.constraint(equalTo: pinImageView.centerYAnchor),

            pinImageView.widthAnchor.constraint(equalToConstant: UX.pinIconSize.width),
            pinImageView.heightAnchor.constraint(equalToConstant: UX.pinIconSize.height),
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

        // TODO: Laurie - fix pins not working
        pinImageView.removeFromSuperview()
        imageView.sd_cancelCurrentImageLoad()
        titleLabel.text = ""
    }

    // TODO: Laurie - fix layout when changing from home settings (2 to 4 fours for example)
    func configure(_ topSite: HomeTopSite) {
        titleLabel.text = topSite.title
        accessibilityLabel = titleLabel.text

        let words = titleLabel.text?.components(separatedBy: NSCharacterSet.whitespacesAndNewlines).count
        titleLabel.numberOfLines = words == 1 ? 1 : 2

        // If its a pinned site add a bullet point to the front
        if topSite.pinned {
            titleWrapper.addArrangedViewToTop(pinViewHolder)
        }

        imageView.image = topSite.image
        topSite.imageLoaded = { image in
            self.imageView.image = image
        }

        applyTheme()
    }

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
