/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let TextBoxHeight = CGFloat(25.0)
private let Margin = CGFloat(10)
private let CellHeight = TextBoxHeight * 4

// UITableViewController doesn't let us specify a style for recycling views. We override the default style here.
private class CustomCell : UITableViewCell {
    let backgroundHolder: UIView
    let background: UIImageViewAligned
    let title: UITextView
    var margin = Margin

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.backgroundHolder = UIView()
        self.backgroundHolder.layer.shadowColor = UIColor.blackColor().CGColor
        self.backgroundHolder.layer.shadowOffset = CGSizeMake(0,0)
        self.backgroundHolder.layer.shadowOpacity = 0.25
        self.backgroundHolder.layer.shadowRadius = 2.0

        self.background = UIImageViewAligned()
        self.background.contentMode = UIViewContentMode.ScaleAspectFill
        self.background.clipsToBounds = true
        self.background.userInteractionEnabled = false
        self.background.alignLeft = true
        self.background.alignTop = true

        self.title = UITextView()
        self.title.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.75)
        self.title.textColor = UIColor.whiteColor()
        self.title.textAlignment = NSTextAlignment.Left
        self.title.userInteractionEnabled = false

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundHolder.addSubview(self.background)
        addSubview(backgroundHolder)
        addSubview(self.title)
        backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)

        selectionStyle = .None
        self.title.addObserver(self, forKeyPath: "contentSize", options: .New, context: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.title.removeObserver(self, forKeyPath: "contentSize")
    }

    private override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        let tv = object as UITextView
        verticalCenter(tv)
    }

    private func verticalCenter(text: UITextView) {
        var  top = (TextBoxHeight - text.contentSize.height) * text.zoomScale / 2.0
        top = top < 0.0 ? 0.0 : top
        text.contentOffset = CGPoint(x: 0, y: -top)
    }

    func showFullscreen(container: UIView, table: UITableView) {
        margin = 0
        container.insertSubview(self, atIndex: container.subviews.count)
        frame = CGRect(x: container.frame.origin.x,
            y: container.frame.origin.y + ToolbarHeight + StatusBarHeight,
            width: container.frame.width,
            height: container.frame.height - ToolbarHeight - ToolbarHeight - StatusBarHeight) // Don't let our cell overlap either of the toolbars
        title.alpha = 0
        setNeedsLayout()
    }

    func showAt(offsetY: Int, container: UIView, table: UITableView) {
        margin = Margin
        container.insertSubview(self, atIndex: container.subviews.count)
        frame = CGRect(x: 0,
            y: ToolbarHeight + StatusBarHeight + CGFloat(offsetY) * CellHeight - table.contentOffset.y,
            width: container.frame.width,
            height: CellHeight)
        title.alpha = 1
        setNeedsLayout()
    }

    var tab: Browser? {
        didSet {
            background.image = tab?.screenshot()
            title.text = tab?.title
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let w = frame.width - 2 * margin
        let h = frame.height - margin

        backgroundHolder.frame = CGRect(x: margin,
            y: margin,
            width: w,
            height: h)
        background.frame = CGRect(origin: CGPointMake(0,0), size: backgroundHolder.frame.size)

        title.frame = CGRect(x: 0 + margin,
            y: 0 + frame.height - TextBoxHeight,
            width: frame.width - 2 * margin,
            height: TextBoxHeight)

        verticalCenter(title)
    }
}

class TabTrayController: UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource {
    var tabManager: TabManager!
    private let CellIdentifier = "CellIdentifier"
    var tableView: UITableView!
    var profile: Profile!

    var toolbar: UIToolbar!

    override func viewDidLoad() {
        toolbar = UIToolbar()
        toolbar.backgroundImageForToolbarPosition(.Top, barMetrics: UIBarMetrics.Compact)
        toolbar.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.addSubview(toolbar)

        let settingsItem = UIBarButtonItem(title: "\u{2699}", style: .Plain, target: self, action: "SELdidClickSettingsItem")
        let signinItem = UIBarButtonItem(title: "Sign in", style: .Plain, target: self, action: "SELdidClickDone")
        signinItem.enabled = false
        let addTabItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "SELdidClickAddTab")
        let spacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)
        toolbar.setItems([settingsItem, spacer, signinItem, spacer, addTabItem], animated: true)

        tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .None
        tableView.registerClass(CustomCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0)
        view.addSubview(tableView)

        toolbar.snp_makeConstraints { make in
            make.top.equalTo(self.view).offset(StatusBarHeight)
            make.left.right.equalTo(self.view)
            return
        }

        tableView.snp_makeConstraints { make in
            make.top.equalTo(self.toolbar.snp_bottom)
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
        return CellHeight
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tab = tabManager.getTab(indexPath.item)
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as CustomCell
        cell.title.text = tab.title
        cell.background.image = tab.screenshot(size: CGSize(width: tableView.frame.width, height: CellHeight))
        return cell
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let tab = tabManager.getTab(indexPath.item)
        tabManager.removeTab(tab)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
    }
}

extension TabTrayController : Transitionable {
    private func getTransitionCell(options: TransitionOptions, browser: Browser?) -> CustomCell {
        if let cell = options.moving as? CustomCell {
            cell.tab = browser
            return cell
        } else {
            let cell = CustomCell(style: UITableViewCellStyle.Default, reuseIdentifier: "id")
            cell.tab = browser
            options.moving = cell
            return cell
        }
    }

    func transitionableWillHide(transitionable: Transitionable, options: TransitionOptions) {
        // Create a fake cell that is shown fullscreen
        if let container = options.container {
            let cell = getTransitionCell(options, browser: tabManager.selectedTab)
            cell.showFullscreen(container, table: tableView)
        }

        // Scroll the toolbar off the top
        toolbar.alpha = 0
        toolbar.transform = CGAffineTransformMakeTranslation(0, -ToolbarHeight)
    }

    func transitionableWillShow(transitionable: Transitionable, options: TransitionOptions) {
        if let container = options.container {
            // Create a fake cell that is at the selected index
            let cell = getTransitionCell(options, browser: tabManager.selectedTab)
            cell.showAt(tabManager.selectedIndex, container: container, table: tableView)
        }

        // Scroll the toolbar on from the top
        toolbar.alpha = 1
        toolbar.transform = CGAffineTransformIdentity
    }

    func transitionableWillComplete(transitionable: Transitionable, options: TransitionOptions) {
        if let cell = options.moving {
            cell.removeFromSuperview()
        }
    }
}

