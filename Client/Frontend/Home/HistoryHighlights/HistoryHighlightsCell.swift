// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A cell used in FxHomeScreen's History Highlights section.
class HistoryHighlightsCell: BlurrableCollectionViewCell, ReusableCell {

    struct UX {
        static let verticalSpacing: CGFloat = 20
        static let horizontalSpacing: CGFloat = 16
        static let generalCornerRadius: CGFloat = 10
        static let heroImageDimension: CGFloat = 24
        static let shadowRadius: CGFloat = 4
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
                                                                   size: 12)
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
    private var cellModel: HistoryHighlightsModel?

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
        cellModel = options
        itemTitle.text = options.title

        if let descriptionCount = options.description {
            itemDescription.text = descriptionCount
            itemDescription.isHidden = false
        }

        bottomLine.alpha = options.hideBottomLine ? 0 : 1
        isFillerCell = options.isFillerCell
        accessibilityLabel = options.accessibilityLabel

        heroImage.image = UIImage.templateImageNamed(ImageIdentifiers.stackedTabsIcon)
        adjustLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        heroImage.image = nil
        itemDescription.isHidden = true

        contentView.layer.shadowRadius = 0.0
        contentView.layer.shadowOpacity = 0.0
        contentView.layer.shadowPath = nil
    }

    // MARK: - Setup Helper methods
    private func setupLayout() {
        contentView.addSubview(heroImage)
        contentView.addSubview(textStack)
        contentView.addSubview(bottomLine)

        NSLayoutConstraint.activate([
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor,
                                               constant: UX.horizontalSpacing),
            heroImage.heightAnchor.constraint(equalToConstant: UX.heroImageDimension),
            heroImage.widthAnchor.constraint(equalToConstant: UX.heroImageDimension),
            heroImage.centerYAnchor.constraint(equalTo: textStack.centerYAnchor),

            textStack.leadingAnchor.constraint(equalTo: heroImage.trailingAnchor,
                                               constant: UX.horizontalSpacing),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                constant: -UX.horizontalSpacing),
            textStack.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            bottomLine.heightAnchor.constraint(equalToConstant: 0.5),
            bottomLine.leadingAnchor.constraint(equalTo: itemTitle.leadingAnchor),
            bottomLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor,
                                                 constant: -UX.horizontalSpacing),
            bottomLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    private func setupShadow(_ shouldAddShadow: Bool, cornersToRound: CACornerMask?) {
        contentView.layer.maskedCorners = cornersToRound ?? .layerMaxXMinYCorner
        contentView.layer.cornerRadius = UX.generalCornerRadius

        var needsShadow = shouldAddShadow
        if let cornersToRound = cornersToRound {
            needsShadow = cornersToRound.contains(.layerMinXMaxYCorner) ||
                cornersToRound.contains(.layerMaxXMaxYCorner) ||
                shouldAddShadow
        }

        if needsShadow {
            let size: CGFloat = 5
            let distance: CGFloat = 0
            let rect = CGRect(
                x: -size,
                y: contentView.frame.height - (size * 0.4) + distance,
                width: contentView.frame.width + size * 2,
                height: size
            )

            contentView.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
            contentView.layer.shadowRadius = UX.shadowRadius
            contentView.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
            contentView.layer.shadowPath = UIBezierPath(ovalIn: rect).cgPath
        }
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
            contentView.backgroundColor = .clear
            contentView.layer.maskedCorners = cellModel?.corners ?? .layerMaxXMinYCorner
            contentView.layer.cornerRadius = UX.generalCornerRadius
        } else {
            contentView.removeVisualEffectView()
            contentView.backgroundColor = LegacyThemeManager.instance.current.homePanel.topSitesContainerView
            setupShadow(cellModel?.shouldAddShadow ?? false, cornersToRound: cellModel?.corners)
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
