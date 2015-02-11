/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

class BookmarksPanel: UITableViewController, HomePanel {
    private let BOOKMARK_CELL_IDENTIFIER = "BOOKMARK_CELL"
    private let BOOKMARK_HEADER_IDENTIFIER = "BOOKMARK_HEADER"

    var delegate: HomePanelDelegate? = nil

    var source: BookmarksModel?
    var _profile: Profile!
    var profile: Profile! {
        get {
            return _profile
        }

        set (profile) {
            self._profile = profile
            profile.bookmarks.modelForRoot(self.onNewModel, failure: self.onModelFailure)
        }
    }

    func onNewModel(model: BookmarksModel) {
        // Switch out the model and redisplay.
        self.source = model
        dispatch_async(dispatch_get_main_queue()) {
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }

    func onModelFailure(e: Any) {
        // Do nothing.
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.sectionFooterHeight = 0
        //tableView.separatorStyle = UITableViewCellSeparatorStyle.None
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: BOOKMARK_CELL_IDENTIFIER)
        let nib = UINib(nibName: "TabsViewControllerHeader", bundle: nil)
        tableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: BOOKMARK_HEADER_IDENTIFIER)

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
    }


    func reloadData() {
        self.source?.reloadData(self.onNewModel, self.onModelFailure)
    }

    func refresh() {
        reloadData()
    }

    override func viewDidAppear(animated: Bool) {
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let source = source {
            return source.current.count
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(BOOKMARK_CELL_IDENTIFIER, forIndexPath: indexPath) as UITableViewCell

        if let source = source {
            let bookmark = source.current[indexPath.row]
            cell.imageView?.image = bookmark.icon
            cell.textLabel?.text = bookmark.title
            cell.textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13)
            cell.textLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
            cell.indentationWidth = 20
        }

        return cell
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 42
    }

    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueReusableHeaderFooterViewWithIdentifier(BOOKMARK_HEADER_IDENTIFIER) as? UIView

        if let label = view?.viewWithTag(1) as? UILabel {
            label.text = "Recent Bookmarks"
        }

        return view
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        if let source = source {
            let bookmark = source.current[indexPath.row]

            switch (bookmark) {
            case let item as BookmarkItem:
                delegate?.homePanel(didSubmitURL: NSURL(string: item.url)!)
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
