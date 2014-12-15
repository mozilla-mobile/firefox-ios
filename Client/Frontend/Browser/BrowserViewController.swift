/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

private let StatusBarHeight = 20

class BrowserViewController: UIViewController, BrowserToolbarDelegate, TabManagerDelegate {
    var toolbar: BrowserToolbar!
    let tabManager = TabManager()

    override func viewDidLoad() {
        toolbar = BrowserToolbar()
        view.addSubview(toolbar)

        toolbar.snp_makeConstraints { make in
            make.top.equalTo(self.view).offset(StatusBarHeight)
            make.height.equalTo(44)
            make.leading.trailing.equalTo(self.view)
        }

        toolbar.browserToolbarDelegate = self
        tabManager.delegate = self

        tabManager.addTab()
    }

    func didClickBack() {
        tabManager.selectedTab?.goBack()
    }

    func didClickForward() {
        tabManager.selectedTab?.goForward()
    }

    func didClickAddTab() {
        let controller = TabTrayController()
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
    }

    func didEnterURL(url: NSURL) {
        tabManager.selectedTab?.loadRequest(NSURLRequest(URL: url))
    }

    func didSelectedTabChange(selected: Browser?, previous: Browser?) {
        previous?.view.hidden = true
        selected?.view.hidden = false
    }

    func didAddTab(tab: Browser) {
        toolbar.updateTabCount(tabManager.count)

        tab.view.hidden = true
        view.addSubview(tab.view)
        tab.view.snp_makeConstraints { make in
            make.top.equalTo(self.toolbar.snp_bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }
        tab.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.mozilla.org")!))
    }

    func didRemoveTab(tab: Browser) {
        toolbar.updateTabCount(tabManager.count)

        tab.view.removeFromSuperview()
    }
}