// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A cell used in FxHomeScreen's History Highlights section.
class HistoryHighlightsCell: BlurrableCollectionViewCell, ReusableCell {

    struct UX {
        static let generalCornerRadius: CGFloat = 10
        static let heroImageDimension: CGFloat = 24
        static let shadowRadius: CGFloat = 0
        static let shadowOffset: CGFloat = 2
    }

    // MARK: - UI Elements
    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = UX.generalCornerRadius
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.stackedTabsIcon)
    }

    let itemTitle: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: 15)
        label.adjustsFontForContentSizeCategory = true
    }

    let itemDescription: UILabel = .build { label in
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .caption1,
                                                                   size: 13)
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

        setupShadow(cornersToRound: options.corners)
        heroImage.image = UIImage.templateImageNamed(ImageIdentifiers.stackedTabsIcon)
        adjustLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

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
            heroImage.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: UX.verticalSpacing),
            heroImage.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                              constant: -UX.verticalSpacing),

            textStack.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            textStack.topAnchor.constraint(greaterThanOrEqualTo: contentView.topAnchor, constant: UX.verticalSpacing),
            textStack.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor,
                                              constant: -UX.verticalSpacing),

            bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
            bottomLine.leadingAnchor.constraint(equalTo: itemTitle.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func setupShadow(cornersToRound: CACornerMask?) {
        contentView.clipsToBounds = true
        contentView.layer.maskedCorners = cornersToRound ?? .layerMaxXMinYCorner
        contentView.layer.cornerRadius = UX.generalCornerRadius

        contentView.layer.shadowPath = UIBezierPath(roundedRect: contentView.bounds,
                                                    cornerRadius: UX.generalCornerRadius).cgPath
        contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        contentView.layer.shadowOffset = CGSize(width: 0,
                                          height: UX.shadowOffset)
        contentView.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        contentView.layer.shadowRadius = UX.shadowRadius

    }

    private func applyTheme() {
        contentView.backgroundColor = UIColor.theme.homePanel.recentlySavedBookmarkCellBackground
        heroImage.tintColor = UIColor.theme.homePanel.recentlyVisitedCellGroupImage
        bottomLine.backgroundColor = UIColor.theme.homePanel.recentlyVisitedCellBottomLine
    }

    private func adjustLayout() {
        // If blur is disabled set background color
        if shouldApplyWallpaperBlur {
            contentView.addBlurEffectWithClearBackgroundAndClipping(using: .systemThickMaterial)
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = LegacyThemeManager.instance.current.homePanel.topSitesContainerView
            setupShadow(cornersToRound: nil)
        }
    }
}

// MARK: - Notifiable
extension HistoryHighlightsCell: Notifiable {
    func handleNotifications(_ notification: Notification) {
        ensureMainThread { [weak self] in
            switch notification.name {
            case .DisplayThemeChanged:
                self?.applyTheme()
            case .WallpaperDidChange:
                self?.adjustLayout()
            default: break
            }
        }
    }
}
