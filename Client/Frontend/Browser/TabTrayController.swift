/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class TabTrayController: UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource {
    var tabManager: TabManager!

    override func viewDidLoad() {
        let toolbar = UIToolbar()
        view.addSubview(toolbar)

        let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "SELdidClickDone")
        let addTabItem = UIBarButtonItem(title: "Add tab", style: UIBarButtonItemStyle.Plain, target: self, action: "SELdidClickAddTab")
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        toolbar.items = [doneItem, spacer, addTabItem]

        let tabTableView = UITableView()
        tabTableView.dataSource = self
        tabTableView.delegate = self
        view.addSubview(tabTableView)

        toolbar.snp_makeConstraints { make in
            make.top.equalTo(self.view).offset(StatusBarHeight)
            make.left.right.equalTo(self.view)
            return
        }

        tabTableView.snp_makeConstraints { make in
            make.top.equalTo(toolbar.snp_bottom)
            make.left.right.bottom.equalTo(self.view)
        }
    }

    func SELdidClickDone() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    func SELdidClickAddTab() {
        tabManager?.addTab()
        dismissViewControllerAnimated(true, completion: nil)
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let tab = tabManager.getTab(indexPath.item)
        tabManager.selectTab(tab)
        dismissViewControllerAnimated(true, completion: nil)
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tabManager.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tab = tabManager.getTab(indexPath.item)
        let cell = UITableViewCell()
        cell.textLabel?.text = tab.url?.absoluteString
        cell.selected = (tab === tabManager.selectedTab)
        return cell
    }

    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let tab = tabManager.getTab(indexPath.item)
        tabManager.removeTab(tab)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
    }
}