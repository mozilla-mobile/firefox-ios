/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

private let RemoteTabIdentifier = "RemoteTab"

class SyncedTabsViewController: UITableViewController, ClientSelectedDelegate, HomePanel {

    weak var homePanelDelegate: HomePanelDelegate? = nil
    var tabs: [RemoteTab]? = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = RemoteTabsPanelUX.RowHeight
        tableView.separatorInset = UIEdgeInsetsZero
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return self.tabs!.count ?? 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) ->
        UITableViewCell {
            tableView.registerClass(TwoLineTableViewCell.self, forCellReuseIdentifier: RemoteTabIdentifier)
            let cell = tableView.dequeueReusableCellWithIdentifier(RemoteTabIdentifier, forIndexPath: indexPath) as! TwoLineTableViewCell
            let tab = tabs?[indexPath.item]
            cell.setLines(tab!.title, detailText: tab!.URL.absoluteString)
            // TODO: Bug 1144765 - Populate image with cached favicons.
            return cell
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return RemoteTabsPanelUX.HeaderHeight
    }

    func reloadView() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.tableView.reloadData()
        })
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)

        if let tab = tabs?[indexPath.item] {
            // It's not a bookmark, so let's call it Typed (which means History, too).
            let visitType = VisitType.Typed
            homePanelDelegate?.homePanel(self, didSelectURL: tab.URL, visitType: visitType)
        }
    }
}