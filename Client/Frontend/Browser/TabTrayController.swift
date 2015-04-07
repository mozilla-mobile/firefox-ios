/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private struct TabTrayControllerUX {
    static let CornerRadius = CGFloat(4.0)
    static let BackgroundColor = UIColor(red: 0.21, green: 0.23, blue: 0.25, alpha: 1)
    static let TextBoxHeight = CGFloat(32.0)
    static let CellHeight = TextBoxHeight * 5
    static let Margin = CGFloat(15)
    // This color has been manually adjusted to match background layer with iOS translucency effect.
    static let ToolbarBarTintColor = UIColor(red: 0.35, green: 0.37, blue: 0.39, alpha: 0)
    static let TabTitleTextColor = UIColor.blackColor()
    static let TabTitleTextFont = AppConstants.DefaultSmallFont
}


// UITableViewController doesn't let us specify a style for recycling views. We override the default style here.
private class TabCell: UITableViewCell {
    let backgroundHolder: UIView
    let background: UIImageViewAligned
    let titleText: UILabel
    let title: UIView
    let innerStroke: InnerStrokedView
    let favicon: UIImageView

    // Changes depending on whether we're full-screen or not.
    var margin = TabTrayControllerUX.Margin
    var animator: SwipeAnimator!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {

        self.backgroundHolder = UIView()
        self.backgroundHolder.layer.shadowColor = UIColor.blackColor().CGColor
        self.backgroundHolder.layer.shadowOffset = CGSizeMake(0, 2.0)
        self.backgroundHolder.layer.shadowOpacity = 0.95
        self.backgroundHolder.layer.shadowRadius = 1.0
        self.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        self.backgroundHolder.clipsToBounds = true

        self.background = UIImageViewAligned()
        self.background.contentMode = UIViewContentMode.ScaleAspectFill
        self.background.clipsToBounds = true
        self.background.userInteractionEnabled = false
        self.background.alignLeft = true
        self.background.alignTop = true

        self.favicon = UIImageView(image: UIImage(named: "defaultFavicon")!)
        self.favicon.backgroundColor = UIColor.clearColor()

        self.title = UIView()
        self.title.backgroundColor = UIColor.whiteColor()

        self.titleText = UILabel()
        self.titleText.textColor = TabTrayControllerUX.TabTitleTextColor
        self.titleText.backgroundColor = UIColor.clearColor()
        self.titleText.textAlignment = NSTextAlignment.Left
        self.titleText.userInteractionEnabled = false
        self.titleText.numberOfLines = 1
        self.titleText.font = TabTrayControllerUX.TabTitleTextFont

        self.title.addSubview(self.titleText)
        self.title.addSubview(self.favicon)

        self.innerStroke = InnerStrokedView(frame: self.backgroundHolder.frame)
        self.innerStroke.layer.backgroundColor = UIColor.clearColor().CGColor

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.animator = SwipeAnimator(animatingView: self.backgroundHolder,
            containerView: self, ux: SwipeAnimatorUX())

        backgroundHolder.addSubview(self.background)
        addSubview(backgroundHolder)
        backgroundHolder.addSubview(self.title)
        backgroundHolder.addSubview(innerStroke)

        backgroundColor = UIColor.clearColor()

        selectionStyle = .None
        self.titleText.addObserver(self, forKeyPath: "contentSize", options: .New, context: nil)
        setupFrames()

        self.animator.originalCenter = CGPoint(x: UIScreen.mainScreen().bounds.width / 2, y: TabTrayControllerUX.CellHeight / 2)
    }

    func setupFrames() {
        // Will need to be updated when moving to collection view using collection view's sizeForItem
        let w = UIScreen.mainScreen().bounds.width - (2 * margin)
        let h = TabTrayControllerUX.CellHeight - margin

        backgroundHolder.frame = CGRect(x: margin,
            y: margin,
            width: w,
            height: h)
        background.frame = CGRect(origin: CGPointMake(0, 0), size: backgroundHolder.frame.size)

        title.frame = CGRect(x: 0,
            y: 0,
            width: backgroundHolder.frame.width,
            height: TabTrayControllerUX.TextBoxHeight)

        favicon.frame = CGRect(x: 6, y: (TabTrayControllerUX.TextBoxHeight - 16)/2, width: 16, height: 16)

        let titleTextLeft = favicon.frame.origin.x + favicon.frame.width + 6
        titleText.frame = CGRect(x: titleTextLeft,
            y: 0,
            width: title.frame.width - titleTextLeft - margin,
            height: title.frame.height)

        innerStroke.frame = background.frame

        verticalCenter(titleText)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.titleText.removeObserver(self, forKeyPath: "contentSize")
    }

    private override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        let tv = object as UILabel
        verticalCenter(tv)
    }

    private func verticalCenter(text: UILabel) {
        var top = (TabTrayControllerUX.TextBoxHeight - text.bounds.height) / 2.0
        top = top < 0.0 ? 0.0 : top
        text.frame.origin = CGPoint(x: text.frame.origin.x, y: top)
    }

    func showFullscreen(container: UIView, table: UITableView) {
        margin = 0
        container.insertSubview(self, atIndex: container.subviews.count)
        frame = CGRect(x: container.frame.origin.x,
            y: container.frame.origin.y + AppConstants.ToolbarHeight + AppConstants.StatusBarHeight,
            width: container.frame.width,
            height: container.frame.height - 2 * AppConstants.ToolbarHeight - AppConstants.StatusBarHeight) // Don't let our cell overlap either of the toolbars
        title.alpha = 0
        setNeedsLayout()
    }

    func showAt(offsetY: Int, container: UIView, table: UITableView) {
        margin = TabTrayControllerUX.Margin
        container.insertSubview(self, atIndex: container.subviews.count)
        frame = CGRect(x: 0,
            y: AppConstants.ToolbarHeight + AppConstants.StatusBarHeight + CGFloat(offsetY) * TabTrayControllerUX.CellHeight,
            width: container.frame.width,
            height: TabTrayControllerUX.CellHeight)
        title.alpha = 1
        setNeedsLayout()
    }

    var tab: Browser? {
        didSet {
            titleText.text = tab?.title
        }
    }
}

struct SwipeAnimatorUX {
    let totalRotationInDegrees = 10.0
    let deleteThreshold = CGFloat(140)
    let totalScale = CGFloat(0.9)
    let totalAlpha = CGFloat(0.7)
    let minExitVelocity = CGFloat(800.0)
    let recenterAnimationDuration = NSTimeInterval(0.15)
}

private protocol SwipeAnimatorDelegate {
    func swipeAnimator(animator: SwipeAnimator, viewDidExitContainerBounds: UIView)
}

private class SwipeAnimator: NSObject {
    let animatingView: UIView
    let container: UIView
    let ux: SwipeAnimatorUX

    var originalCenter: CGPoint!
    var startLocation: CGPoint!
    var delegate: SwipeAnimatorDelegate?

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

            if (actualVelocity < self.ux.minExitVelocity || abs(self.animatingView.center.x - self.container.center.x) < self.ux.deleteThreshold) {
                UIView.animateWithDuration(self.ux.recenterAnimationDuration, animations: {
                    self.animatingView.transform = CGAffineTransformIdentity
                    self.animatingView.center = self.startLocation
                    self.animatingView.alpha = 1
                })
                return
            }

            // Otherwise we are good and we can get rid of the view

            // Calculate the edge to calculate distance from
            let edgeX = velocity.x > 0 ? CGRectGetMaxX(self.container.frame) :
                CGRectGetMinX(self.container.frame)
            var distance
            = (self.animatingView.frame.size.width / 2) + abs(self.animatingView.center.x - edgeX)

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

        default:
            break
        }
    }
}

extension SwipeAnimator: UIGestureRecognizerDelegate {
    private func gestureRecognizerShouldBegin(recognizer: UIGestureRecognizer) -> Bool {
        let cellView = recognizer.view as UIView!
        let panGesture = recognizer as UIPanGestureRecognizer
        let translation = panGesture.translationInView(cellView.superview!)
        return fabs(translation.x) > fabs(translation.y)
    }
}

class TabTrayController: UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource {
    var tabManager: TabManager!
    private let CellIdentifier = "CellIdentifier"
    var tableView: UITableView!
    var profile: Profile!
    var screenshotHelper: ScreenshotHelper!

    var navBar: UINavigationBar!

    override func viewDidLoad() {
        view.isAccessibilityElement = true
        view.accessibilityLabel = NSLocalizedString("Tabs Tray", comment: "Accessibility label for the Tabs Tray view.")

        navBar = UINavigationBar()

        navBar.barTintColor = TabTrayControllerUX.ToolbarBarTintColor
        navBar.tintColor = UIColor.whiteColor()
        navBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor()]

        navBar.layer.shadowColor = UIColor.blackColor().CGColor
        navBar.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        navBar.layer.shadowRadius = 2.0
        navBar.layer.shadowOpacity = 0.25
        
        let signInButton = UIButton.buttonWithType(UIButtonType.Custom) as UIButton
        signInButton.addTarget(self, action: "SELdidClickDone", forControlEvents: UIControlEvents.TouchUpInside)
        signInButton.setTitle(NSLocalizedString("Sign in", comment: "Button that leads to Sign in section of the Settings sheet."), forState: UIControlState.Normal)
        signInButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        
        let navItem = UINavigationItem()
        navItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "settings"), style: .Plain, target: self, action: "SELdidClickSettingsItem")
        navItem.leftBarButtonItem?.accessibilityLabel = NSLocalizedString("Settings", comment: "Accessibility label for the Settings button in the Tab Tray.")

        navItem.titleView = signInButton
        signInButton.hidden = true //hiding sign in button until we decide on UX

        navItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "add"), style: .Plain, target: self, action: "SELdidClickAddTab")


        navBar.pushNavigationItem(navItem, animated: false)

        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .None
        tableView.registerClass(TabCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.contentInset = UIEdgeInsets(top: AppConstants.StatusBarHeight + AppConstants.ToolbarHeight, left: 0, bottom: 0, right: 0)
        tableView.backgroundColor = TabTrayControllerUX.BackgroundColor

        view.addSubview(tableView)
        view.addSubview(navBar)

        navBar.snp_makeConstraints { make in
            make.top.equalTo(self.view)
            make.height.equalTo(AppConstants.StatusBarHeight + AppConstants.ToolbarHeight)
            make.left.right.equalTo(self.view)
            return
        }

        tableView.snp_makeConstraints { make in
            make.top.equalTo(self.view)
            make.left.right.bottom.equalTo(self.view)
        }
    }

    func SELdidClickDone() {
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func SELdidClickSettingsItem() {
        let controller = SettingsNavigationController()
        controller.profile = profile
        presentViewController(controller, animated: true, completion: nil)
    }

    func SELdidClickAddTab() {
        tabManager?.addTab()
        presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tab = tabManager.getTab(indexPath.item)
        tabManager.selectTab(tab)

        dispatch_async(dispatch_get_main_queue()) { _ in
            self.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tabManager.count
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return TabTrayControllerUX.CellHeight
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tab = tabManager.getTab(indexPath.item)
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as TabCell
        cell.animator.delegate = self
        cell.titleText.text = tab.displayTitle

        let screenshotAspectRatio = tableView.frame.width / TabTrayControllerUX.CellHeight
        cell.background.image = screenshotHelper.takeScreenshot(tab, aspectRatio: screenshotAspectRatio, quality: 1)
        return cell
    }

    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .None
    }
}

extension TabTrayController: Transitionable {
    private func getTransitionCell(options: TransitionOptions, browser: Browser?) -> TabCell {
        var transitionCell: TabCell
        if let cell = options.moving as? TabCell {
            transitionCell = cell
        } else {
            transitionCell = TabCell(style: UITableViewCellStyle.Default, reuseIdentifier: "id")
            options.moving = transitionCell
        }

        if let browser = browser {
            transitionCell.background.image = screenshotHelper.takeScreenshot(browser, aspectRatio: 0, quality: 1)
        } else {
            transitionCell.background.image = nil
        }
        transitionCell.titleText.text = browser?.displayTitle

        return transitionCell
    }

    func transitionableWillHide(transitionable: Transitionable, options: TransitionOptions) {
        // Create a fake cell that is shown fullscreen
        if let container = options.container {
            let cell = getTransitionCell(options, browser: tabManager.selectedTab)
            // TODO: Smoothly animate the corner radius to 0.
            cell.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
            cell.showFullscreen(container, table: tableView)
        }

        // Scroll the toolbar off the top
        navBar.alpha = 0
        navBar.transform = CGAffineTransformMakeTranslation(0, -AppConstants.ToolbarHeight)

        tableView.backgroundColor = UIColor.clearColor()
    }

    func transitionableWillShow(transitionable: Transitionable, options: TransitionOptions) {
        if let container = options.container {
            // Create a fake cell that is at the selected index
            let cell = getTransitionCell(options, browser: tabManager.selectedTab)
            cell.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
            cell.showAt(tabManager.selectedIndex, container: container, table: tableView)
        }

        // Scroll the toolbar on from the top
        navBar.alpha = 1
        navBar.transform = CGAffineTransformIdentity

        tableView.backgroundColor = TabTrayControllerUX.BackgroundColor
    }

    func transitionableWillComplete(transitionable: Transitionable, options: TransitionOptions) {
        if let cell = options.moving {
            cell.removeFromSuperview()
        }
    }
}

extension TabTrayController: SwipeAnimatorDelegate {
    private func swipeAnimator(animator: SwipeAnimator, viewDidExitContainerBounds: UIView) {
        let tabCell = animator.container as UITableViewCell
        if let indexPath = self.tableView.indexPathForCell(tabCell) {
            let tab = tabManager.getTab(indexPath.item)
            tabManager.removeTab(tab)
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
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
