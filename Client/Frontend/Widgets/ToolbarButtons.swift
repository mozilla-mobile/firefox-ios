/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public class ToolbarButton: UIButton {
    private class func createToolbarButton(
        iconForState iconForState: [UIControlState: UIImage],
        accessibilityLabel: String
    ) -> ToolbarButton {
        let button = ToolbarButton()
        for (state, icon) in iconForState { button.setImage(icon, forState: state) }
        button.accessibilityLabel = accessibilityLabel
        return button
    }

    public override func intrinsicContentSize() -> CGSize {
        return CGSize(width: 40, height: 40)
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CancelToolbarButton: ToolbarButton {
    private let sideMargin: CGFloat = 8

    override func intrinsicContentSize() -> CGSize {
        return CGSize(width: titleLabel?.intrinsicContentSize().width ?? 0 + sideMargin * 2, height: 40)
    }
}

extension CancelToolbarButton: Themeable {
    func applyTheme(themeName: String) {
        if themeName == Theme.NormalMode {
            setTitleColor(.blackColor(), forState: .Normal)
        } else if themeName == Theme.PrivateMode {
            setTitleColor(.whiteColor(), forState: .Normal)
        }
    }
}


/// Custom ToolbarButton that renders the Tab count and flip animations
class TabCountToolbarButton: ToolbarButton {
    private let tabCount = TabCountView(count: 1)

    var count: Int {
        return tabCount.count
    }

    convenience init() {
        self.init(frame: CGRect.zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tabCount)
        setupTabCountViewConstriants(tabCount)
    }

    private func setupTabCountViewConstriants(view: TabCountView) {
        view.snp_makeConstraints { make in
            make.center.equalTo(self)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCount(count: Int, animated: Bool = true) {
        if animated {
            flipAndIncrement()
        } else {
            tabCount.count = count
        }
    }

    func flipAndIncrement() {
        let newCount = count + 1
        let newCountView = TabCountView(count: newCount)
        addSubview(newCountView)
        setupTabCountViewConstriants(newCountView)
        layoutIfNeeded()

        // Instead of changing the anchorPoint of the CALayer, lets alter the rotation matrix math to be
        // a rotation around a non-origin point
        let frame = tabCount.frame
        let halfTitleHeight = CGRectGetHeight(frame) / 2

        var newFlipTransform = CATransform3DIdentity
        newFlipTransform = CATransform3DTranslate(newFlipTransform, 0, halfTitleHeight, 0)
        newFlipTransform.m34 = -1.0 / 200.0 // add some perspective
        newFlipTransform = CATransform3DRotate(newFlipTransform, CGFloat(-M_PI_2), 1.0, 0.0, 0.0)
        newCountView.layer.transform = newFlipTransform

        var oldFlipTransform = CATransform3DIdentity
        oldFlipTransform = CATransform3DTranslate(oldFlipTransform, 0, halfTitleHeight, 0)
        oldFlipTransform.m34 = -1.0 / 200.0 // add some perspective
        oldFlipTransform = CATransform3DRotate(oldFlipTransform, CGFloat(M_PI_2), 1.0, 0.0, 0.0)

        UIView.animateWithDuration(1.5,
                                   delay: 0,
                                   usingSpringWithDamping: 0.5,
                                   initialSpringVelocity: 0.0,
                                   options: UIViewAnimationOptions.CurveEaseInOut,
                                   animations: {
                                        newCountView.layer.transform = CATransform3DIdentity
                                        self.tabCount.layer.transform = oldFlipTransform
                                        self.tabCount.layer.opacity = 0

                                   },
                                   completion: { finished in
                                        self.tabCount.layer.opacity = 1
                                        self.tabCount.layer.transform = CATransform3DIdentity
                                        if finished {
                                            self.tabCount.count = newCount
                                        }
                                        newCountView.removeFromSuperview()
                                   })
    }
}

extension TabCountToolbarButton: Themeable {
    func applyTheme(themeName: String) {
        tabCount.applyTheme(themeName)
    }
}

// MARK: - Browser Toolbar Buttons
extension ToolbarButton {
    class func tabsButton() -> ToolbarButton {
        return TabCountToolbarButton()
    }

    class func cancelButton() -> ToolbarButton {
        let cancelButton = CancelToolbarButton()
        cancelButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
        let cancelTitle = NSLocalizedString("Cancel", comment: "Button label to cancel entering a URL or search query")
        cancelButton.setTitle(cancelTitle, forState: UIControlState.Normal)
        cancelButton.titleLabel?.font = UIConstants.DefaultChromeFont
        return cancelButton
    }

    class func backButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.backIcon(),
                .Highlighted: UIImage.backPressedIcon()
            ],
            accessibilityLabel: NSLocalizedString("Back", comment: "Accessibility Label for the browser toolbar Back button")
        )
    }

    class func forwardButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.forwardIcon(),
                .Highlighted: UIImage.forwardPressedIcon()
            ],
            accessibilityLabel: NSLocalizedString("Forward", comment: "Accessibility Label for the browser toolbar Forward button")
        )
    }

    class func reloadButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.reloadIcon(),
                .Highlighted: UIImage.reloadPressedIcon()
            ],
            accessibilityLabel: NSLocalizedString("Reload", comment: "Accessibility Label for the browser toolbar Reload button")
        )
    }

    class func shareButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.shareIcon(),
                .Highlighted: UIImage.sharePressedIcon()
            ],
            accessibilityLabel: NSLocalizedString("Share", comment: "Accessibility Label for the browser toolbar Share button")
        )
    }

    class func bookmarkedButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.bookmarkIcon(),
                .Highlighted: UIImage.bookmarkPressedIcon(),
                .Selected: UIImage.bookmarkSelectedIcon()
            ],
            accessibilityLabel: NSLocalizedString("Bookmark", comment: "Accessibility Label for the browser toolbar Bookmark button")
        )
    }
}

// MARK: - Panel Toolbar Buttons
extension ToolbarButton {
    class func topSitesPanelButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.topSitesPanelIcon(),
                .Selected: UIImage.topSitesPanelSelectedIcon()
            ],
            accessibilityLabel: NSLocalizedString("Top sites", comment: "Panel accessibility label")
        )
    }

    class func bookmarksPanelButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.bookmarksPanelIcon(),
                .Selected: UIImage.bookmarksPanelSelectedIcon()
            ],
            accessibilityLabel: NSLocalizedString("Bookmarks", comment: "Panel accessibility label")
        )
    }

    class func historyPanelButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.historyPanelIcon(),
                .Selected: UIImage.historyPanelSelectedIcon()
            ],
            accessibilityLabel: NSLocalizedString("History", comment: "Panel accessibility label")
        )
    }

    class func syncedTabsPanelButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.syncedTabsPanelIcon(),
                .Selected: UIImage.syncedTabsPanelSelectedIcon()
            ],
            accessibilityLabel: NSLocalizedString("Synced tabs", comment: "Panel accessibility label")
        )
    }

    class func readingListPanelButton() -> ToolbarButton {
        return createToolbarButton(
            iconForState: [
                .Normal: UIImage.readingListPanelIcon(),
                .Selected: UIImage.readingListPanelSelectedIcon()
            ],
            accessibilityLabel: NSLocalizedString("Reading list", comment: "Panel accessibility label")
        )
    }
}

extension UIControlState: Hashable {
    public var hashValue: Int {
        return Int(rawValue)
    }
}

// MARK: - Browser Icons
extension UIImage {
    class func backIcon() -> UIImage { return UIImage(named: "back")! }
    class func backPressedIcon() -> UIImage { return UIImage(named: "backPressed")! }

    class func forwardIcon() -> UIImage { return UIImage(named: "forward")! }
    class func forwardPressedIcon() -> UIImage { return UIImage(named: "forwardPressed")! }

    class func reloadIcon() -> UIImage { return UIImage(named: "reload")! }
    class func reloadPressedIcon() -> UIImage { return UIImage(named: "reloadPressed")! }

    class func stopIcon() -> UIImage { return UIImage(named: "stop")! }
    class func stopPressedIcon() -> UIImage { return UIImage(named: "stopPressed")! }

    class func shareIcon() -> UIImage { return UIImage(named: "send")! }
    class func sharePressedIcon() -> UIImage { return UIImage(named: "sendPressed")! }

    class func bookmarkIcon() -> UIImage { return UIImage(named: "bookmark")! }
    class func bookmarkPressedIcon() -> UIImage { return UIImage(named: "bookmarkHighlighted")! }
    class func bookmarkSelectedIcon() -> UIImage { return UIImage(named: "bookmarked")! }
}

// MARK: - Panel Icons
extension UIImage {
    class func topSitesPanelIcon() -> UIImage { return UIImage(named: "panelIconTopSites")! }
    class func topSitesPanelSelectedIcon() -> UIImage { return UIImage(named: "panelIconTopSitesSelected")! }

    class func bookmarksPanelIcon() -> UIImage { return UIImage(named: "panelIconBookmarks")! }
    class func bookmarksPanelSelectedIcon() -> UIImage { return UIImage(named: "panelIconBookmarksSelected")! }

    class func historyPanelIcon() -> UIImage { return UIImage(named: "panelIconHistory")! }
    class func historyPanelSelectedIcon() -> UIImage { return UIImage(named: "panelIconHistorySelected")! }

    class func syncedTabsPanelIcon() -> UIImage { return UIImage(named: "panelIconSyncedTabs")! }
    class func syncedTabsPanelSelectedIcon() -> UIImage { return UIImage(named: "panelIconSyncedTabsSelected")! }

    class func readingListPanelIcon() -> UIImage { return UIImage(named: "panelIconReadingList")! }
    class func readingListPanelSelectedIcon() -> UIImage { return UIImage(named: "panelIconReadingListSelected")! }
}