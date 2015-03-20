/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Snap
import Storage

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

    private var clients: [RemoteClient]?

    private func tabAtIndexPath(indexPath: NSIndexPath) -> RemoteTab? {
        return clients?[indexPath.section].tabs[indexPath.item]
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

    @objc private func SELrefresh() {
        self.refreshControl?.beginRefreshing()
        profile.remoteClientsAndTabs.getClientsAndTabs { clients in
            self.refreshControl?.endRefreshing()
            self.clients = clients
            // Maybe show a background view.
            let tableView = self.tableView
            if self.clients == nil || self.clients!.isEmpty {
                tableView.backgroundView = UIView()
                tableView.backgroundView?.frame = tableView.frame
                // TODO: Populate background view with UX-approved content.
                tableView.backgroundView?.backgroundColor = UIColor.redColor()
                // Hide dividing lines.
                tableView.separatorStyle = UITableViewCellSeparatorStyle.None
            } else {
                tableView.backgroundView = nil
                // Show dividing lines.
                tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
            }
            tableView.reloadData()
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return clients?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clients?[section].tabs.count ?? 0
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return RemoteTabsPanelUX.HeaderHeight
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if let client = clients?[section] {
            let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(RemoteClientIdentifier) as TwoLineHeaderFooterView
            view.frame = CGRect(x: 0, y: 0, width: tableView.frame.width, height: RemoteTabsPanelUX.HeaderHeight)
            view.textLabel.text = client.name
            // TODO: allow localization; convert timestamp to relative timestring.
            view.detailTextLabel.text = "Last synced: \(String(client.lastModified))"
            if client.type == "desktop" {
                view.imageView.image = UIImage(named: "deviceTypeDesktop")
            } else {
                view.imageView.image = UIImage(named: "deviceTypeMobile")
            }
            return view
        } else {
            return nil
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(RemoteTabIdentifier, forIndexPath: indexPath) as TwoLineTableViewCell
        if let tab = tabAtIndexPath(indexPath) {
            // TODO: Populate image with cached favicons.
            if let title = tab.title {
                cell.textLabel?.text = title
                cell.detailTextLabel?.text = tab.URL.absoluteString
            } else {
                cell.textLabel?.text = tab.URL.absoluteString
                cell.detailTextLabel?.text = nil
            }
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        if let tab = tabAtIndexPath(indexPath) {
            homePanelDelegate?.homePanel(self, didSelectURL: tab.URL)
        }
    }
}
