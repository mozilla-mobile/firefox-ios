/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

class ReaderPanel: UITableViewController, HomePanel {

    var readingListItemsCursor: Cursor? = nil
    weak var delegate: HomePanelDelegate? = nil

    var profile: Profile! {
        didSet {
            profile.readingList.get { (cursor) -> Void in
                self.readingListItemsCursor = (cursor.status == .Success) ? cursor : nil
                self.tableView.reloadData()
            }
        }
    }

    // MARK: UITableViewDataSourceDelegate

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let cursor = self.readingListItemsCursor {
            return cursor.count
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "ReadingListCell")
        if let cursor = self.readingListItemsCursor {
            if let readingListItem = cursor[indexPath.row] as? ReadingListItem {
                cell.textLabel?.text = readingListItem.title
            }
        }
        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let cursor = self.readingListItemsCursor {
            if let readingListItem = cursor[indexPath.row] as? ReadingListItem {
                if let encodedURL = readingListItem.url.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet()) {
                    if let aboutReaderURL = NSURL(string: "about:reader?url=\(encodedURL)") {
                        delegate?.homePanel(didSubmitURL: aboutReaderURL)
                    }
                }
            }
        }
    }
}
