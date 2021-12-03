// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared

// MARK: - Tab Tray Cell Protocol
protocol TabTrayCell where Self: UICollectionViewCell {
    /// True when the tab is the selected tab in the tray
    var isSelectedTab: Bool { get }

    /// Configure a tab cell using a Tab object, setting it's selected state at the same time
    func configureWith(tab: Tab, isSelected selected: Bool)
}

// MARK: - Tab Cell
class TabCell: UICollectionViewCell, TabTrayCell, ReusableCell {
    // MARK: - Constants
    enum Style {
        case light
        case dark
    }

    static let borderWidth: CGFloat = 3

    // MARK: - UI Vars
    lazy var backgroundHolder: UIView = .build { view in
        view.layer.cornerRadius = GridTabTrayControllerUX.CornerRadius
        view.clipsToBounds = true
        view.backgroundColor = UIColor.theme.tabTray.cellBackground
    }

    lazy private var faviconBG: UIView = .build { view in
        view.layer.cornerRadius = TopSiteCellUX.cellCornerRadius
        view.layer.borderWidth = TopSiteCellUX.borderWidth
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = TopSiteCellUX.shadowRadius
        view.backgroundColor = UIColor.theme.homePanel.shortcutBackground
        view.layer.borderColor = TopSiteCellUX.borderColor.cgColor
        view.layer.shadowColor = UIColor.theme.homePanel.shortcutShadowColor
        view.layer.shadowOpacity = UIColor.theme.homePanel.shortcutShadowOpacity
    }

    lazy var screenshotView: UIImageView = .build { view in
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.theme.tabTray.screenshotBackground
    }
    
    lazy var smallFaviconView: UIImageView = .build { view in
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.isUserInteractionEnabled = false
        view.backgroundColor = UIColor.clear
        view.layer.cornerRadius = TopSiteCellUX.iconCornerRadius
        view.layer.masksToBounds = true
    }

    lazy var titleText: UILabel = .build { label in
        label.isUserInteractionEnabled = false
        label.numberOfLines = 1
        label.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
        label.textColor = UIColor.theme.tabTray.tabTitleText
    }

    lazy var favicon: UIImageView = .build { favicon in
        favicon.backgroundColor = UIColor.clear
        favicon.layer.cornerRadius = 2.0
        favicon.layer.masksToBounds = true
    }

    lazy var closeButton: UIButton = .build { button in
        button.setImage(UIImage.templateImageNamed("tab_close"), for: [])
        button.imageView?.contentMode = .scaleAspectFit
        button.contentMode = .center
        button.tintColor = UIColor.theme.tabTray.cellCloseButton
        button.imageEdgeInsets = UIEdgeInsets(equalInset: GridTabTrayControllerUX.CloseButtonEdgeInset)
    }

    var title = UIVisualEffectView(effect: UIBlurEffect(style: UIColor.theme.tabTray.tabTitleBlur))
    var animator: SwipeAnimator?
    var isSelectedTab = false

    weak var delegate: TabCellDelegate?

    // Changes depending on whether we're full-screen or not.
    var margin = CGFloat(0)

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
    
    func setupConstraint() {
        NSLayoutConstraint.activate([
            backgroundHolder.topAnchor.constraint(equalTo: contentView.topAnchor),
            backgroundHolder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            backgroundHolder.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            backgroundHolder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),

            title.topAnchor.constraint(equalTo: backgroundHolder.topAnchor),
            title.leftAnchor.constraint(equalTo: backgroundHolder.leftAnchor),
            title.rightAnchor.constraint(equalTo: backgroundHolder.rightAnchor),
            title.heightAnchor.constraint(equalToConstant: GridTabTrayControllerUX.TextBoxHeight),

            favicon.leadingAnchor.constraint(equalTo: title.leadingAnchor, constant: 6),
            favicon.topAnchor.constraint(equalTo: title.topAnchor , constant: (GridTabTrayControllerUX.TextBoxHeight - GridTabTrayControllerUX.FaviconSize) / 2),
            favicon.heightAnchor.constraint(equalToConstant: GridTabTrayControllerUX.FaviconSize),
            favicon.widthAnchor.constraint(equalToConstant: GridTabTrayControllerUX.FaviconSize),

            closeButton.heightAnchor.constraint(equalToConstant: GridTabTrayControllerUX.CloseButtonSize),
            closeButton.widthAnchor.constraint(equalToConstant: GridTabTrayControllerUX.CloseButtonSize),
            closeButton.centerYAnchor.constraint(equalTo: title.contentView.centerYAnchor),
            closeButton.rightAnchor.constraint(equalTo: title.rightAnchor),

            titleText.leadingAnchor.constraint(equalTo: favicon.trailingAnchor, constant: 6),
            titleText.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: 6),
            titleText.centerYAnchor.constraint(equalTo: title.contentView.centerYAnchor),

            screenshotView.topAnchor.constraint(equalTo: topAnchor),
            screenshotView.leftAnchor.constraint(equalTo: backgroundHolder.leftAnchor),
            screenshotView.rightAnchor.constraint(equalTo: backgroundHolder.rightAnchor),
            screenshotView.bottomAnchor.constraint(equalTo: backgroundHolder.bottomAnchor),

            faviconBG.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 10),
            faviconBG.centerXAnchor.constraint(equalTo: centerXAnchor),
            faviconBG.heightAnchor.constraint(equalToConstant: TopSiteCellUX.backgroundSize.height),
            faviconBG.widthAnchor.constraint(equalToConstant: TopSiteCellUX.backgroundSize.width),

            smallFaviconView.heightAnchor.constraint(equalToConstant: TopSiteCellUX.iconSize.height),
            smallFaviconView.widthAnchor.constraint(equalToConstant: TopSiteCellUX.iconSize.width),
            smallFaviconView.centerYAnchor.constraint(equalTo: faviconBG.centerYAnchor),
            smallFaviconView.centerXAnchor.constraint(equalTo: faviconBG.centerXAnchor),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let shadowPath = CGRect(width: layer.frame.width + (TabCell.borderWidth * 2), height: layer.frame.height + (TabCell.borderWidth * 2))
        layer.shadowPath = UIBezierPath(roundedRect: shadowPath, cornerRadius: GridTabTrayControllerUX.CornerRadius+TabCell.borderWidth).cgPath
    }

    // MARK: - Configure tab cell with a Tab
    func configureWith(tab: Tab, isSelected selected: Bool) {
        isSelectedTab = selected

        titleText.text = getTabTrayTitle(tab: tab)
        accessibilityLabel = getA11yTitleLabel(tab: tab)
        isAccessibilityElement = true
        accessibilityHint = .TabTraySwipeToCloseAccessibilityHint

        if let favIcon = tab.displayFavicon, let url = URL(string: favIcon.url) {
            favicon.sd_setImage(with: url, placeholderImage: UIImage(named: "defaultFavicon"), options: [], completed: nil)
        } else {
            favicon.image = UIImage(named: "defaultFavicon")
            favicon.tintColor = UIColor.theme.tabTray.faviconTint
        }

        if selected {
            setTabSelected(tab.isPrivate)
        } else {
            layer.shadowOffset = .zero
            layer.shadowPath = nil
            layer.shadowOpacity = 0
        }

        faviconBG.isHidden = true

        // Regular screenshot for home or internal url when tab has home screenshot
        if let url = tab.url, let tabScreenshot = tab.screenshot, (url.absoluteString.starts(with: "internal") &&
            tab.hasHomeScreenshot) {
            screenshotView.image = tabScreenshot

        // Favicon or letter image when home screenshot is present for a regular (non-internal) url
        } else if let url = tab.url, (!url.absoluteString.starts(with: "internal") &&
            tab.hasHomeScreenshot) {
            setFaviconImage(for: tab, with: smallFaviconView)

        // Tab screenshot when available
        } else if let tabScreenshot = tab.screenshot {
            screenshotView.image = tabScreenshot

        // Favicon or letter image when tab screenshot isn't available
        } else {
            setFaviconImage(for: tab, with: smallFaviconView)
        }
    }

    override func prepareForReuse() {
        // Reset any close animations.
        super.prepareForReuse()
        backgroundHolder.transform = .identity
        backgroundHolder.alpha = 1
        self.titleText.font = DynamicFontHelper.defaultHelper.DefaultSmallFontBold
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

    @objc func close() {
        delegate?.tabCellDidClose(self)
    }

    private func setTabSelected(_ isPrivate: Bool) {
        // This creates a border around a tabcell. Using the shadow creates a border _outside_ of the tab frame.
        layer.shadowColor = (isPrivate ? UIColor.theme.tabTray.privateModePurple : UIConstants.SystemBlueColor).cgColor
        layer.shadowOpacity = 1
        layer.shadowRadius = 0 // A 0 radius creates a solid border instead of a gradient blur
        layer.masksToBounds = false
        // create a frame that is "BorderWidth" size bigger than the cell
        layer.shadowOffset = CGSize(width: -TabCell.borderWidth, height: -TabCell.borderWidth)
        let shadowPath = CGRect(width: layer.frame.width + (TabCell.borderWidth * 2), height: layer.frame.height + (TabCell.borderWidth * 2))
        layer.shadowPath = UIBezierPath(roundedRect: shadowPath, cornerRadius: GridTabTrayControllerUX.CornerRadius+TabCell.borderWidth).cgPath
    }

    func setFaviconImage(for tab: Tab, with imageView: UIImageView) {
        if let url = tab.url?.domainURL ?? tab.sessionData?.urls.last?.domainURL {
            imageView.setImageAndBackground(forIcon: tab.displayFavicon, website: url) {}
            faviconBG.isHidden = false
            screenshotView.image = nil
        }
    }
}

// MARK: - Extension Tab Tray Cell protocol
extension TabTrayCell {

    /// Use the display title unless it's an empty string, then use the base domain from the url
    func getTabTrayTitle(tab: Tab) -> String? {
        let baseDomain = tab.sessionData?.urls.last?.baseDomain ?? tab.url?.baseDomain
        var backUpName: String = "" // In case display title is empty
        if let baseDomain = baseDomain {
            backUpName = baseDomain.contains("local") ? .AppMenuOpenHomePageTitleString : baseDomain
        } else if let url = tab.url, let about = InternalURL(url)?.aboutComponent {
            backUpName = about
        }
        return tab.displayTitle.isEmpty ? backUpName : tab.displayTitle
    }

    func getA11yTitleLabel(tab: Tab) -> String? {
        let baseName = getTabTrayTitle(tab: tab)

        if isSelectedTab, let baseName = baseName, !baseName.isEmpty {
            return baseName + ". " + String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else if isSelectedTab {
            return String.TabTrayCurrentlySelectedTabAccessibilityLabel
        } else {
            return baseName
        }
    }
}
