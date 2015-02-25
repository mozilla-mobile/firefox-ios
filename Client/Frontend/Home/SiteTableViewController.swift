/** This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

/** Provides some base shared functionality for home view panels for shared
 * row and header types.
 */
class SiteTableViewController: UITableViewController, HomePanel {
    weak var homePanelDelegate: HomePanelDelegate? = nil
    private let CellIdentifier = "CellIdentifier"
    private let HeaderIdentifier = "HeaderIdentifier"
    var profile: Profile! {
        didSet {
            reloadData()
        }
    }
    var data: Cursor = Cursor(status: .Success, msg: "No data set")

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.registerClass(TwoLineCell.self, forCellReuseIdentifier: CellIdentifier)
        let nib = UINib(nibName: "TabsViewControllerHeader", bundle: nil)
        tableView.registerNib(nib, forHeaderFooterViewReuseIdentifier: HeaderIdentifier)

        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: "reloadData", forControlEvents: UIControlEvents.ValueChanged)
    }

    func reloadData() {
        if data.status != .Success {
            println("Err: \(data.statusMessage)")
        } else {
            self.tableView.reloadData()
        }
        refreshControl?.endRefreshing()
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell
        // Callers should override this to fill in the cell returned here
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier(HeaderIdentifier) as? UIView
        // Callers should override this to fill in the cell returned here
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
}
