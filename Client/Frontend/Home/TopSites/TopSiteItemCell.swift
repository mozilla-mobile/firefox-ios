// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import SDWebImage
import Storage
import UIKit

/// The TopSite cell that appears in the ASHorizontalScrollView.
class TopSiteItemCell: UICollectionViewCell, ReusableCell {

    // MARK: - Variables

    private var homeTopSite: HomeTopSite?
    private var titleLabelLeadingConstraint: NSLayoutConstraint?
    var notificationCenter: NotificationCenter = NotificationCenter.default

    struct UX {
        static let borderColor = UIColor(white: 0, alpha: 0.1)
        static let borderWidth: CGFloat = 0.5
        static let cellCornerRadius: CGFloat = 8
        static let titleOffset: CGFloat = 4
        static let iconSize = CGSize(width: 36, height: 36)
        static let iconCornerRadius: CGFloat = 4
        static let imageBackgroundSize = CGSize(width: 60, height: 60)
        static let overlayColor = UIColor(white: 0.0, alpha: 0.25)
        static let pinAlignmentSpacing: CGFloat = 2
        static let pinIconSize: CGSize = CGSize(width: 12, height: 12)
        static let shadowRadius: CGFloat = 6
        static let widthSafeSpace: CGFloat = 16
        static let Spacing: CGFloat = 8
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

    private lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        // Limiting max size to accomodate for non-self-sizing parent cell.
        titleLabel.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                        maxSize: 18)
        titleLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + TopSiteItemCell.UX.shadowRadius
        titleLabel.numberOfLines = 2
    }

    private lazy var faviconBG: UIView = .build { view in
        view.layer.cornerRadius = UX.cellCornerRadius
        view.layer.borderWidth = UX.borderWidth
        view.layer.borderColor = UX.borderColor.cgColor

        view.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        view.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.cornerRadius = UX.cellCornerRadius
        let shadowRect = CGRect(width: UX.imageBackgroundSize.width, height: UX.imageBackgroundSize.height)
        view.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
        view.layer.shadowRadius = UX.shadowRadius
    }

    private lazy var selectedOverlay: UIView = .build { selectedOverlay in
        selectedOverlay.isHidden = true
        selectedOverlay.layer.cornerRadius = UX.cellCornerRadius
        selectedOverlay.backgroundColor = UX.overlayColor
    }

    override var isSelected: Bool {
        didSet {
            selectedOverlay.isHidden = !isSelected
        }
    }

    override var isHighlighted: Bool {
        didSet {
            selectedOverlay.isHidden = !isHighlighted
        }
    }

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell

        applyTheme()
        setupLayout()

        setupNotifications(forObserver: self, observing: [.DisplayThemeChanged])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.backgroundColor = UIColor.clear

        titleLabel.text = nil
        titleLabelLeadingConstraint?.isActive = true

        pinViewHolder.isHidden = true
        pinImageView.removeFromSuperview()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        selectedOverlay.isHidden = true
    }

    // MARK: - Public methods

    func configure(_ topSite: HomeTopSite) {
        homeTopSite = topSite
        titleLabel.text = topSite.title
        accessibilityLabel = titleLabel.text

        imageView.image = topSite.image
        topSite.imageLoaded = { image in
            // Checks to assign image to correct cell when reusing a cell
            guard topSite.identifier == self.homeTopSite?.identifier else { return }
            self.imageView.image = image
        }

        configurePinnedSite(topSite)
        applyTheme()
    }

    // MARK: - Setup Helper methods

    private func setupLayout() {
        titleWrapper.addSubview(titleLabel)
        titleWrapper.addSubview(pinViewHolder)
        contentView.addSubview(titleWrapper)
        faviconBG.addSubview(imageView)
        contentView.addSubview(faviconBG)
        contentView.addSubview(selectedOverlay)

        NSLayoutConstraint.activate([
            titleWrapper.topAnchor.constraint(equalTo: faviconBG.bottomAnchor, constant: UX.Spacing),
            titleWrapper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            titleWrapper.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleWrapper.widthAnchor.constraint(greaterThanOrEqualToConstant: UX.imageBackgroundSize.width),
            titleWrapper.widthAnchor.constraint(lessThanOrEqualToConstant: contentView.frame.width - UX.widthSafeSpace),

            faviconBG.topAnchor.constraint(equalTo: contentView.topAnchor),
            faviconBG.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            faviconBG.widthAnchor.constraint(equalToConstant: UX.imageBackgroundSize.width),
            faviconBG.heightAnchor.constraint(equalToConstant: UX.imageBackgroundSize.height),

            imageView.widthAnchor.constraint(equalToConstant: UX.iconSize.width),
            imageView.heightAnchor.constraint(equalToConstant: UX.iconSize.height),
            imageView.centerXAnchor.constraint(equalTo: faviconBG.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: faviconBG.centerYAnchor),

            selectedOverlay.topAnchor.constraint(equalTo: faviconBG.topAnchor),
            selectedOverlay.leadingAnchor.constraint(equalTo: faviconBG.leadingAnchor),
            selectedOverlay.trailingAnchor.constraint(equalTo: faviconBG.trailingAnchor),
            selectedOverlay.bottomAnchor.constraint(equalTo: faviconBG.bottomAnchor),

            pinViewHolder.leadingAnchor.constraint(equalTo: titleWrapper.leadingAnchor),
            pinViewHolder.bottomAnchor.constraint(equalTo: titleLabel.firstBaselineAnchor, constant: UX.pinAlignmentSpacing),

            titleLabel.topAnchor.constraint(equalTo: titleWrapper.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: pinViewHolder.trailingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleWrapper.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: titleWrapper.bottomAnchor)
        ])

        titleLabel.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
        titleLabelLeadingConstraint = titleLabel.leadingAnchor.constraint(equalTo: titleWrapper.leadingAnchor)
        titleLabelLeadingConstraint?.isActive = true
    }

    private func configurePinnedSite(_ topSite: HomeTopSite) {
        guard topSite.isPinned else { return }
        pinViewHolder.addSubview(pinImageView)
        pinViewHolder.isHidden = false
        titleLabelLeadingConstraint?.isActive = false

        NSLayoutConstraint.activate([
            pinViewHolder.leadingAnchor.constraint(equalTo: pinImageView.leadingAnchor),
            pinViewHolder.trailingAnchor.constraint(equalTo: pinImageView.trailingAnchor, constant: UX.titleOffset),
            pinViewHolder.topAnchor.constraint(equalTo: pinImageView.topAnchor),
            pinViewHolder.bottomAnchor.constraint(equalTo: pinImageView.bottomAnchor),

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
        faviconBG.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        titleLabel.backgroundColor = UIColor.clear
    }
}

// MARK: - Notifiable
extension TopSiteItemCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
