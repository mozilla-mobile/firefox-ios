/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private struct TabTrayControllerUX {
    static let CornerRadius = CGFloat(4.0)
    static let BackgroundColor = UIColor(red: 0.21, green: 0.23, blue: 0.25, alpha: 1)
    static let CellBackgroundColor = UIColor(red:0.95, green:0.95, blue:0.95, alpha:1)
    static let TextBoxHeight = CGFloat(32.0)
    static let FaviconSize = CGFloat(18.0)
    static let CellHeight = TextBoxHeight * 5
    static let Margin = CGFloat(15)
    // This color has been manually adjusted to match background layer with iOS translucency effect.
    static let ToolbarBarTintColor = UIColor(red: 0.21, green: 0.23, blue: 0.25, alpha: 1)
    static let ToolbarButtonOffset = CGFloat(10.0)
    static let TabTitleTextColor = UIColor.blackColor()
    static let TabTitleTextFont = AppConstants.DefaultSmallFontBold
    static let CloseButtonSize = CGFloat(18.0)
    static let CloseButtonMargin = CGFloat(6.0)
    static let CloseButtonEdgeInset = CGFloat(3.0)
    static let NumberOfColumnsCompact = 1
    static let NumberOfColumnsRegular = 3
}

private protocol CustomCellDelegate: class {
    func customCellDidClose(cell: CustomCell)
}

// UIcollectionViewController doesn't let us specify a style for recycling views. We override the default style here.
private class CustomCell: UICollectionViewCell {
    let backgroundHolder: UIView
    let background: UIImageViewAligned
    let titleText: UILabel
    let title: UIVisualEffectView
    let innerStroke: InnerStrokedView
    let favicon: UIImageView
    let closeTab: UIButton
    var animator: SwipeAnimator!

    weak var delegate: CustomCellDelegate?

    // Changes depending on whether we're full-screen or not.
    var margin = CGFloat(0)

    override init(frame: CGRect) {
        self.backgroundHolder = UIView()
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

        self.closeTab = UIButton()
        self.closeTab.setImage(UIImage(named: "stop"), forState: UIControlState.Normal)
        self.closeTab.imageEdgeInsets = UIEdgeInsetsMake(TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset, TabTrayControllerUX.CloseButtonEdgeInset)

        self.title.addSubview(self.closeTab)
        self.title.addSubview(self.titleText)
        self.title.addSubview(self.favicon)

        self.innerStroke = InnerStrokedView(frame: self.backgroundHolder.frame)
        self.innerStroke.layer.backgroundColor = UIColor.clearColor().CGColor

        super.init(frame: frame)

        self.animator = SwipeAnimator(animatingView: self.backgroundHolder,
            containerView: self, ux: SwipeAnimatorUX())

        backgroundHolder.addSubview(self.background)
        addSubview(backgroundHolder)
        backgroundHolder.addSubview(innerStroke)
        backgroundHolder.addSubview(self.title)

        self.titleText.addObserver(self, forKeyPath: "contentSize", options: .New, context: nil)
        setupFrames()

        self.animator.originalCenter = CGPoint(x: self.frame.width / 2, y: self.frame.height / 2)

        self.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: NSLocalizedString("Close", comment: "Accessibility label for action denoting closing a tab in tab list (tray)"), target: self.animator, selector: "SELcloseWithoutGesture")
        ]
    }

    func setupFrames() {
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

        closeTab.frame = CGRect(x: backgroundHolder.frame.width - TabTrayControllerUX.CloseButtonSize - TabTrayControllerUX.CloseButtonMargin,
            y: (TabTrayControllerUX.TextBoxHeight - TabTrayControllerUX.CloseButtonSize) / 2,
            width: TabTrayControllerUX.CloseButtonSize,
            height: TabTrayControllerUX.CloseButtonSize)

        verticalCenter(titleText)

    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.titleText.removeObserver(self, forKeyPath: "contentSize")
    }

    private override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        let tv = object as! UILabel
        verticalCenter(tv)
    }

    private func verticalCenter(text: UILabel) {
        var top = (TabTrayControllerUX.TextBoxHeight - text.bounds.height) / 2.0
        top = top < 0.0 ? 0.0 : top
        text.frame.origin = CGPoint(x: text.frame.origin.x, y: top)
    }

    func showFullscreen(container: UIView, table: UICollectionView, shouldOffset: Bool) {
        var offset: CGFloat = shouldOffset ? 2 : 1

        frame = CGRect(x: 0,
                        y: container.frame.origin.y + AppConstants.ToolbarHeight + AppConstants.StatusBarHeight,
                        width: container.frame.width,
                        height: container.frame.height - (AppConstants.ToolbarHeight * offset + AppConstants.StatusBarHeight))

        container.insertSubview(self, atIndex: container.subviews.count)
        setupFrames()

    }

    func showAt(index: Int, container: UIView, table: UICollectionView) {
        let scrollOffset = table.contentOffset.y + table.contentInset.top
        if table.numberOfItemsInSection(0) > 0 {
            if let attr = table.collectionViewLayout.layoutAttributesForItemAtIndexPath(NSIndexPath(forItem: index, inSection: 0)) {
                frame = CGRectOffset(attr.frame, -container.frame.origin.x, -container.frame.origin.y + AppConstants.ToolbarHeight + AppConstants.StatusBarHeight - scrollOffset)
            }
        } else {
            // TODO: fix this so the frame is where the first item *would* be
            frame = CGRect(x: 0,
                        y: TabTrayControllerUX.Margin + AppConstants.ToolbarHeight + AppConstants.StatusBarHeight,
                        width: container.frame.width,
                        height: TabTrayControllerUX.CellHeight)
        }

        container.insertSubview(self, atIndex: container.subviews.count)
        setupFrames()
    }

    var tab: Browser? {
        didSet {
            titleText.text = tab?.title
            if let favIcon = tab?.displayFavicon {
                favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
            }
        }
    }

    @objc func SELdidPressClose() {
        delegate?.customCellDidClose(self)
    }
}

private struct SwipeAnimatorUX {
    let totalRotationInDegrees = 10.0
    let deleteThreshold = CGFloat(140)
    let totalScale = CGFloat(0.9)
    let totalAlpha = CGFloat(0.7)
    let minExitVelocity = CGFloat(800.0)
    let recenterAnimationDuration = NSTimeInterval(0.15)
}

private protocol SwipeAnimatorDelegate: class {
    func swipeAnimator(animator: SwipeAnimator, viewDidExitContainerBounds: UIView)
}

private class SwipeAnimator: NSObject {
    let animatingView: UIView
    let ux: SwipeAnimatorUX

    var originalCenter: CGPoint!
    var startLocation: CGPoint!

    weak var container: UIView!
    weak var delegate: SwipeAnimatorDelegate!

    init(animatingView view: UIView, containerView: UIView, ux swipeUX: SwipeAnimatorUX) {
        animatingView = view
        container = containerView
        ux = swipeUX

        super.init()

        let panGesture = UIPanGestureRecognizer(target: self, action: Selector("SELdidPan:"))
        container.addGestureRecognizer(panGesture)
        panGesture.delegate = self
    }

    @objc func SELdidPan(recognizer: UIPanGestureRecognizer!) {
        switch (recognizer.state) {
        case .Began:
            self.startLocation = self.animatingView.center;

        case .Changed:
            let translation = recognizer.translationInView(self.container)
            let newLocation =
            CGPoint(x: self.startLocation.x + translation.x, y: self.animatingView.center.y)
            self.animatingView.center = newLocation

            // Calculate values to determine the amount we need to scale/rotate with
            let distanceFromCenter = abs(self.originalCenter.x - self.animatingView.center.x)
            let halfWidth = self.container.frame.size.width / 2
            let totalRotationInRadians = CGFloat(self.ux.totalRotationInDegrees / 180.0 * M_PI)

            // Determine rotation / scaling amounts by the distance to the edge
            var rotation = (distanceFromCenter / halfWidth) * totalRotationInRadians
            rotation *= self.originalCenter.x - self.animatingView.center.x > 0 ? -1 : 1
            var scale = 1 - (distanceFromCenter / halfWidth) * (1 - self.ux.totalScale)
            let alpha = 1 - (distanceFromCenter / halfWidth) * (1 - self.ux.totalAlpha)

            let rotationTransform = CGAffineTransformMakeRotation(rotation)
            let scaleTransform = CGAffineTransformMakeScale(scale, scale)
            let combinedTransform = CGAffineTransformConcat(rotationTransform, scaleTransform)

            self.animatingView.transform = combinedTransform
            self.animatingView.alpha = alpha

        case .Cancelled:
            self.animatingView.center = self.startLocation
            self.animatingView.transform = CGAffineTransformIdentity
            self.animatingView.alpha = 1

        case .Ended:
            // Bounce back if the velocity is too low or if we have not reached the treshold yet

            let velocity = recognizer.velocityInView(self.container)
            let actualVelocity = max(abs(velocity.x), self.ux.minExitVelocity)

            if (actualVelocity < self.ux.minExitVelocity || abs(self.animatingView.center.x - self.originalCenter.x) < self.ux.deleteThreshold) {
                UIView.animateWithDuration(self.ux.recenterAnimationDuration, animations: {
                    self.animatingView.transform = CGAffineTransformIdentity
                    self.animatingView.center = self.startLocation
                    self.animatingView.alpha = 1
                })
                return
            }

            // Otherwise we are good and we can get rid of the view
            close(velocity: velocity, actualVelocity: actualVelocity)

        default:
            break
        }
    }

    func close(#velocity: CGPoint, actualVelocity: CGFloat) {
        // Calculate the edge to calculate distance from
        let edgeX = velocity.x > 0 ? CGRectGetMaxX(self.container.frame) : CGRectGetMinX(self.container.frame)
        var distance = (self.animatingView.center.x / 2) + abs(self.animatingView.center.x - edgeX)

        // Determine which way we need to travel
        distance *= velocity.x > 0 ? 1 : -1

        let timeStep = NSTimeInterval(abs(distance) / actualVelocity)
        UIView.animateWithDuration(timeStep, animations: {
            let animatedPosition
            = CGPoint(x: self.animatingView.center.x + distance, y: self.animatingView.center.y)
            self.animatingView.center = animatedPosition
        }, completion: { finished in
            if finished {
                self.animatingView.hidden = true
                self.delegate?.swipeAnimator(self, viewDidExitContainerBounds: self.animatingView)
            }
        })
    }

    @objc func SELcloseWithoutGesture() -> Bool {
        close(velocity: CGPointMake(-self.ux.minExitVelocity, 0), actualVelocity: self.ux.minExitVelocity)
        return true
    }
}

extension SwipeAnimator: UIGestureRecognizerDelegate {
    @objc private func gestureRecognizerShouldBegin(recognizer: UIGestureRecognizer) -> Bool {
        let cellView = recognizer.view as UIView!
        let panGesture = recognizer as! UIPanGestureRecognizer
        let translation = panGesture.translationInView(cellView.superview!)
        return fabs(translation.x) > fabs(translation.y)
    }
}

class TabTrayController: UIViewController, UITabBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    var tabManager: TabManager!
    private let CellIdentifier = "CellIdentifier"
    var collectionView: UICollectionView!
    var profile: Profile!
    var numberOfColumns: Int!

    var navBar: UINavigationBar!
    var addTabButton: UIButton!
    var settingsButton: UIButton!

    override func viewDidLoad() {
        view.accessibilityLabel = NSLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")
        tabManager.addDelegate(self)

        navBar = UINavigationBar()

        navBar.barTintColor = TabTrayControllerUX.ToolbarBarTintColor
        navBar.tintColor = UIColor.whiteColor()
        navBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]
        navBar.translucent = false // the translucency was causing some bad color pop during the transition
        
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

        navBar.addSubview(addTabButton)
        navBar.addSubview(settingsButton)

        numberOfColumns = numberOfColumnsForCurrentSize()
        let flowLayout = UICollectionViewFlowLayout()
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(CustomCell.self, forCellWithReuseIdentifier: CellIdentifier)
        collectionView.contentInset = UIEdgeInsets(top: AppConstants.StatusBarHeight + AppConstants.ToolbarHeight, left: 0, bottom: 0, right: 0)

        collectionView.backgroundColor = TabTrayControllerUX.BackgroundColor

        view.addSubview(collectionView)
        view.addSubview(navBar)

        navBar.snp_makeConstraints { make in
            make.top.equalTo(self.view)
            make.height.equalTo(AppConstants.StatusBarHeight + AppConstants.ToolbarHeight)
            make.left.right.equalTo(self.view)
        }

        addTabButton.snp_makeConstraints { make in
            make.trailing.bottom.equalTo(self.navBar)
            make.size.equalTo(AppConstants.ToolbarHeight)
        }

        settingsButton.snp_makeConstraints { make in
            make.leading.bottom.equalTo(self.navBar)
            make.size.equalTo(AppConstants.ToolbarHeight)
        }

        collectionView.snp_makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.bottom.equalTo(self.view)
        }
    }

    private func numberOfColumnsForCurrentSize() -> Int {
        if self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClass.Compact {
            return TabTrayControllerUX.NumberOfColumnsRegular
        } else if self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Compact {
            return TabTrayControllerUX.NumberOfColumnsCompact
        } else {
            return TabTrayControllerUX.NumberOfColumnsRegular
        }
    }

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
        tabManager?.addTab()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let tab = tabManager[indexPath.item]
        tabManager.selectTab(tab)

        dispatch_async(dispatch_get_main_queue()) { _ in
            self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! CustomCell
        cell.animator.delegate = self
        cell.delegate = self

        if let tab = tabManager[indexPath.item] {
            cell.titleText.text = tab.displayTitle
            cell.accessibilityLabel = tab.displayTitle
            cell.isAccessibilityElement = true
            if let favIcon = tab.displayFavicon {
                cell.favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
            } else {
                cell.favicon.image = UIImage(named: "defaultFavicon")
            }
            cell.background.image = tab.screenshot
        }

        let screenshotAspectRatio = cell.frame.width / TabTrayControllerUX.CellHeight
        cell.closeTab.addTarget(cell, action: "SELdidPressClose", forControlEvents: UIControlEvents.TouchUpInside)

        // calling setupFrames here fixes reused cells which don't get resized on rotation
        // TODO: is there a better way?
        cell.setupFrames()

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
        return CGSizeMake(cellWidth, TabTrayControllerUX.CellHeight)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin, TabTrayControllerUX.Margin)
    }

    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return TabTrayControllerUX.Margin
    }

    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        collectionView.collectionViewLayout.invalidateLayout()
    }

    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        collectionView.layoutSubviews()
        for cell in collectionView.visibleCells() {
            if let tab = cell as? CustomCell {
                tab.setupFrames()
            }
        }
    }

    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        numberOfColumns = numberOfColumnsForCurrentSize()
        collectionView.layoutIfNeeded()
        for cell in collectionView.visibleCells() {
            if let tab = cell as? CustomCell {
                tab.setupFrames()
            }
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}

extension TabTrayController: Transitionable {
    private func getTransitionCell(options: TransitionOptions, browser: Browser?) -> CustomCell {
        var transitionCell: CustomCell
        if let cell = options.moving as? CustomCell {
            transitionCell = cell
        } else {
            transitionCell = CustomCell(frame: options.container!.frame)
            options.moving = transitionCell
        }

        transitionCell.background.image = browser?.screenshot
        transitionCell.titleText.text = browser?.displayTitle
        if let favIcon = browser?.displayFavicon {
            transitionCell.favicon.sd_setImageWithURL(NSURL(string: favIcon.url)!)
        }
        return transitionCell
    }

    func transitionablePreShow(transitionable: Transitionable, options: TransitionOptions) {
        self.collectionView.layoutSubviews()
        self.collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: tabManager.selectedIndex, inSection: 0), atScrollPosition: .CenteredVertically, animated: false)
    }

    func transitionablePreHide(transitionable: Transitionable, options: TransitionOptions) {

    }

    func transitionableWillHide(transitionable: Transitionable, options: TransitionOptions) {
        // Create a fake cell that is shown fullscreen
        if let container = options.container {
            let cell = getTransitionCell(options, browser: tabManager.selectedTab)
            // TODO: Smoothly animate the corner radius to 0.
            // cell.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
            var hasToolbar = false
            if let fromView = options.fromView as? BrowserViewController {
                hasToolbar = fromView.shouldShowToolbar()
            } else if let toView = options.toView as? BrowserViewController {
                hasToolbar = toView.shouldShowToolbar()
            }

            cell.showFullscreen(container, table: collectionView, shouldOffset: hasToolbar)
            cell.layoutIfNeeded()
            cell.title.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, -cell.title.frame.height)

            let corners = CABasicAnimation(keyPath: "cornerRadius")
            corners.toValue = 0
            corners.fromValue = TabTrayControllerUX.CornerRadius
            corners.duration = options.duration!
            corners.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            
            cell.backgroundHolder.layer.addAnimation(corners, forKey: "cornerRadius")
            cell.innerStroke.layer.addAnimation(corners, forKey: "cornerRadius")

            cell.innerStroke.alpha = 0
        }

        let buttonOffset = addTabButton.frame.width + TabTrayControllerUX.ToolbarButtonOffset
        addTabButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, buttonOffset , 0)
        settingsButton.transform = CGAffineTransformTranslate(CGAffineTransformIdentity, -buttonOffset , 0)
        navBar.alpha = 0
        collectionView.alpha = 0

    }

    func transitionableWillShow(transitionable: Transitionable, options: TransitionOptions) {
        if let container = options.container {
            // Create a fake cell that is at the selected index
            let cell = getTransitionCell(options, browser: tabManager.selectedTab)
            cell.showAt(tabManager.selectedIndex, container: container, table: collectionView)
            cell.layoutIfNeeded()

            let corners = CABasicAnimation(keyPath: "cornerRadius")
            corners.toValue = TabTrayControllerUX.CornerRadius
            corners.fromValue = 0
            corners.duration = options.duration!
            corners.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)

            cell.backgroundHolder.layer.addAnimation(corners, forKey: "cornerRadius")
            cell.innerStroke.layer.addAnimation(corners, forKey: "cornerRadius")

            cell.innerStroke.alpha = 1
        }

        addTabButton.transform = CGAffineTransformIdentity
        settingsButton.transform = CGAffineTransformIdentity
        navBar.alpha = 1
        collectionView.alpha = 1
    }

    func transitionableWillComplete(transitionable: Transitionable, options: TransitionOptions) {
        if let cell = options.moving {
          cell.removeFromSuperview()
        }
    }

}

extension TabTrayController: SwipeAnimatorDelegate {
    private func swipeAnimator(animator: SwipeAnimator, viewDidExitContainerBounds: UIView) {
        let tabCell = animator.container as! CustomCell
        if let indexPath = self.collectionView.indexPathForCell(tabCell) {
            if let tab = tabManager[indexPath.item] {
                tabManager.removeTab(tab)
            }
        }
    }
}

extension TabTrayController: TabManagerDelegate {
    func tabManager(tabManager: TabManager, didSelectedTabChange selected: Browser?, previous: Browser?) {
        // Our UI doesn't care about what's selected
    }

    func tabManager(tabManager: TabManager, didCreateTab tab: Browser) {
    }

    func tabManager(tabManager: TabManager, didAddTab tab: Browser, atIndex index: Int) {
        self.collectionView.insertItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
    }

    func tabManager(tabManager: TabManager, didRemoveTab tab: Browser, atIndex index: Int) {
        self.collectionView.deleteItemsAtIndexPaths([NSIndexPath(forItem: index, inSection: 0)])
    }
}

extension TabTrayController: CustomCellDelegate {
    private func customCellDidClose(cell: CustomCell) {
        let indexPath = collectionView.indexPathForCell(cell)!
        if let tab = tabManager[indexPath.item] {
            tabManager.removeTab(tab)
        }
    }
}

// A transparent view with a rectangular border with rounded corners, stroked
// with a semi-transparent white border.
private class InnerStrokedView: UIView {
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
