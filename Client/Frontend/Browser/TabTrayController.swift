/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit

public struct TabTrayControllerUX {
    static let CornerRadius = CGFloat(4.0)
    static let CellBackgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1)
    static let BackgroundColor = AppConstants.BackgroundColor
    static let TextBoxHeight = CGFloat(32.0)
    static let FaviconSize = CGFloat(18.0)
    static let Margin = CGFloat(15)
    static let ToolbarBarTintColor = AppConstants.BackgroundColor
    static let ToolbarButtonOffset = CGFloat(10.0)
    static let TabTitleTextColor = UIColor.blackColor()
    static let TabTitleTextFont = AppConstants.DefaultSmallFontBold
    static let CloseButtonSize = CGFloat(18.0)
    static let NavButtonMargin = CGFloat(6.0)
    static let CloseButtonEdgeInset = CGFloat(10)
    static let NumberOfColumnsCompact = 1
    static let NumberOfColumnsRegular = 3

    // Moved from AppConstants temporarily until animation code is merged
    static var StatusBarHeight: CGFloat {
        if UIScreen.mainScreen().traitCollection.verticalSizeClass == .Compact {
            return 0
        }
        return 20
    }
}

class TabTrayController: UIViewController, UITabBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var browserViewController: BrowserViewController?

    var tabManager: TabManager!
    var profile: Profile!

    lazy var numberOfColumns: Int = {
        return self.numberOfColumnsForTraitCollection(self.traitCollection)
    }()

    var cellHeight: CGFloat {
        if self.traitCollection.verticalSizeClass == .Compact {
            return TabTrayControllerUX.TextBoxHeight * 5
        } else if self.traitCollection.horizontalSizeClass == .Compact {
            return TabTrayControllerUX.TextBoxHeight * 5
        } else {
            return TabTrayControllerUX.TextBoxHeight * 8
        }
    }

    lazy var navBar: UIView = {
        let bar = UIView()
        bar.backgroundColor = AppConstants.BackgroundColor
        return bar
    }()

    lazy var addTabButton: UIButton = {
        let addTabButton = UIButton()
        addTabButton.setImage(UIImage(named: "add"), forState: .Normal)
        addTabButton.addTarget(self, action: "SELdidClickAddTab", forControlEvents: .TouchUpInside)
        addTabButton.accessibilityLabel = NSLocalizedString("Add Tab", comment: "Accessibility label for the Add Tab button in the Tab Tray.")
        return addTabButton
    }()

    lazy var settingsButton: UIButton = {
        let settingsButton = UIButton()
        settingsButton.setImage(UIImage(named: "settings"), forState: .Normal)
        settingsButton.addTarget(self, action: "SELdidClickSettingsItem", forControlEvents: .TouchUpInside)
        settingsButton.accessibilityLabel = NSLocalizedString("Settings", comment: "Accessibility label for the Settings button in the Tab Tray.")
        return settingsButton
    }()

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(TabCell.self, forCellWithReuseIdentifier: TabCell.Identifier)
        collectionView.backgroundColor = UIColor.clearColor()
        return collectionView
    }()

    var settingsLeft: Constraint?
    var addTabRight: Constraint?

    // MARK: View Controller Overrides and Callbacks
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppConstants.BackgroundColor
        tabManager.addDelegate(self)

        view.accessibilityLabel = NSLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")

        navBar.addSubview(addTabButton)
        navBar.addSubview(settingsButton)

        view.addSubview(collectionView)
        view.addSubview(navBar)

        setupConstraints()
    }

    private func setupConstraints() {
        let castedTopGuide = topLayoutGuide as! UIView

        navBar.snp_makeConstraints { make in
            make.top.equalTo(castedTopGuide.snp_bottom)
            make.left.right.equalTo(view)
            make.height.equalTo(AppConstants.ToolbarHeight)
        }

        addTabButton.snp_makeConstraints { make in
            make.centerY.equalTo(navBar)
            make.size.equalTo(navBar.snp_height)
            addTabRight = make.right.equalTo(navBar).offset(-TabTrayControllerUX.NavButtonMargin).constraint
        }

        settingsButton.snp_makeConstraints { make in
            make.centerY.equalTo(navBar)
            make.size.equalTo(navBar.snp_height)
            settingsLeft = make.left.equalTo(navBar).offset(TabTrayControllerUX.NavButtonMargin).constraint
        }

        collectionView.snp_remakeConstraints { make in
            make.top.equalTo(navBar.snp_top)
            make.left.right.bottom.equalTo(self.view)
        }
    }

    private func numberOfColumnsForTraitCollection(traitCollection: UITraitCollection) -> Int {
        if traitCollection.verticalSizeClass == .Compact {
            return TabTrayControllerUX.NumberOfColumnsRegular
        } else if traitCollection.horizontalSizeClass == .Compact {
            return TabTrayControllerUX.NumberOfColumnsCompact
        } else {
            return TabTrayControllerUX.NumberOfColumnsRegular
        }
    }

    override func willTransitionToTraitCollection(newCollection: UITraitCollection, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransitionToTraitCollection(newCollection, withTransitionCoordinator: coordinator)
        numberOfColumns = numberOfColumnsForTraitCollection(newCollection)
    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    // MARK: Selectors
    func SELdidClickDone() {
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func SELdidClickSettingsItem() {
        let controller = SettingsNavigationController()
        controller.profile = profile
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
    }

    func SELdidClickAddTab() {
        // We're only doing one update here, but using a batch update lets us delay selecting the tab
        // until after its insert animation finishes.
        collectionView.performBatchUpdates({ _ in
            tabManager.addTab()
        }, completion: { finished in
            if finished {
                self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
            }
        })
    }

    func SELdidPressClose(sender: AnyObject) {
        let index = (sender as! UIButton).tag
        if let tab = tabManager[index] {
            tabManager.removeTab(tab)
        }
    }

    // MARK: Collection View Delegate/Data Source
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let tab = tabManager[indexPath.item]
        tabManager.selectTab(tab)
        self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(TabCell.Identifier, forIndexPath: indexPath) as! TabCell
        cell.animator.delegate = self
        cell.configureCellWithTab(tabManager[indexPath.row])
        cell.closeButton.tag = indexPath.row
        cell.closeButton.addTarget(self, action: "SELdidPressClose:", forControlEvents: .TouchUpInside)
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
        return CGSizeMake(cellWidth, self.cellHeight)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(TabTrayControllerUX.Margin + AppConstants.ToolbarHeight, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }
}

extension TabTrayController: Transitionable {

    private func frameFittingBelowNavBar() -> CGRect {
        let yOffset = self.topLayoutGuide.length
        var belowNavFrame = CGRect()
        belowNavFrame.origin = CGPoint(x: 0, y: yOffset)
        belowNavFrame.size = CGSize(width: self.view.bounds.width, height: self.view.bounds.height - yOffset)
        return belowNavFrame
    }

    private func tabCellFromBrowser(browser: Browser?, frame: CGRect) -> TabCell {
        let tabCell = TabCell()
        tabCell.configureCellWithTab(browser)
        tabCell.storeSnapshotForHeader(browserViewController?.header)
        tabCell.storeSnapshotForFooter(browserViewController?.footer)
        tabCell.frame = frame
        tabCell.setNeedsLayout()
        return tabCell
    }

    func transitionablePreShow(transitionable: Transitionable, options: TransitionOptions) {
        if let browserViewController = options.fromView as? BrowserViewController,
           let tabController = options.toView as? TabTrayController,
           let container = options.container,
           let browser = tabManager.selectedTab {

            // Scroll to where we need to be in the collection view and take a snapshto if it to show for the
            // alpha + scale animation
            collectionView.frame = frameFittingBelowNavBar()
            collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: tabManager.selectedIndex, inSection: 0), atScrollPosition: .None, animated: false)

            let attributes = collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: self.tabManager.selectedIndex, inSection: 0))
            options.cellFrame = collectionView.convertRect(attributes.frame, toView: self.view)
            collectionView.transform = CGAffineTransformMakeScale(0.9, 0.9)
            collectionView.alpha = 0

            // Add tab to view hierarchy for animation
            let tabCell = self.tabCellFromBrowser(browser, frame: frameFittingBelowNavBar())
            tabCell.expanded = true

            container.addSubview(tabCell)
            options.moving = tabCell

            // Hide and move the nav buttons offset screen
            addTabRight?.updateOffset(addTabButton.frame.size.width + TabTrayControllerUX.NavButtonMargin)
            addTabButton.alpha = 0
            settingsLeft?.updateOffset(-(settingsButton.frame.size.width + TabTrayControllerUX.NavButtonMargin))
            settingsButton.alpha = 0
        }
    }

    func transitionablePreHide(transitionable: Transitionable, options: TransitionOptions) {
        if let container = options.container, let browser = tabManager.selectedTab {

            // Add tab view to container for animation
            let attributes = self.collectionView.collectionViewLayout.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: tabManager.selectedIndex, inSection: 0))
            let tabFrame = self.collectionView.convertRect(attributes.frame, toView: self.view)
            let tabCell = self.tabCellFromBrowser(browser, frame: tabFrame)
            container.addSubview(tabCell)
            options.moving = tabCell
        }
    }

    func transitionableWillHide(transitionable: Transitionable, options: TransitionOptions) {
        if let tabCell = options.moving as? TabCell, let container = options.container, let bvc = browserViewController {

            // Animate nav buttons
            addTabRight?.updateOffset(addTabButton.frame.size.width + TabTrayControllerUX.NavButtonMargin)
            addTabButton.alpha = 0
            settingsLeft?.updateOffset(-(settingsButton.frame.size.width + TabTrayControllerUX.NavButtonMargin))
            settingsButton.alpha = 0

            // Animate tab view to fill the screen
            var endFrame = CGRect()
            let topLayoutLength = bvc.topLayoutGuide.length
            endFrame.origin = CGPoint(x: bvc.view.bounds.origin.x, y: bvc.view.bounds.origin.y + topLayoutLength)
            endFrame.size = CGSize(width: bvc.view.bounds.size.width, height: bvc.view.bounds.size.height - topLayoutLength)

            tabCell.frame = endFrame
            tabCell.layer.cornerRadius = 0
            tabCell.expanded = true

            collectionView.transform = CGAffineTransformMakeScale(0.9, 0.9)
            collectionView.alpha = 0
        }
    }

    func transitionableWillShow(transitionable: Transitionable, options: TransitionOptions) {
        if let tabCell = options.moving as? TabCell, let cellFrame = options.cellFrame {

            // Animate nav buttons
            addTabRight?.updateOffset(-TabTrayControllerUX.NavButtonMargin)
            addTabButton.alpha = 1
            settingsLeft?.updateOffset(TabTrayControllerUX.NavButtonMargin)
            settingsButton.alpha = 1

            // Animate the tab view to shrink to it's cell position
            tabCell.frame = cellFrame
            tabCell.layer.cornerRadius = TabTrayControllerUX.CornerRadius
            tabCell.expanded = false
            collectionView.transform = CGAffineTransformIdentity
            collectionView.alpha = 1
        }
    }

    func transitionableWillComplete(transitionable: Transitionable, options: TransitionOptions) {
        if let tabCell = options.moving as? TabCell {
            tabCell.removeFromSuperview()
            collectionView.alpha = 1
        }
    }
}

extension TabTrayController: SwipeAnimatorDelegate {
    func swipeAnimator(animator: SwipeAnimator, viewDidExitContainerBounds: UIView) {
        let tabCell = animator.container as! TabCell
        if let indexPath = self.collectionView.indexPathForCell(tabCell) {
            if let tab = tabManager[indexPath.item] {
                tabManager.removeTab(tab)
            }
        }
    }
}

extension TabTrayController: TabManagerDelegate {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?) {
    }

    func tabManager(tabManager: TabManager, didCreateTab tab: Browser) {
    }

    func tabManager(tabManager: TabManager, didAddTab tab: Browser, atIndex index: Int) {
        self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
    }

    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser, atIndex index: Int) {
        var newTab: Browser? = nil
        self.collectionView.performBatchUpdates({ _ in
            self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
            if tabManager.count == 0 {
                newTab = tabManager.addTab()
            }
        }, completion: { finished in
            if finished {
                if let newTab = newTab {
                    self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
                }
            }
        })
    }
}
