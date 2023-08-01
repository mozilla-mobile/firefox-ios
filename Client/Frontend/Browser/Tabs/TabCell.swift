// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared
import SiteImageView

// MARK: - Tab Tray Cell Protocol
protocol TabTrayCell where Self: UICollectionViewCell {
    /// True when the tab is the selected tab in the tray
    var isSelectedTab: Bool { get }

    /// Configure a tab cell using a Tab object, setting it's selected state at the same time
    func configureWith(tab: Tab, isSelected selected: Bool, theme: Theme)
}

protocol TabCellDelegate: AnyObject {
    func tabCellDidClose(_ cell: TabCell)
}

// MARK: - Tab Cell
class TabCell: UICollectionViewCell,
               TabTrayCell,
               ReusableCell,
               ThemeApplicable {
    // MARK: - Constants
    enum Style {
        case light
        case dark
    }

    static let borderWidth: CGFloat = 3

    // MARK: - UI Vars
    private lazy var backgroundHolder: UIView = .build { view in
        view.layer.cornerRadius = GridTabViewController.UX.cornerRadius + TabCell.borderWidth
        view.clipsToBounds = true
    }

    private lazy var faviconBG: UIView = .build { view in
        view.layer.cornerRadius = HomepageViewModel.UX.generalCornerRadius
        view.layer.borderWidth = HomepageViewModel.UX.generalBorderWidth
        view.layer.shadowOffset = HomepageViewModel.UX.shadowOffset
        view.layer.shadowRadius = HomepageViewModel.UX.shadowRadius
    }

    private lazy var screenshotView: UIImageView = .build { view in
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
    }

    private lazy var titleText: UILabel = .build { label in
        label.isUserInteractionEnabled = false
        label.numberOfLines = 1
        label.font = LegacyDynamicFontHelper.defaultHelper.DefaultSmallFontBold
    }

    private lazy var smallFaviconView: FaviconImageView = .build { _ in }
    private lazy var favicon: FaviconImageView = .build { _ in }

    private lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross), for: [])
        button.imageView?.contentMode = .scaleAspectFit
        button.contentMode = .center
        button.imageEdgeInsets = UIEdgeInsets(equalInset: GridTabViewController.UX.closeButtonEdgeInset)
    }

    // TODO: Handle visual effects theming FXIOS-5064
    private var title = UIVisualEffectView(effect: UIBlurEffect(style: UIColor.legacyTheme.tabTray.tabTitleBlur))
    var animator: SwipeAnimator?
    var isSelectedTab = false

    weak var delegate: TabCellDelegate?

    // Changes depending on whether we're full-screen or not.
    private var margin = CGFloat(0)

    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.animator = SwipeAnimator(animatingView: self)
        self.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        contentView.addSubview(backgroundHolder)

        faviconBG.addSubview(smallFaviconView)
        backgroundHolder.addSubviews(screenshotView, faviconBG)

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: .TabTrayCloseAccessibilityCustomAction, target: self.animator, selector: #selector(SwipeAnimator.closeWithoutGesture))
        ]

        backgroundHolder.addSubview(title)
        title.translatesAutoresizingMaskIntoConstraints = false
        title.contentView.addSubview(self.closeButton)
        title.contentView.addSubview(self.titleText)
        title.contentView.addSubview(self.favicon)

        setupConstraint()
    }

    private func setupConstraint() {
        NSLayoutConstraint.activate([
            backgroundHolder.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundHolder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundHolder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            backgroundHolder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            title.topAnchor.constraint(equalTo: backgroundHolder.topAnchor),
            title.leftAnchor.constraint(equalTo: backgroundHolder.leftAnchor),
            title.rightAnchor.constraint(equalTo: backgroundHolder.rightAnchor),
            title.heightAnchor.constraint(equalToConstant: GridTabViewController.UX.textBoxHeight),

            favicon.leadingAnchor.constraint(equalTo: title.leadingAnchor, constant: 6),
            favicon.topAnchor.constraint(equalTo: title.topAnchor, constant: (GridTabViewController.UX.textBoxHeight - GridTabViewController.UX.faviconSize) / 2),
            favicon.heightAnchor.constraint(equalToConstant: GridTabViewController.UX.faviconSize),
            favicon.widthAnchor.constraint(equalToConstant: GridTabViewController.UX.faviconSize),

            closeButton.heightAnchor.constraint(equalToConstant: GridTabViewController.UX.closeButtonSize),
            closeButton.widthAnchor.constraint(equalToConstant: GridTabViewController.UX.closeButtonSize),
            closeButton.centerYAnchor.constraint(equalTo: title.contentView.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: title.trailingAnchor),

            titleText.leadingAnchor.constraint(equalTo: favicon.trailingAnchor, constant: 6),
            titleText.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: 6),
            titleText.centerYAnchor.constraint(equalTo: title.contentView.centerYAnchor),

            screenshotView.topAnchor.constraint(equalTo: topAnchor),
            screenshotView.leftAnchor.constraint(equalTo: backgroundHolder.leftAnchor),
            screenshotView.rightAnchor.constraint(equalTo: backgroundHolder.rightAnchor),
            screenshotView.bottomAnchor.constraint(equalTo: backgroundHolder.bottomAnchor),

            faviconBG.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),
            faviconBG.centerXAnchor.constraint(equalTo: centerXAnchor),
            faviconBG.heightAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.height),
            faviconBG.widthAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.width),

            smallFaviconView.heightAnchor.constraint(equalToConstant: TopSiteItemCell.UX.iconSize.height),
            smallFaviconView.widthAnchor.constraint(equalToConstant: TopSiteItemCell.UX.iconSize.width),
            smallFaviconView.centerYAnchor.constraint(equalTo: faviconBG.centerYAnchor),
            smallFaviconView.centerXAnchor.constraint(equalTo: faviconBG.centerXAnchor),
        ])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    // MARK: - Configure tab cell with a Tab
    func configureWith(tab: Tab, isSelected selected: Bool, theme: Theme) {
        isSelectedTab = selected

        applyTheme(theme: theme)

        titleText.text = tab.getTabTrayTitle()
        accessibilityLabel = getA11yTitleLabel(tab: tab)
        isAccessibilityElement = true
        accessibilityHint = .TabTraySwipeToCloseAccessibilityHint

        favicon.image = UIImage(named: StandardImageIdentifiers.Large.globe)
        if !tab.isFxHomeTab, let tabURL = tab.url?.absoluteString {
            favicon.setFavicon(FaviconImageViewModel(siteURLString: tabURL))
        }

        if selected {
            setTabSelected(tab.isPrivate, theme: theme)
        } else {
            layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0
            layer.cornerRadius = GridTabViewController.UX.cornerRadius + TabCell.borderWidth
        }

        faviconBG.isHidden = true

        // Regular screenshot for home or internal url when tab has home screenshot
        if let url = tab.url, let tabScreenshot = tab.screenshot, (url.absoluteString.starts(with: "internal") &&
            tab.hasHomeScreenshot) {
            screenshotView.image = tabScreenshot

        // Favicon or letter image when home screenshot is present for a regular (non-internal) url
        } else if let url = tab.url, (!url.absoluteString.starts(with: "internal") &&
            tab.hasHomeScreenshot) {
            smallFaviconView.image = UIImage(named: StandardImageIdentifiers.Large.globe)
            faviconBG.isHidden = false
            screenshotView.image = nil

        // Tab screenshot when available
        } else if let tabScreenshot = tab.screenshot {
            screenshotView.image = tabScreenshot

        // Favicon or letter image when tab screenshot isn't available
        } else {
            faviconBG.isHidden = false
            screenshotView.image = nil

            if let tabURL = tab.url?.absoluteString {
                smallFaviconView.setFavicon(FaviconImageViewModel(siteURLString: tabURL))
            }
        }
    }

    func applyTheme(theme: Theme) {
        backgroundHolder.backgroundColor = theme.colors.layer1
        closeButton.tintColor = theme.colors.indicatorActive
        titleText.textColor = theme.colors.textPrimary
        screenshotView.backgroundColor = theme.colors.layer1
        favicon.tintColor = theme.colors.textPrimary
        smallFaviconView.tintColor = theme.colors.textPrimary
    }

    override func prepareForReuse() {
        // Reset any close animations.
        super.prepareForReuse()
        screenshotView.image = nil
        backgroundHolder.transform = .identity
        backgroundHolder.alpha = 1
        self.titleText.font = LegacyDynamicFontHelper.defaultHelper.DefaultSmallFontBold
        layer.shadowOffset = .zero
        layer.shadowPath = nil
        layer.shadowOpacity = 0
        isHidden = false
    }

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

    @objc
    func close() {
        delegate?.tabCellDidClose(self)
    }

    private func setTabSelected(_ isPrivate: Bool, theme: Theme) {
        layoutMargins = UIEdgeInsets(top: TabCell.borderWidth, left: TabCell.borderWidth, bottom: TabCell.borderWidth, right: TabCell.borderWidth)
        layer.borderColor = (isPrivate ? theme.colors.borderAccentPrivate : theme.colors.borderAccent).cgColor
        layer.borderWidth = TabCell.borderWidth
        layer.cornerRadius = GridTabViewController.UX.cornerRadius + TabCell.borderWidth
    }
}

// MARK: - Extension Tab Tray Cell protocol
extension TabTrayCell {
    func getA11yTitleLabel(tab: Tab) -> String? {
        let baseName = tab.getTabTrayTitle()

        if isSelectedTab, let baseName = baseName, !baseName.isEmpty {
            return baseName + ". " + String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else if isSelectedTab {
            return String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else {
            return baseName
        }
    }
}
