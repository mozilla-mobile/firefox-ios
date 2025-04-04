// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared
import SiteImageView

protocol TabCellDelegate: AnyObject {
    func tabCellDidClose(for tabUUID: TabUUID)
}

class TabCell: UICollectionViewCell, ThemeApplicable, ReusableCell {
    struct UX {
        static let borderWidth: CGFloat = 3.0
        static let cornerRadius: CGFloat = 16
        static let subviewDefaultPadding: CGFloat = 6.0
        static let faviconYOffset: CGFloat = 10.0
        static let faviconSize: CGFloat = 20
        static let closeButtonSize: CGFloat = 32
        static let textBoxHeight: CGFloat = 44
        static let closeButtonTrailing: CGFloat = 4
        static let closeButtonEdgeInset = NSDirectionalEdgeInsets(top: 12,
                                                                  leading: 12,
                                                                  bottom: 12,
                                                                  trailing: 12)

        // Using the same sizes for fallback favicon as the top sites on the homepage
        static let imageBackgroundSize = TopSiteItemCell.UX.imageBackgroundSize
        static let topSiteIconSize = TopSiteItemCell.UX.iconSize
    }
    // MARK: - Properties

    private(set) var tabModel: TabModel?

    var isSelectedTab: Bool { return tabModel?.isSelected ?? false }
    var animator: SwipeAnimator?
    weak var delegate: TabCellDelegate?

    private lazy var smallFaviconView: FaviconImageView = .build()
    private lazy var favicon: FaviconImageView = .build()
    private lazy var headerView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    // MARK: - UI

    private lazy var backgroundHolder: UIView = .build { view in
        view.layer.cornerRadius = UX.cornerRadius
        view.clipsToBounds = true
    }

    private lazy var faviconBG: UIView = .build { view in
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        view.layer.borderWidth = HomepageViewModel.UX.generalBorderWidth
        view.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        view.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
        view.isHidden = true
    }

    private lazy var screenshotView: UIImageView = .build { view in
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
    }

    private lazy var titleText: UILabel = .build { label in
        label.numberOfLines = 1
        label.font = FXFontStyles.Bold.caption1.scaledFont()
        label.adjustsFontForContentSizeCategory = true
        label.isAccessibilityElement = false
    }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross), for: [])
        button.imageView?.contentMode = .scaleAspectFit
        button.contentMode = .center
        var configuration = UIButton.Configuration.plain()
        configuration.contentInsets = UX.closeButtonEdgeInset
        button.configuration = configuration
    }

    // MARK: - Initializer

    override init(frame: CGRect) {
        super.init(frame: frame)
        animator = SwipeAnimator(animatingView: self)
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        contentView.addSubview(backgroundHolder)

        faviconBG.addSubview(smallFaviconView)
        backgroundHolder.addSubviews(screenshotView, faviconBG, headerView)

        accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: .TabTrayCloseAccessibilityCustomAction,
                                        target: animator,
                                        selector: #selector(SwipeAnimator.closeWithoutGesture))
        ]

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.contentView.addSubview(closeButton)
        headerView.contentView.addSubview(titleText)
        headerView.contentView.addSubview(favicon)

        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not yet supported") }

    // MARK: - Configuration
    func configure(with tabModel: TabModel, theme: Theme?, delegate: TabCellDelegate, a11yId: String) {
        self.tabModel = tabModel
        self.delegate = delegate

        if let swipeAnimatorDelegate = delegate as? SwipeAnimatorDelegate {
            animator?.delegate = swipeAnimatorDelegate
        }

        animator?.animateBackToCenter()

        titleText.text = tabModel.tabTitle
        accessibilityLabel = getA11yTitleLabel(tabModel: tabModel)
        isAccessibilityElement = true
        accessibilityHint = .TabTraySwipeToCloseAccessibilityHint
        accessibilityIdentifier = a11yId

        let identifier = StandardImageIdentifiers.Large.globe
        if let globeFavicon = UIImage(named: identifier)?.withRenderingMode(.alwaysTemplate) {
            favicon.manuallySetImage(globeFavicon)
        }

        if !tabModel.isFxHomeTab, let tabURL = tabModel.url?.absoluteString {
            favicon.setFavicon(FaviconImageViewModel(siteURLString: tabURL))
        }

        updateUIForSelectedState(tabModel.isSelected,
                                 isPrivate: tabModel.isPrivate,
                                 theme: theme)

        configureScreenshot(tabModel: tabModel)

        if let theme {
            applyTheme(theme: theme)
        }
    }

    // MARK: - Actions

    @objc
    func close() {
        guard let tabModel = tabModel else { return }
        delegate?.tabCellDidClose(for: tabModel.tabUUID)
    }

    // MARK: - ThemeApplicable

    func applyTheme(theme: Theme) {
        headerView.effect = UIBlurEffect(style: theme.type.tabTitleBlurStyle())
        backgroundHolder.backgroundColor = theme.colors.layer1
        closeButton.tintColor = theme.colors.indicatorActive
        titleText.textColor = theme.colors.textPrimary
        screenshotView.backgroundColor = theme.colors.layer1
        favicon.tintColor = theme.colors.textPrimary
        smallFaviconView.tintColor = theme.colors.textPrimary
    }

    // MARK: - Configuration

    private func configureScreenshot(tabModel: TabModel) {
        if let url = tabModel.url,
           isInternal(url: url),
           tabModel.hasHomeScreenshot {
            // Regular screenshot for home or internal url when tab has home screenshot
            let defaultImage = UIImage(named: StandardImageIdentifiers.Large.globe)?
                .withRenderingMode(.alwaysTemplate)
            smallFaviconView.manuallySetImage(defaultImage ?? UIImage())
            screenshotView.image = tabModel.screenshot
        } else if let url = tabModel.url,
                  !isInternal(url: url),
                  tabModel.hasHomeScreenshot {
            // Favicon or letter image when home screenshot is present for a regular (non-internal) url
            let defaultImage = UIImage(
                named: StandardImageIdentifiers.Large.globe
            )?.withRenderingMode(.alwaysTemplate)
            smallFaviconView.manuallySetImage(defaultImage ?? UIImage())
            faviconBG.isHidden = false
            screenshotView.image = nil
        } else if let tabScreenshot = tabModel.screenshot {
            // Use Tab screenshot when available
            screenshotView.image = tabScreenshot
        } else {
            // Favicon or letter image when tab screenshot isn't available
            faviconBG.isHidden = false
            screenshotView.image = nil

            if let tabURL = tabModel.url?.absoluteString {
                smallFaviconView.setFavicon(FaviconImageViewModel(siteURLString: tabURL))
            }
        }
    }

    private func isInternal(url: URL) -> Bool {
        return url.absoluteString.starts(with: "internal")
    }

    private func updateUIForSelectedState(_ selected: Bool,
                                          isPrivate: Bool,
                                          theme: Theme?) {
        guard let theme = theme else { return }
        if selected {
            layoutMargins = UIEdgeInsets(top: UX.borderWidth,
                                         left: UX.borderWidth,
                                         bottom: UX.borderWidth,
                                         right: UX.borderWidth)
            layer.borderColor = (isPrivate ? theme.colors.borderAccentPrivate : theme.colors.borderAccent).cgColor
            layer.borderWidth = UX.borderWidth
            layer.cornerRadius = UX.cornerRadius
        } else {
            layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0
            layer.cornerRadius = UX.cornerRadius
        }
    }

    // MARK: - UICollectionViewCell

    override func prepareForReuse() {
        // Reset any close animations.
        super.prepareForReuse()
        screenshotView.image = nil
        backgroundHolder.transform = .identity
        backgroundHolder.alpha = 1
        faviconBG.isHidden = true
        layer.shadowOffset = .zero
        layer.shadowPath = nil
        layer.shadowOpacity = 0
        isHidden = false
    }

    // MARK: - Auto Layout

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            backgroundHolder.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundHolder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundHolder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            backgroundHolder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            headerView.topAnchor.constraint(equalTo: backgroundHolder.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: backgroundHolder.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: backgroundHolder.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: UX.textBoxHeight),

            // Parts of the header view
            favicon.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: UX.subviewDefaultPadding),
            favicon.topAnchor.constraint(
                equalTo: headerView.topAnchor,
                constant: (UX.textBoxHeight - UX.faviconSize) / 2.0
            ),
            favicon.heightAnchor.constraint(equalToConstant: UX.faviconSize),
            favicon.widthAnchor.constraint(equalToConstant: UX.faviconSize),

            closeButton.heightAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalToConstant: UX.closeButtonSize),
            closeButton.centerYAnchor.constraint(equalTo: headerView.contentView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor,
                                                  constant: -UX.closeButtonTrailing),

            titleText.leadingAnchor.constraint(equalTo: favicon.trailingAnchor,
                                               constant: UX.subviewDefaultPadding),
            titleText.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor,
                                                constant: UX.subviewDefaultPadding),
            titleText.topAnchor.constraint(equalTo: headerView.contentView.topAnchor),
            titleText.bottomAnchor.constraint(equalTo: headerView.contentView.bottomAnchor),

            // Screenshot either shown or favicon takes its place as fallback
            screenshotView.topAnchor.constraint(equalTo: headerView.contentView.bottomAnchor),
            screenshotView.leadingAnchor.constraint(equalTo: backgroundHolder.leadingAnchor),
            screenshotView.trailingAnchor.constraint(equalTo: backgroundHolder.trailingAnchor),
            screenshotView.bottomAnchor.constraint(equalTo: backgroundHolder.bottomAnchor),

            faviconBG.centerYAnchor.constraint(equalTo: backgroundHolder.centerYAnchor, constant: UX.faviconYOffset),
            faviconBG.centerXAnchor.constraint(equalTo: backgroundHolder.centerXAnchor),
            faviconBG.heightAnchor.constraint(equalToConstant: UX.imageBackgroundSize.height),
            faviconBG.widthAnchor.constraint(equalToConstant: UX.imageBackgroundSize.width),

            smallFaviconView.heightAnchor.constraint(equalToConstant: UX.topSiteIconSize.height),
            smallFaviconView.widthAnchor.constraint(equalToConstant: UX.topSiteIconSize.width),
            smallFaviconView.centerYAnchor.constraint(equalTo: faviconBG.centerYAnchor),
            smallFaviconView.centerXAnchor.constraint(equalTo: faviconBG.centerXAnchor),
        ])
    }

    // MARK: - Accessibility

    override func accessibilityScroll(_ direction: UIAccessibilityScrollDirection) -> Bool {
        var right: Bool
        switch direction {
        case .left:
            right = false
        case .right:
            right = true
        default:
            return false
        }
        animator?.close(right: right)
        return true
    }

    private func getA11yTitleLabel(tabModel: TabModel) -> String? {
        let baseName = tabModel.tabTitle

        if isSelectedTab, !baseName.isEmpty {
            return baseName + ". " + String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else if isSelectedTab {
            return String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else {
            return baseName
        }
    }
}
