/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

struct SiteTableViewControllerUX {
    static let HeaderHeight = CGFloat(25)
    static let RowHeight = CGFloat(58)
    static let HeaderBorderColor = UIColor(rgb: 0xCFD5D9).colorWithAlphaComponent(0.8)
    static let HeaderTextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x232323)
    static let HeaderBackgroundColor = UIColor(rgb: 0xECF0F3).colorWithAlphaComponent(0.3)
    static let HeaderFont = UIFont.systemFontOfSize(11, weight: UIFontWeightMedium)
}

class SiteTableViewHeader : UITableViewHeaderFooterView {
    // I can't get drawRect to play nicely with the glass background. As a fallback
    // we just use views for the top and bottom borders.
    let topBorder = UIView()
    let bottomBorder = UIView()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        addSubview(topBorder)
        addSubview(bottomBorder)
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .ExtraLight))

        textLabel?.font = SiteTableViewControllerUX.HeaderFont
        textLabel?.textColor = SiteTableViewControllerUX.HeaderTextColor
        textLabel?.textAlignment = .Center
        contentView.backgroundColor = SiteTableViewControllerUX.HeaderBackgroundColor
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        topBorder.frame = CGRect(x: 0, y: -0.5, width: frame.width, height: 0.5)
        bottomBorder.frame = CGRect(x: 0, y: frame.height, width: frame.width, height: 0.5)
        topBorder.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        bottomBorder.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
    }
}

/**
 * Provides base shared functionality for site rows and headers.
 */
class SiteTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    private let CellIdentifier = "CellIdentifier"
    private let HeaderIdentifier = "HeaderIdentifier"
    var profile: Profile! {
        didSet {
            reloadData()
        }
    }
    var data: Cursor<Site> = Cursor<Site>(status: .Success, msg: "No data set")
    var tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)
        tableView.snp_makeConstraints { make in
            make.edges.equalTo(self.view)
            return
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.registerClass(TwoLineTableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.registerClass(SiteTableViewHeader.self, forHeaderFooterViewReuseIdentifier: HeaderIdentifier)
        tableView.layoutMargins = UIEdgeInsetsZero
        tableView.keyboardDismissMode = UIScrollViewKeyboardDismissMode.OnDrag
        tableView.backgroundColor = UIConstants.PanelBackgroundColor
        tableView.separatorColor = UIConstants.SeparatorColor
        tableView.accessibilityIdentifier = "SiteTable"

        // Set an empty footer to prevent empty cells from appearing in the list.
        tableView.tableFooterView = UIView()
    }

    func reloadData() {
        if data.status != .Success {
            print("Err: \(data.statusMessage)", terminator: "\n")
        } else {
            self.tableView.reloadData()
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath)
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier(HeaderIdentifier)
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SiteTableViewControllerUX.HeaderHeight
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return SiteTableViewControllerUX.RowHeight
    }
}
