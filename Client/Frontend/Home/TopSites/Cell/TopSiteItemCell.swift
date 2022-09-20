// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import Storage
import UIKit

/// The TopSite cell that appears in the ASHorizontalScrollView.
class TopSiteItemCell: UICollectionViewCell, ReusableCell {

    // MARK: - Variables

    private var homeTopSite: TopSite?
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    struct UX {
        static var borderColor: UIColor { return .theme.ecosia.secondaryButton }
        static let borderWidth: CGFloat = 0.5
        static let cellCornerRadius: CGFloat = 26
        static let titleOffset: CGFloat = 4
        static let iconSize = CGSize(width: 32, height: 32)
        static let iconCornerRadius: CGFloat = 4
        static let imageBackgroundSize = CGSize(width: 52, height: 52)
        static let overlayColor = UIColor(white: 0.0, alpha: 0.25)
        static let pinAlignmentSpacing: CGFloat = 2
        static let pinIconSize: CGSize = CGSize(width: 12, height: 12)
        static let shadowRadius: CGFloat = 6
        static let topSpace: CGFloat = 8
        static let textSafeSpace: CGFloat = 4
        static let bottomSpace: CGFloat = 10
    }

    private lazy var imageView: UIImageView = .build { imageView in
        imageView.layer.cornerRadius = UX.iconCornerRadius
        imageView.layer.masksToBounds = true
    }

    /* Ecosia
    // Holds the title and the pin image of the top site
    private lazy var titlePinWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
    }

    // Holds the titlePinWrapper and the Sponsored text for a sponsored tile
    private lazy var descriptionWrapper: UIStackView = .build { stackView in
        stackView.backgroundColor = .clear
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.distribution = .fillProportionally
    }
     */

    /* Ecosia
    private lazy var pinViewHolder: UIView = .build { view in
        view.isHidden = true
    }
     */

    private lazy var pinImageView: UIImageView = .build { imageView in
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.pinSmall)
        imageView.isHidden = true
    }

    private lazy var titleLabel: UILabel = .build { titleLabel in
        titleLabel.textAlignment = .center
        titleLabel.font = .preferredFont(forTextStyle: .footnote)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.allowsDefaultTighteningForTruncation = true
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + TopSiteItemCell.UX.shadowRadius
        titleLabel.numberOfLines = 2
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.setContentHuggingPriority(UILayoutPriority(1000), for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    /* Ecosia
    private lazy var sponsoredLabel: UILabel = .build { sponsoredLabel in
        sponsoredLabel.textAlignment = .center
        sponsoredLabel.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                            maxSize: 26)
        sponsoredLabel.adjustsFontForContentSizeCategory = true
        sponsoredLabel.preferredMaxLayoutWidth = UX.imageBackgroundSize.width + TopSiteItemCell.UX.shadowRadius
        sponsoredLabel.numberOfLines = 1
    }
     */

    private lazy var faviconBG: UIView = .build { view in
        view.layer.cornerRadius = UX.cellCornerRadius
        /* Ecosia
        view.layer.borderWidth = UX.borderWidth
        view.layer.borderColor = UX.borderColor.cgColor

        view.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        view.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        let shadowRect = CGRect(width: UX.imageBackgroundSize.width, height: UX.imageBackgroundSize.height)
        view.layer.shadowPath = UIBezierPath(rect: shadowRect).cgPath
        view.layer.shadowRadius = UX.shadowRadius
        */
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
        // Ecosia // sponsoredLabel.text = nil
        // Ecosia // pinViewHolder.isHidden = true
        pinImageView.isHidden = true
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        selectedOverlay.isHidden = true
    }

    // MARK: - Public methods

    func configure(_ topSite: TopSite, position: Int) {
        homeTopSite = topSite
        titleLabel.text = topSite.title
        let words = titleLabel.text?.components(separatedBy: .whitespacesAndNewlines).count ?? 0
        titleLabel.numberOfLines = min(max(words, 1), 2)
        accessibilityLabel = topSite.accessibilityLabel

        imageView.setFaviconOrDefaultIcon(forSite: topSite.site) {}

        configurePinnedSite(topSite)
        // Ecosia // configureSponsoredSite(topSite)

        applyTheme()
    }

    // MARK: - Setup Helper methods

    private func setupLayout() {
        /* Ecosia
        titlePinWrapper.addArrangedSubview(pinViewHolder)
        titlePinWrapper.addArrangedSubview(titleLabel)
        pinViewHolder.addSubview(pinImageView)

        descriptionWrapper.addArrangedSubview(titlePinWrapper)
        descriptionWrapper.addArrangedSubview(sponsoredLabel)
        contentView.addSubview(descriptionWrapper)
         */

        faviconBG.addSubview(imageView)
        contentView.addSubview(faviconBG)
        contentView.addSubview(selectedOverlay)
        contentView.addSubview(pinImageView)
        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: faviconBG.bottomAnchor, constant: UX.topSpace),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -UX.bottomSpace),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -UX.bottomSpace, priority: .defaultHigh),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: UX.textSafeSpace),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -UX.textSafeSpace),

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

            pinImageView.leadingAnchor.constraint(equalTo: faviconBG.leadingAnchor),
            pinImageView.topAnchor.constraint(equalTo: faviconBG.topAnchor),
            pinImageView.widthAnchor.constraint(equalToConstant: UX.pinIconSize.width),
            pinImageView.heightAnchor.constraint(equalToConstant: UX.pinIconSize.height),
        ])
    }

    private func configurePinnedSite(_ topSite: TopSite) {
        guard topSite.isPinned else { return }
        // Ecosia // pinViewHolder.isHidden = false
        pinImageView.isHidden = false
    }

    /* Ecosia
    private func configureSponsoredSite(_ topSite: TopSite) {
        guard topSite.isSponsoredTile else { return }

        sponsoredLabel.text = topSite.sponsoredText
    }
     */
}

// MARK: NotificationThemeable
extension TopSiteItemCell: NotificationThemeable {
    func applyTheme() {
        pinImageView.tintColor = UIColor.theme.homePanel.topSitePin
        faviconBG.backgroundColor = .theme.ecosia.secondaryButton
        selectedOverlay.backgroundColor = UX.overlayColor
        titleLabel.backgroundColor = UIColor.clear
        titleLabel.textColor = UIColor.theme.ecosia.primaryText
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
