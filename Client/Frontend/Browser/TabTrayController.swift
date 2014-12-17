/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let StatusBarHeight = 20

class TabTrayController: UIViewController, UITabBarDelegate {
    var tabManager: TabManager?
    private var tabDataSource: TabTableDataSource?
    private var tabDelegate: TabTableDelegate?

    override func viewDidLoad() {
        let toolbar = UIToolbar()
        view.addSubview(toolbar)

        let doneItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: "SELdidClickDone")
        let addTabItem = UIBarButtonItem(title: "Add tab", style: UIBarButtonItemStyle.Plain, target: self, action: "SELdidClickAddTab")
        let spacer = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        toolbar.items = [doneItem, spacer, addTabItem]

        let tabTableView = UITableView()
        if var tabs = tabManager?.getTabs() {
            tabDataSource = TabTableDataSource(tabs: &tabs, selectedTab: tabManager!.selectedTab, { [unowned self] tab in
                self.tabManager?.removeTab(tab)
                self.tabDataSource?.selectedTab = self.tabManager?.selectedTab
                return
            })

            tabDelegate = TabTableDelegate(tabs: &tabs, { [unowned self] tab in
                self.tabManager?.selectTab(tab)
                self.dismissViewControllerAnimated(true, completion: nil)
            })

            tabTableView.dataSource = tabDataSource
            tabTableView.delegate = tabDelegate
        }
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
}

private class TabTableDelegate: NSObject, UITableViewDelegate {
    let tabs: [Browser]
    let selectCallback: Browser -> ()

    init (inout tabs: [Browser], selectCallback: Browser -> ()) {
        self.tabs = tabs
        self.selectCallback = selectCallback
    }

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectCallback(tabs[indexPath.item])
    }
}

private class TabTableDataSource: NSObject, UITableViewDataSource {
    var tabs: [Browser]
    var selectedTab: Browser?
    let removeCallback: Browser -> ()

    init (inout tabs: [Browser], selectedTab: Browser?, removeCallback: Browser -> ()) {
        self.tabs = tabs
        self.selectedTab = selectedTab
        self.removeCallback = removeCallback
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tabs.count
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let tab = tabs[indexPath.item]
        let cell = UITableViewCell()
        cell.textLabel?.text = tab.url?.absoluteString
        cell.selected = (tab === selectedTab)
        return cell
    }

    private func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let tab = tabs.removeAtIndex(indexPath.item)
        tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        removeCallback(tab)
    }
}