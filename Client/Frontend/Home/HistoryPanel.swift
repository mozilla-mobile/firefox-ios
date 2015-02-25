/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

import Storage

class HistoryPanel: SiteTableViewController {
    override func reloadData() {
        let opts = QueryOptions()
        opts.sort = .LastVisit
        profile.history.get(opts, complete: { (data: Cursor) -> Void in
            self.refreshControl?.endRefreshing()
            self.data = data
            self.tableView.reloadData()
        })
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let site = data[indexPath.row] as? Site {
            cell.textLabel?.text = site.title
            cell.detailTextLabel?.text = site.url
            if let img = site.icon? {
                let imgURL = NSURL(string: img.url)
                cell.imageView?.sd_setImageWithURL(imgURL, placeholderImage: self.profile.favicons.defaultIcon)
            } else {
                cell.imageView?.image = self.profile.favicons.defaultIcon
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let site = data[indexPath.row] as? Site {
            if let url = NSURL(string: site.url) {
                homePanelDelegate?.homePanel(didSubmitURL: url)
                return
            }
        }
        println("Could not click on history row")
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0
    }
}
