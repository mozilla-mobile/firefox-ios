/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import SnapKit

struct TabTrayControllerUX {
    static let CornerRadius = CGFloat(4.0)
    static let BackgroundColor = UIConstants.AppBackgroundColor
    static let CellBackgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1)
    static let TextBoxHeight = CGFloat(32.0)
    static let FaviconSize = CGFloat(18.0)
    static let Margin = CGFloat(15)
    static let ToolbarBarTintColor = UIConstants.AppBackgroundColor
    static let ToolbarButtonOffset = CGFloat(10.0)
    static let TabTitleTextColor = UIColor.blackColor()
    static let TabTitleTextFont = UIConstants.DefaultSmallFontBold
    static let CloseButtonSize = CGFloat(18.0)
    static let CloseButtonMargin = CGFloat(6.0)
    static let CloseButtonEdgeInset = CGFloat(10)

    static let NumberOfColumnsThin = 1
    static let NumberOfColumnsWide = 3
    static let CompactNumberOfColumnsThin = 2

    // Moved from UIConstants temporarily until animation code is merged
    static var StatusBarHeight: CGFloat {
        if UIScreen.mainScreen().traitCollection.verticalSizeClass == .Compact {
            return 0
        }
        return 20
    }
}

protocol TabCellDelegate: class {
    func tabCellDidClose(cell: TabCell)
}

// UIcollectionViewController doesn't let us specify a style for recycling views. We override the default style here.
class TabCell: UICollectionViewCell {
    let backgroundHolder: UIView
    let background: UIImageViewAligned
    let titleText: UILabel
    let title: UIVisualEffectView
    let innerStroke: InnerStrokedView
    let favicon: UIImageView
    let closeButton: UIButton
    var animator: SwipeAnimator!

    weak var delegate: TabCellDelegate?

    // Changes depending on whether we're full-screen or not.
    var margin = CGFloat(0)

    override init(frame: CGRect) {

        self.backgroundHolder = UIView()
        self.backgroundHolder.backgroundColor = UIColor.whiteColor()
        self.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        self.backgroundHolder.clipsToBounds = true
        self.backgroundHolder.backgroundColor = TabTrayControllerUX.CellBackgroundColor

        self.background = UIImageViewAligned()
        self.background.contentMode = UIViewContentMode.ScaleAspectFill
        self.background.clipsToBounds = true
        self.background.userInteractionEnabled = false
        self.background.alignLeft = true
        self.background.alignTop = true

        self.favicon = UIImageView()
        self.favicon.backgroundColor = UIColor.clearColor()
        self.favicon.layer.cornerRadius = 2.0
        self.favicon.layer.masksToBounds = true

        self.title = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        self.title.layer.shadowColor = UIColor.blackColor().CGColor
        self.title.layer.shadowOpacity = 0.2
        self.title.layer.shadowOffset = CGSize(width: 0, height: 0.5)
        self.title.layer.shadowRadius = 0

        self.titleText = UILabel()
        self.titleText.textColor = TabTrayControllerUX.TabTitleTextColor
        self.titleText.backgroundColor = UIColor.clearColor()
        self.titleText.textAlignment = NSTextAlignment.Left
        self.titleText.userInteractionEnabled = false
        self.titleText.numberOfLines = 1
        self.titleText.font = TabTrayControllerUX.TabTitleTextFont

        self.closeButton = UIButton()
        self.closeButton.setImage(UIImage(named: "stop"), forState: UIControlState.Normal)
        self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset)

        self.title.addSubview(self.closeButton)
        self.title.addSubview(self.titleText)
        self.title.addSubview(self.favicon)

        self.innerStroke = InnerStrokedView(frame: self.backgroundHolder.frame)
        self.innerStroke.layer.backgroundColor = UIColor.clearColor().CGColor

        super.init(frame: frame)

        self.opaque = true

        self.animator = SwipeAnimator(animatingView: self.backgroundHolder, container: self)
        self.closeButton.addTarget(self.animator, action: "SELcloseWithoutGesture", forControlEvents: UIControlEvents.TouchUpInside)

        contentView.addSubview(backgroundHolder)
        backgroundHolder.addSubview(self.background)
        backgroundHolder.addSubview(innerStroke)
        backgroundHolder.addSubview(self.title)

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: NSLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)"), target: self.animator, selector: "SELcloseWithoutGesture")
        ]
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let w = frame.width
        let h = frame.height
        backgroundHolder.frame = CGRect(x: margin,
            y: margin,
            width: w,
            height: h)
        background.frame = CGRect(origin: CGPointMake(0, 0), size: backgroundHolder.frame.size)

        title.frame = CGRect(x: 0,
            y: 0,
            width: backgroundHolder.frame.width,
            height: TabTrayControllerUX.TextBoxHeight)

        favicon.frame = CGRect(x: 6,
            y: (TabTrayControllerUX.TextBoxHeight - TabTrayControllerUX.FaviconSize)/2,
            width: TabTrayControllerUX.FaviconSize,
            height: TabTrayControllerUX.FaviconSize)

        let titleTextLeft = favicon.frame.origin.x + favicon.frame.width + 6
        titleText.frame = CGRect(x: titleTextLeft,
            y: 0,
            width: title.frame.width - titleTextLeft - margin  - TabTrayControllerUX.CloseButtonSize - TabTrayControllerUX.CloseButtonMargin * 2,
            height: title.frame.height)

        innerStroke.frame = background.frame

        closeButton.snp_makeConstraints { make in
            make.size.equalTo(title.snp_height)
            make.trailing.centerY.equalTo(title)
        }

        var top = (TabTrayControllerUX.TextBoxHeight - titleText.bounds.height) / 2.0
        titleText.frame.origin = CGPoint(x: titleText.frame.origin.x, y: max(0, top))
    }


    override func prepareForReuse() {
        // Reset any close animations.
        backgroundHolder.transform = CGAffineTransformIdentity
        backgroundHolder.alpha = 1
    }

    var tab: Browser? {
        didSet {
            titleText.text = tab?.title
            if let favIcon = tab?.displayFavicon {
                favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
            }
        }
    }

    override func accessibilityScroll(direction: UIAccessibilityScrollDirection) -> Bool {
        var right: Bool
        switch direction {
        case .Left:
            right = false
        case .Right:
            right = true
        default:
            return false
        }
        animator.close(right: right)
        return true
    }
}

class TabTrayController: UIViewController, UITabBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var tabManager: TabManager!
    private let CellIdentifier = "CellIdentifier"
    var collectionView: UICollectionView!
    var profile: Profile!
    var numberOfColumns: Int {
        let compactLayout = profile.prefs.boolForKey("CompactTabLayout") ?? true

        // iPhone 4-6+ portrait
        if traitCollection.horizontalSizeClass == .Compact && traitCollection.verticalSizeClass == .Regular {
            return compactLayout ? TabTrayControllerUX.CompactNumberOfColumnsThin : TabTrayControllerUX.NumberOfColumnsThin
        } else {
            return TabTrayControllerUX.NumberOfColumnsWide
        }
    }

    var navBar: UIView!
    var addTabButton: UIButton!
    var settingsButton: UIButton!
    var collectionViewTransitionSnapshot: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.accessibilityLabel = NSLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")
        tabManager.addDelegate(self)

        navBar = UIView()
        navBar.backgroundColor = TabTrayControllerUX.BackgroundColor

        let signInButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        signInButton.addTarget(self, action: "SELdidClickDone", forControlEvents: UIControlEvents.TouchUpInside)
        signInButton.setTitle(NSLocalizedString("Sign in", comment: "Button that leads to Sign in section of the Settings sheet."), forState: UIControlState.Normal)
        signInButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        // workaround for VoiceOver bug - if we create the button with UIButton.buttonWithType,
        // it gets initial frame with height 0 and accessibility somehow does not update the height
        // later and thus the button becomes completely unavailable to VoiceOver unless we
        // explicitly set the height to some (reasonable) non-zero value.
        // Also note that setting accessibilityFrame instead of frame has no effect.
        signInButton.frame.size.height = signInButton.intrinsicContentSize().height
        
        let navItem = UINavigationItem()
        navItem.titleView = signInButton
        signInButton.hidden = true //hiding sign in button until we decide on UX

        addTabButton = UIButton()
        addTabButton.setImage(UIImage(named: "add"), forState: .Normal)
        addTabButton.addTarget(self, action: "SELdidClickAddTab", forControlEvents: .TouchUpInside)
        addTabButton.accessibilityLabel = NSLocalizedString("Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")

        settingsButton = UIButton()
        settingsButton.setImage(UIImage(named: "settings"), forState: .Normal)
        settingsButton.addTarget(self, action: "SELdidClickSettingsItem", forControlEvents: .TouchUpInside)
        settingsButton.accessibilityLabel = NSLocalizedString("Settings", comment: "Accessibility label for the Settings button in the Tab Tray.")

        let flowLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(TabCell.self, forCellWithReuseIdentifier: CellIdentifier)

        collectionView.backgroundColor = TabTrayControllerUX.BackgroundColor

        view.addSubview(collectionView)
        view.addSubview(navBar)
        view.addSubview(addTabButton)
        view.addSubview(settingsButton)

        makeConstraints()
    }

    private func makeConstraints() {
        navBar.snp_makeConstraints { make in
            let topLayoutGuide = self.topLayoutGuide as! UIView
            make.top.equalTo(topLayoutGuide.snp_bottom)
            make.height.equalTo(UIConstants.ToolbarHeight)
            make.left.right.equalTo(self.view)
        }

        addTabButton.snp_makeConstraints { make in
            make.trailing.bottom.equalTo(self.navBar)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }

        settingsButton.snp_makeConstraints { make in
            make.leading.bottom.equalTo(self.navBar)
            make.size.equalTo(UIConstants.ToolbarHeight)
        }

        collectionView.snp_makeConstraints { make in
            make.top.equalTo(navBar.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }
    }

    func cellHeightForCurrentDevice() -> CGFloat {
        let compactLayout = profile.prefs.boolForKey("CompactTabLayout") ?? true
        let shortHeight = (compactLayout ? TabTrayControllerUX.TextBoxHeight * 6 : TabTrayControllerUX.TextBoxHeight * 5)

        if self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact {
            return shortHeight
        } else if self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact {
            return shortHeight
        } else {
            return TabTrayControllerUX.TextBoxHeight * 8
        }
    }

    func SELdidClickDone() {
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func SELdidClickSettingsItem() {
        let controller = SettingsNavigationController()
        controller.profile = profile
        controller.tabManager = tabManager
        controller.popoverDelegate = self
		controller.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        presentViewController(controller, animated: true, completion: nil)
    }

    func SELdidClickAddTab() {
        // We're only doing one update here, but using a batch update lets us delay selecting the tab
        // until after its insert animation finishes.
        self.collectionView.performBatchUpdates({ _ in
            let tab = self.tabManager.addTab()
            self.tabManager.selectTab(tab)
        }, completion: { finished in
            if finished {
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let tab = tabManager[indexPath.item]
        tabManager.selectTab(tab)
        self.navigationController?.popViewControllerAnimated(true)
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! TabCell
        cell.animator.delegate = self
        cell.delegate = self

        if let tab = tabManager[indexPath.item] {
            cell.titleText.text = tab.displayTitle
            if !tab.displayTitle.isEmpty {
                cell.accessibilityLabel = tab.displayTitle
            } else {
                cell.accessibilityLabel = AboutUtils.getAboutComponent(tab.url)
            }

            cell.isAccessibilityElement = true
            cell.accessibilityHint = NSLocalizedString("Swipe right or left with three fingers to close the tab.", comment: "Accessibility hint for tab tray's displayed tab.")

            if let favIcon = tab.displayFavicon {
                cell.favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
            } else {
                cell.favicon.image = UIImage(named: "defaultFavicon")
            }

            cell.background.image = tab.screenshot
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tabManager.count
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let cellWidth = (collectionView.bounds.width - TabTrayControllerUX.Margin * CGFloat(numberOfColumns + 1)) / CGFloat(numberOfColumns)
        return CGSizeMake(cellWidth, self.cellHeightForCurrentDevice())
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

extension TabTrayController: PresentingModalViewControllerDelegate {
    func dismissPresentedModalViewController(modalViewController: UIViewController, animated: Bool) {
        dismissViewControllerAnimated(animated, completion: { self.collectionView.reloadData() })
    }
}

extension TabTrayController: SwipeAnimatorDelegate {
    func swipeAnimator(animator: SwipeAnimator, viewDidExitContainerBounds: UIView) {
        let tabCell = animator.container as! TabCell
        if let indexPath = self.collectionView.indexPathForCell(tabCell) {
            if let tab = tabManager[indexPath.item] {
                tabManager.removeTab(tab)
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Closing tab", comment: ""))
            }
        }
    }
}

extension TabTrayController: TabManagerDelegate {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?) {
        // Our UI doesn't care about what's selected
    }

    func tabManager(tabManager: TabManager, didCreateTab tab: Browser, restoring: Bool) {
    }

    func tabManager(tabManager: TabManager, didAddTab tab: Browser, atIndex index: Int, restoring: Bool) {
        self.collectionView.performBatchUpdates({ _ in
            self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
        }, completion: { finished in
            if finished {
                tabManager.selectTab(tabManager[index])
                // don't pop the tab tray view controller if it is not in the foreground
                if self.presentedViewController == nil {
                    self.navigationController?.popViewControllerAnimated(true)
                }
            }
        })
    }

    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser, atIndex index: Int) {
        var newTab: Browser? = nil
        self.collectionView.performBatchUpdates({ _ in
            self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
        }, completion: { finished in
            if tabManager.count == 0 {
                newTab = tabManager.addTab()
            }
        })
    }

    func tabManagerDidAddTabs(tabManager: TabManager) {
    }

    func tabManagerDidRestoreTabs(tabManager: TabManager) {
    }
}

extension TabTrayController: TabCellDelegate {
    func tabCellDidClose(cell: TabCell) {
        let indexPath = collectionView.indexPathForCell(cell)!
        if let tab = tabManager[indexPath.item] {
            tabManager.removeTab(tab)
        }
    }
}

extension TabTrayController: UIScrollViewAccessibilityDelegate {
    func accessibilityScrollStatusForScrollView(scrollView: UIScrollView!) -> String! {
        var visibleCells = collectionView.visibleCells() as! [TabCell]
        var bounds = collectionView.bounds
        bounds = CGRectOffset(bounds, collectionView.contentInset.left, collectionView.contentInset.top)
        bounds.size.width -= collectionView.contentInset.left + collectionView.contentInset.right
        bounds.size.height -= collectionView.contentInset.top + collectionView.contentInset.bottom
        // visible cells do sometimes return also not visible cells when attempting to go past the last cell with VoiceOver right-flick gesture; so make sure we have only visible cells (yeah...)
        visibleCells = visibleCells.filter { !CGRectIsEmpty(CGRectIntersection($0.frame, bounds)) }

        var indexPaths = visibleCells.map { self.collectionView.indexPathForCell($0)! }
        indexPaths.sort { $0.section < $1.section || ($0.section == $1.section && $0.row < $1.row) }

        if indexPaths.count == 0 {
            return NSLocalizedString("No tabs", comment: "Message spoken by VoiceOver to indicate that there are no tabs in the Tabs Tray")
        }

        let firstTab = indexPaths.first!.row + 1
        let lastTab = indexPaths.last!.row + 1
        let tabCount = collectionView.numberOfItemsInSection(0)

        if (firstTab == lastTab) {
            let format = NSLocalizedString("Tab %@ of %@", comment: "Message spoken by VoiceOver saying the position of the single currently visible tab in Tabs Tray, along with the total number of tabs. E.g. \"Tab 2 of 5\" says that tab 2 is visible (and is the only visible tab), out of 5 tabs total.")
            return String(format: format, NSNumber(integer: firstTab), NSNumber(integer: tabCount))
        } else {
            let format = NSLocalizedString("Tabs %@ to %@ of %@", comment: "Message spoken by VoiceOver saying the range of tabs that are currently visible in Tabs Tray, along with the total number of tabs. E.g. \"Tabs 8 to 10 of 15\" says tabs 8, 9 and 10 are visible, out of 15 tabs total.")
            return String(format: format, NSNumber(integer: firstTab), NSNumber(integer: lastTab), NSNumber(integer: tabCount))
        }
    }
}

// A transparent view with a rectangular border with rounded corners, stroked
// with a semi-transparent white border.
class InnerStrokedView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawRect(rect: CGRect) {
        let strokeWidth = 1.0 as CGFloat
        let halfWidth = strokeWidth/2 as CGFloat

        let path = UIBezierPath(roundedRect: CGRect(x: halfWidth,
            y: halfWidth,
            width: rect.width - strokeWidth,
            height: rect.height - strokeWidth),
            cornerRadius: TabTrayControllerUX.CornerRadius)
        
        path.lineWidth = strokeWidth
        UIColor.whiteColor().colorWithAlphaComponent(0.2).setStroke()
        path.stroke()
    }
}
