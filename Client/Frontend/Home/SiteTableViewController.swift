/** This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

/** Provides some base shared functionality for home view panels for shared
 * row and header types.
 */
class SiteTableViewHeader : UITableViewHeaderFooterView {
    // I can't get drawRect to play nicely with the glass background. As a fallback
    // we just use views for the top and bottom borders.
    let topBorder = UIView()
    let bottomBorder = UIView()
    override init() {
        super.init()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        didLoad()
    }

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
    }

    private func didLoad() {
        println("Did load \(self)")
        addSubview(topBorder)
        addSubview(bottomBorder)
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        topBorder.frame = CGRect(x: 0, y: 0, width: frame.width, height: 1)
        bottomBorder.frame = CGRect(x: 0, y: frame.height - 1, width: frame.width, height: 1)
        topBorder.backgroundColor = UIColor.lightGrayColor()
        bottomBorder.backgroundColor = UIColor.lightGrayColor()
        super.layoutSubviews()

        textLabel.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        textLabel.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkTextColor()
        textLabel.textAlignment = .Center
        contentView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.05)
    }
}

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
        tableView.registerClass(SiteTableViewHeader.self, forHeaderFooterViewReuseIdentifier: HeaderIdentifier)

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
        return 25
    }
}
