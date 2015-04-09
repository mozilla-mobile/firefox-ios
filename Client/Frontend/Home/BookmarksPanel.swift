/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

class BookmarksPanel: SiteTableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    var source: BookmarksModel?

    override var profile: Profile! {
        didSet {
            profile.bookmarks.modelForRoot(self.onNewModel, failure: self.onModelFailure)
        }
    }

    private func onNewModel(model: BookmarksModel) {
        self.source = model
        dispatch_async(dispatch_get_main_queue()) {
            self.tableView.reloadData()
        }
    }

    private func onModelFailure(e: Any) {
        println("Error: failed to get data: \(e)")
    }

    override func reloadData() {
        self.source?.reloadData(self.onNewModel, failure: self.onModelFailure)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let source = source {
            return source.current.count
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let source = source {
            let bookmark = source.current[indexPath.row]
            if let favicon = bookmark?.favicon {
                cell.imageView?.sd_setImageWithURL(NSURL(string: favicon.url)!, placeholderImage: profile.favicons.defaultIcon)
            }
            cell.textLabel?.text = bookmark?.title
        }

        return cell
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("Recent Bookmarks", comment: "Header for bookmarks list")
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        if let source = source {
            let bookmark = source.current[indexPath.row]

            switch (bookmark) {
            case let item as BookmarkItem:
                homePanelDelegate?.homePanel(self, didSelectURL: NSURL(string: item.url)!)
                break

            case let folder as BookmarkFolder:
                // Descend into the folder.
                source.selectFolder(folder, success: self.onNewModel, failure: self.onModelFailure)
                break

            default:
                // Weird.
                break        // Just here until there's another executable statement (compiler requires one).
            }
        }
    }
}
