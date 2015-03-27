/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Storage

struct SiteTableViewControllerUX {
    static let HeaderHeight = CGFloat(25)
    static let RowHeight = CGFloat(58)
    static let HeaderBorderColor = UIColor(rgb: 0xCFD5D9).colorWithAlphaComponent(0.8)
    static let HeaderTextColor = UIColor(rgb: 0x565656)
    static let HeaderBackgroundColor = UIColor(rgb: 0xECF0F3).colorWithAlphaComponent(0.7)
}

private class SiteTableViewHeader : UITableViewHeaderFooterView {
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
        addSubview(topBorder)
        addSubview(bottomBorder)
        backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        topBorder.frame = CGRect(x: 0, y: -0.5, width: frame.width, height: 0.5)
        bottomBorder.frame = CGRect(x: 0, y: frame.height, width: frame.width, height: 0.5)
        topBorder.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        bottomBorder.backgroundColor = SiteTableViewControllerUX.HeaderBorderColor
        super.layoutSubviews()

        textLabel.font = UIFont(name: "HelveticaNeue-Medium", size: 11)
        textLabel.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : SiteTableViewControllerUX.HeaderTextColor
        textLabel.textAlignment = .Center
        contentView.backgroundColor = SiteTableViewControllerUX.HeaderBackgroundColor
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
    var data: Cursor = Cursor(status: .Success, msg: "No data set")
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
    }

    func reloadData() {
        if data.status != .Success {
            println("Err: \(data.statusMessage)")
        } else {
            self.tableView.reloadData()
        }
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCellWithIdentifier(CellIdentifier) as UITableViewCell
        // Callers should override this to fill in the cell returned here
    }

    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterViewWithIdentifier(HeaderIdentifier) as? UIView
        // Callers should override this to fill in the cell returned here
    }

    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return SiteTableViewControllerUX.HeaderHeight
    }

    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return SiteTableViewControllerUX.RowHeight
    }
}
