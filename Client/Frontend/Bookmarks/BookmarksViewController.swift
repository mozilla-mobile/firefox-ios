// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class BookmarksViewController: UITableViewController {
    private let BOOKMARK_CELL_IDENTIFIER = "BOOKMARK_CELL"
    private let BOOKMARK_HEADER_IDENTIFIER = "BOOKMARK_HEADER"

    var source: BookmarksModel!
    var _account: Account!
    var account: Account! {
        get {
            return _account
        }

        set (account) {
            self._account = account
            self.source = account.bookmarks.nullModel
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
        self.source.reloadData(self.onNewModel, self.onModelFailure)
    }
    
    func refresh() {
        reloadData()
    }
    
    override func viewDidAppear(animated: Bool) {
        reloadData()
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.source.current.count
    }
    
    private let FAVICON_SIZE = 32
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier(BOOKMARK_CELL_IDENTIFIER, forIndexPath: indexPath) as UITableViewCell

        let bookmark: BookmarkNode = self.source.current[indexPath.row]
        cell.imageView?.image = bookmark.icon
        cell.textLabel?.text = bookmark.title
        cell.textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        cell.textLabel?.textColor = UIColor.darkGrayColor()
        cell.indentationWidth = 20
        
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
    
    //    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    //        let objects = UINib(nibName: "TabsViewControllerHeader", bundle: nil).instantiateWithOwner(nil, options: nil)
    //        if let view = objects[0] as? UIView {
    //            if let label = view.viewWithTag(1) as? UILabel {
    //                // TODO: More button
    //            }
    //        }
    //        return view
    //    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: false)
        let bookmark = self.source.current[indexPath.row]

        switch (bookmark) {
        case let item as BookmarkItem:
            // Click it.
            UIApplication.sharedApplication().openURL(NSURL(string: item.url)!)
            break

        case let folder as BookmarkFolder:
            // Descend into the folder.
            self.source.selectFolder(folder, success: self.onNewModel, failure: self.onModelFailure)
            break

        default:
            // Weird.
            break        // Just here until there's another executable statement (compiler requires one).
        }
    }
}
