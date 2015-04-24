/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Account
import Shared
import Snap
import Storage
import Sync
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()


private struct RemoteTabsPanelUX {
    static let HeaderHeight: CGFloat = SiteTableViewControllerUX.RowHeight // Not HeaderHeight!
    static let RowHeight: CGFloat = SiteTableViewControllerUX.RowHeight
}

private let RemoteClientIdentifier = "RemoteClient"
private let RemoteTabIdentifier = "RemoteTab"

/**
 * Display a tree hierarchy of remote clients and tabs, like:
 * client
 *   tab
 *   tab
 * client
 *   tab
 *   tab
 * This is not a SiteTableViewController because it is inherently tree-like and not list-like;
 * a technical detail is that STVC is backed by a Cursor and this is backed by a richer data
 * structure.  However, the styling here should agree with STVC where possible.
 */
class RemoteTabsPanel: UITableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var profile: Profile!
    var timer: NSTimer!

    private var clientAndTabs: [ClientAndTabs]?

    private func tabAtIndexPath(indexPath: NSIndexPath) -> RemoteTab? {
        return self.clientAndTabs?[indexPath.section].tabs[indexPath.item]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerClass(TwoLineHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: RemoteClientIdentifier)
        tableView.registerClass(TwoLineTableViewCell.self, forCellReuseIdentifier: RemoteTabIdentifier)
        tableView.rowHeight = RemoteTabsPanelUX.RowHeight
        tableView.separatorInset = UIEdgeInsetsZero

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "SELrefresh", forControlEvents: UIControlEvents.ValueChanged)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.SELrefresh()
    }

    override func viewDidAppear(animated: Bool) {
        timer = NSTimer.scheduledTimerWithTimeInterval(60.0, target: self.tableView, selector: Selector("reloadData"), userInfo: nil, repeats: true)
    }

    override func viewWillDisappear(animated: Bool) {
        timer.invalidate()
    }

    @objc private func SELrefresh() {
        self.refreshControl?.beginRefreshing()

        self.profile.getClientsAndTabs().upon({ tabs in
            if let tabs = tabs.successValue {
                log.info("\(tabs.count) tabs fetched.")
                self.clientAndTabs = tabs

                // Maybe show a background view.
                let tableView = self.tableView
                if tabs.isEmpty {
                    // TODO: Bug 1144760 - Populate background view with UX-approved content.
                    tableView.backgroundView = UIView()
                    tableView.backgroundView?.frame = tableView.frame
                    tableView.backgroundView?.backgroundColor = UIColor.redColor()

                    // Hide dividing lines.
                    tableView.separatorStyle = UITableViewCellSeparatorStyle.None
                } else {
                    tableView.backgroundView = nil
                    // Show dividing lines.
                    tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
                }
                tableView.reloadData()
            } else {
                log.error("Failed to fetch tabs.")
            }

            // Always end refreshing, even if we failed!
            self.refreshControl?.endRefreshing()
        })
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        log.debug("We have \(self.clientAndTabs?.count) sections.")
        return self.clientAndTabs?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        log.debug("Section \(section) has \(self.clientAndTabs?[section].tabs.count) tabs.")
        return self.clientAndTabs?[section].tabs.count ?? 0
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return RemoteTabsPanelUX.HeaderHeight
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let clientTabs = self.clientAndTabs?[section] {
            let client = clientTabs.client
            let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(RemoteClientIdentifier) as! TwoLineHeaderFooterView
            view.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: RemoteTabsPanelUX.HeaderHeight)
            view.textLabel.text = client.name

            // TODO: Bug 1154088 - Convert timestamp to locale-relative timestring.

            /*
             * A note on timestamps.
             * We have access to two timestamps here: the timestamp of the remote client record,
             * and the set of timestamps of the client's tabs.
             * Neither is "last synced". The client record timestamp changes whenever the remote
             * client uploads its record (i.e., infrequently), but also whenever another device
             * sends a command to that client -- which can be much later than when that client
             * last synced.
             * The client's tabs haven't necessarily changed, but it can still have synced.
             * Ideally, we should save and use the modified time of the tabs record itself.
             * This will be the real time that the other client uploaded tabs.
             */
            let timestamp = clientTabs.approximateLastSyncTime()
            let label = NSLocalizedString("Last synced: %@", comment: "Remote tabs last synced time")
            view.detailTextLabel.text = String(format: label, timestamp.toNSDate().toRelativeTimeString())
            if client.type == "desktop" {
                view.imageView.image = UIImage(named: "deviceTypeDesktop")
            } else {
                view.imageView.image = UIImage(named: "deviceTypeMobile")
            }
            return view
        }

        return nil
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(RemoteTabIdentifier, forIndexPath: indexPath) as! TwoLineTableViewCell
        let tab = tabAtIndexPath(indexPath)
        cell.setLines(tab?.title, detailText: tab?.URL.absoluteString)
        // TODO: Bug 1144765 - Populate image with cached favicons.
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        if let tab = tabAtIndexPath(indexPath) {
            homePanelDelegate?.homePanel(self, didSelectURL: tab.URL)
        }
    }
}
