/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import UIKit
import Account
import Shared
import SnapKit
import Storage
import Sync
import XCGLogger

private let RemoteClientIdentifier = "RemoteClient"

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()

protocol ClientSelectedDelegate {
    var tabs: [RemoteTab]? {get set}
    func reloadView()
}

class ClientsViewController: UITableViewController {
    var delegate:ClientSelectedDelegate?
    var profile: Profile!
    var clientAndTabs: [ClientAndTabs]?
    var index: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = RemoteTabsPanelUX.RowHeight
        tableView.separatorInset = UIEdgeInsetsZero
        tableView.delaysContentTouches = false
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "SELrefresh", forControlEvents: UIControlEvents.ValueChanged)
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.SELrefresh()
    }

    func refreshView()
    {
        self.SELrefresh()
    }

    @objc private func SELrefresh() {
        self.refreshControl?.beginRefreshing()

        self.profile.getClientsAndTabs().upon({ tabs in
            if let tabs = tabs.successValue {
                log.info("\(tabs.count) tabs fetched.")
                self.clientAndTabs = tabs.filter { $0.tabs.count > 0 }

                // Maybe show a background view.
                let tableView = self.tableView
                if let clientAndTabs = self.clientAndTabs where clientAndTabs.count > 0 {
                    tableView.backgroundView = nil
                    // Show dividing lines.
                    tableView.separatorStyle = UITableViewCellSeparatorStyle.SingleLine
                } else {
                    // TODO: Bug 1144760 - Populate background view with UX-approved content.
                    tableView.backgroundView = UIView()
                    tableView.backgroundView?.frame = tableView.frame
                    tableView.backgroundView?.backgroundColor = UIColor.redColor()

                    // Hide dividing lines.
                    tableView.separatorStyle = UITableViewCellSeparatorStyle.None
                }
                tableView.reloadData()

                if self.clientAndTabs?.count > 0
                {
                    let rowToSelect:NSIndexPath = NSIndexPath(forRow: 0, inSection: 0)
                    self.tableView.selectRowAtIndexPath(rowToSelect, animated: false, scrollPosition: UITableViewScrollPosition.None)
                    self.tableView(self.tableView, didSelectRowAtIndexPath: rowToSelect)
                }
            } else {
                log.error("Failed to fetch tabs.")
            }

            // Always end refreshing, even if we failed!
            self.refreshControl?.endRefreshing()
        })
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return self.clientAndTabs?.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCell {
            self.tableView.registerClass(TwoLineTableViewCell.self, forCellReuseIdentifier: RemoteClientIdentifier)
            let cell = tableView.dequeueReusableCellWithIdentifier(RemoteClientIdentifier, forIndexPath: indexPath) as! TwoLineTableViewCell

            if let clientTabs = self.clientAndTabs?[indexPath.item] {
                let client = clientTabs.client
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

                let image: UIImage?
                if client.type == "desktop" {
                    image = UIImage(named: "deviceTypeDesktop")
                    image?.accessibilityLabel = NSLocalizedString("computer", comment: "Accessibility label for Desktop Computer (PC) image in remote tabs list")
                } else {
                    image = UIImage(named: "deviceTypeMobile")
                    image?.accessibilityLabel = NSLocalizedString("mobile device", comment: "Accessibility label for Mobile Device image in remote tabs list")
                }
                cell.setLines(client.name, detailText: String(format: label, String(timestamp)))
                cell.imageView?.image = image
            }

            return cell
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return RemoteTabsPanelUX.HeaderHeight
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.index = indexPath.row
        self.delegate?.tabs = self.clientAndTabs?[self.index].tabs
        self.delegate?.reloadView()
    }
}

