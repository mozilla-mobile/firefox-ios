// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A cell used in FxHomeScreen's History Highlights section.
class HistoryHighlightsCell: UICollectionViewCell, ReusableCell {

    struct UX {
        static let generalCornerRadius: CGFloat = 10
        static let heroImageDimension: CGFloat = 24
        static let shadowRadius: CGFloat = 0
        static let shadowOffset: CGFloat = 2
    }

    // MARK: - UI Elements
    var shadowViewLayer: CAShapeLayer?

    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = UX.generalCornerRadius
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.stackedTabsIcon)
    }

    let itemTitle: UILabel = .build { label in
        // Limiting max size since background/shadow of cell can't support self-sizing (shadow doesn't follow)
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   maxSize: 23)
        label.adjustsFontForContentSizeCategory = true
    }

    let itemDescription: UILabel = .build { label in
        // Limiting max size since background/shadow of cell can't support self-sizing (shadow doesn't follow)
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   maxSize: 18)
        label.adjustsFontForContentSizeCategory = true
    }

    private lazy var textStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [itemTitle, itemDescription])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        stack.alignment = .leading

        return stack
    }()

    let bottomLine: UIView = .build { line in
        line.isHidden = false
    }

    var isFillerCell: Bool = false {
        didSet {
            itemTitle.isHidden = isFillerCell
            heroImage.isHidden = isFillerCell
            bottomLine.isHidden = isFillerCell
        }
    }

    // MARK: - Variables
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

        isAccessibilityElement = true
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.HistoryHighlights.itemCell

        applyTheme()
        setupNotifications(forObserver: self,
                           observing: [.DisplayThemeChanged])
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        notificationCenter.removeObserver(self)
    }

    // MARK: - Public methods
    public func updateCell(with options: HistoryHighlightsModel) {
        itemTitle.text = options.title
        if let descriptionCount = options.description {
            itemDescription.text = descriptionCount
            itemDescription.isHidden = false
        }
        bottomLine.alpha = options.hideBottomLine ? 0 : 1
        isFillerCell = options.isFillerCell
        accessibilityLabel = options.accessibilityLabel

        if let corners = options.corners {
            addRoundedCorners([corners], radius: UX.generalCornerRadius)
        }

        if options.shouldAddShadow {
            addShadowLayer(cornersToRound: options.corners ?? UIRectCorner())
        }
        heroImage.image = UIImage.templateImageNamed(ImageIdentifiers.stackedTabsIcon)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        shadowViewLayer?.removeFromSuperlayer()
        heroImage.image = nil
        itemDescription.isHidden = true
    }

    // MARK: - Setup Helper methods
    private func setupLayout() {
        contentView.addSubview(heroImage)
        contentView.addSubview(textStack)
        contentView.addSubview(bottomLine)

        NSLayoutConstraint.activate([
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroImage.heightAnchor.constraint(equalToConstant: UX.heroImageDimension),
            heroImage.widthAnchor.constraint(equalToConstant: UX.heroImageDimension),
            heroImage.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
            bottomLine.leadingAnchor.constraint(equalTo: itemTitle.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func addShadowLayer(cornersToRound: UIRectCorner) {
        let shadowLayer = CAShapeLayer()

        shadowLayer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        shadowLayer.shadowOffset = CGSize(width: 0,
                                          height: UX.shadowOffset)
        shadowLayer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        shadowLayer.shadowRadius = UX.shadowRadius

        let radiusSize = CGSize(width: UX.generalCornerRadius,
                                height: UX.generalCornerRadius)
        shadowLayer.shadowPath = UIBezierPath(roundedRect: bounds,
                                              byRoundingCorners: cornersToRound,
                                              cornerRadii: radiusSize).cgPath
        shadowLayer.shouldRasterize = true
        shadowLayer.rasterizationScale = UIScreen.main.scale

        shadowViewLayer = shadowLayer
        layer.insertSublayer(shadowLayer, at: 0)
    }
}

extension HistoryHighlightsCell: Themeable {
    func applyTheme() {
        contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        heroImage.tintColor = UIColor.theme.homePanel.recentlyVisitedCellGroupImage
        bottomLine.backgroundColor = UIColor.theme.homePanel.recentlyVisitedCellBottomLine
    }
}

// MARK: - Notifiable
extension HistoryHighlightsCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case .DisplayThemeChanged:
            applyTheme()
        default: break
        }
    }
}
