/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit

class BackForwardListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var listData: [WKBackForwardListItem]?
    var tabManager: TabManager!

    override func viewDidLoad() {
        let toolbar = UIToolbar()
        view.addSubview(toolbar)

        let doneItem = UIBarButtonItem(title: NSLocalizedString("Done", comment: "Done button label on back forward list screen"), style: .Done, target: self, action: "SELdidClickDone")
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        toolbar.items = [doneItem, spacer]

        let listTableView = UITableView()
        listTableView.dataSource = self
        listTableView.delegate = self
        view.addSubview(listTableView)

        toolbar.snp_makeConstraints { make in
            let topLayoutGuide = self.topLayoutGuide as! UIView
            make.top.equalTo(topLayoutGuide.snp_bottom)
            make.left.right.equalTo(self.view)
            return
        }

        listTableView.snp_makeConstraints { make in
            make.top.equalTo(toolbar.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }
    }

    func SELdidClickDone() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Table view

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listData?.count ?? 0
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let item = listData![indexPath.item]
        cell.textLabel?.text = item.title ?? item.URL.absoluteString
        return cell
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tabManager.selectedTab?.goToBackForwardListItem(listData![indexPath.item])
        dismissViewControllerAnimated(true, completion: nil)
    }
}
