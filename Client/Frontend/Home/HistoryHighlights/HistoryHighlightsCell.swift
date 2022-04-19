// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

private struct RecentlyVisitedCellUX {
    static let generalCornerRadius: CGFloat = 10
    static let heroImageDimension: CGFloat = 24
    static let shadowRadius: CGFloat = 0
    static let shadowOffset: CGFloat = 2
}

struct HistoryHighlightsViewModel {
    let title: String
    let description: String?
    let favIconImage: UIImage?
    let corners: UIRectCorner?
    let hideBottomLine: Bool
    let isFillerCell: Bool
    let shouldAddShadow: Bool

    init(title: String,
         description: String?,
         shouldHideBottomLine: Bool,
         with corners: UIRectCorner? = nil,
         and heroImage: UIImage? = nil,
         andIsFillerCell: Bool = false,
         shouldAddShadow: Bool = false) {

        self.title = title
        self.description = description
        self.hideBottomLine = shouldHideBottomLine
        self.corners = corners
        self.favIconImage = heroImage
        self.isFillerCell = andIsFillerCell
        self.shouldAddShadow = shouldAddShadow
    }

    // Filler cell init
    init(shouldHideBottomLine: Bool,
         with corners: UIRectCorner? = nil,
         shouldAddShadow: Bool) {

        self.init(title: "",
                  description: "",
                  shouldHideBottomLine: shouldHideBottomLine,
                  with: corners,
                  and: nil,
                  andIsFillerCell: true,
                  shouldAddShadow: shouldAddShadow)
    }
}

/// A cell used in FxHomeScreen's History Highlights section.
class HistoryHighlightsCell: UICollectionViewCell, ReusableCell {

    // MARK: - UI Elements
    var shadowViewLayer: CAShapeLayer?

    let heroImage: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = RecentlyVisitedCellUX.generalCornerRadius
        imageView.image = UIImage.templateImageNamed(ImageIdentifiers.stackedTabsIcon)
    }

    let itemTitle: UILabel = .build { label in
        // Limiting max size to accomodate for non-self-sizing parent cell.
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   maxSize: 23)
        label.adjustsFontForContentSizeCategory = true
    }

    let itemDescription: UILabel = .build { label in
        // Limiting max size to accomodate for non-self-sizing parent cell.
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
    var notificationCenter: NotificationCenter = NotificationCenter.default

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: .zero)

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
    public func updateCell(with options: HistoryHighlightsViewModel) {
        itemTitle.text = options.title
        if let descriptionCount = options.description {
            itemDescription.text = descriptionCount
        }
        bottomLine.alpha = options.hideBottomLine ? 0 : 1
        isFillerCell = options.isFillerCell
        itemDescription.isHidden = itemDescription.text?.isEmpty ?? true

        if let corners = options.corners {
            contentView.addRoundedCorners([corners], radius: RecentlyVisitedCellUX.generalCornerRadius)
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
    }

    // MARK: - Setup Helper methods
    private func setupLayout() {
        contentView.addSubview(heroImage)
        contentView.addSubview(textStack)
        contentView.addSubview(bottomLine)

        NSLayoutConstraint.activate([
            heroImage.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            heroImage.heightAnchor.constraint(equalToConstant: RecentlyVisitedCellUX.heroImageDimension),
            heroImage.widthAnchor.constraint(equalToConstant: RecentlyVisitedCellUX.heroImageDimension),
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
                                          height: RecentlyVisitedCellUX.shadowOffset)
        shadowLayer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
        shadowLayer.shadowRadius = RecentlyVisitedCellUX.shadowRadius

        let radiusSize = CGSize(width: RecentlyVisitedCellUX.generalCornerRadius,
                                height: RecentlyVisitedCellUX.generalCornerRadius)
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
