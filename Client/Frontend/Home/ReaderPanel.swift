/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

class ReaderPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil

    override func reloadData() {
        profile.readingList.get { (cursor) -> Void in
            self.refreshControl?.endRefreshing()
            self.data = cursor
            self.tableView.reloadData()
        }
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let readingListItem = data[indexPath.row] as? ReadingListItem {
            cell.textLabel?.text = readingListItem.title
            cell.detailTextLabel?.text = readingListItem.excerpt
        }
        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let readingListItem = data[indexPath.row] as? ReadingListItem {
            if let encodedURL = readingListItem.url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) {
                if let aboutReaderURL = NSURL(string: "about:reader?url=\(encodedURL)") {
                    homePanelDelegate?.homePanel(self, didSelectURL: aboutReaderURL)
                }
            }
        }
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
}
