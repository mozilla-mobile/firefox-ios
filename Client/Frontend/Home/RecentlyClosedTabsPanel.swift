/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Shared
import Storage
import XCGLogger
import Deferred

private let log = Logger.browserLogger

class RecentlyClosedTabsPanel: UIViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var profile: Profile!

    private lazy var recentlyClosedHeader: UILabel = {
        let headerLabel = UILabel()
        headerLabel.text = Strings.RecentlyClosedTabsPanelTitle
        headerLabel.font = DynamicFontHelper.defaultHelper.DeviceFontHistoryPanel
        headerLabel.textAlignment = .Center
        headerLabel.backgroundColor = .whiteColor()
        return headerLabel
    }()

    private var tableViewController = RecentlyClosedTabsPanelSiteTableViewController()

    private lazy var historyBackButton: HistoryBackButton = {
        let button = HistoryBackButton()
        button.addTarget(self, action: #selector(RecentlyClosedTabsPanel.historyBackButtonWasTapped), forControlEvents: .TouchUpInside)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .whiteColor()

        tableViewController.profile = self.profile
        tableViewController.homePanelDelegate = homePanelDelegate
        tableViewController.recentlyClosedTabsPanel = self

        self.addChildViewController(tableViewController)
        self.view.addSubview(tableViewController.view)
        self.view.addSubview(historyBackButton)
        self.view.addSubview(recentlyClosedHeader)

        historyBackButton.snp_makeConstraints { make in
            make.top.left.right.equalTo(self.view)
            make.height.equalTo(50)
            make.bottom.equalTo(recentlyClosedHeader.snp_top)
        }

        recentlyClosedHeader.snp_makeConstraints { make in
            make.top.equalTo(historyBackButton.snp_bottom)
            make.height.equalTo(20)
            make.bottom.equalTo(tableViewController.view.snp_top).offset(-10)
            make.left.right.equalTo(self.view)
        }

        tableViewController.view.snp_makeConstraints { make in
            make.left.right.bottom.equalTo(self.view)
        }

        tableViewController.didMoveToParentViewController(self)
    }

    @objc private func historyBackButtonWasTapped(gestureRecognizer: UITapGestureRecognizer) {
        self.navigationController?.popViewControllerAnimated(true)
    }
}

class RecentlyClosedTabsPanelSiteTableViewController: SiteTableViewController {
    weak var homePanelDelegate: HomePanelDelegate?
    var recentlyClosedTabs: [ClosedTab] = []
    weak var recentlyClosedTabsPanel: RecentlyClosedTabsPanel?

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(RecentlyClosedTabsPanelSiteTableViewController.longPress(_:)))
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.addGestureRecognizer(longPressRecognizer)
        tableView.accessibilityIdentifier = "Recently Closed Tabs List"
        self.recentlyClosedTabs = profile.recentlyClosedTabs.tabs
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == UIGestureRecognizerState.Began else { return }
        let touchPoint = longPressGestureRecognizer.locationInView(tableView)
        guard let indexPath = tableView.indexPathForRowAtPoint(touchPoint) else { return }

        guard let contextMenu = createContextMenu(indexPath) else { return }
        self.presentViewController(contextMenu, animated: true, completion: nil)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        guard let twoLineCell = cell as? TwoLineTableViewCell else {
            return cell
        }
        let tab = recentlyClosedTabs[indexPath.row]
        let displayURL = tab.url.displayURL ?? tab.url
        twoLineCell.setLines(tab.title, detailText: displayURL.absoluteDisplayString)
        let site: Favicon? = (tab.faviconURL != nil) ? Favicon(url: tab.faviconURL!, type: .Guess) : nil
        cell.imageView?.setIcon(site, forURL: displayURL)
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let homePanelDelegate = homePanelDelegate,
              let recentlyClosedTabsPanel = recentlyClosedTabsPanel else {
            log.warning("No site or no URL when selecting row.")
            return
        }
        let visitType = VisitType.Typed    // Means History, too.
        homePanelDelegate.homePanel(recentlyClosedTabsPanel, didSelectURL: recentlyClosedTabs[indexPath.row].url, visitType: visitType)
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }

    // Functions that deal with showing header rows.
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profile.recentlyClosedTabs.tabs.count
    }

}

extension RecentlyClosedTabsPanelSiteTableViewController: HomePanelContextMenu {
    func getSiteDetails(indexPath: NSIndexPath) -> Site? {
        let closedTab = recentlyClosedTabs[indexPath.row]
        let site: Site
        if let title = closedTab.title {
            site = Site(url: String(closedTab.url), title: title)
        } else {
            site = Site(url: String(closedTab.url), title: "")
        }
        return site
    }

    func getImageDetails(indexPath: NSIndexPath) -> (siteImage: UIImage?, siteBGColor: UIColor?) {
        guard let tabCell = super.tableView.cellForRowAtIndexPath(indexPath) else { return (nil, nil) }
        return (tabCell.imageView?.image, tabCell.imageView?.backgroundColor)
    }

    func getContextMenuActions(site: Site, indexPath: NSIndexPath) -> [ActionOverlayTableViewAction]? {
        return getDefaultContextMenuActions(site, homePanelDelegate: homePanelDelegate)
    }
}
