/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebKit

private let StatusBarHeight = 20

class BrowserViewController: UIViewController, BrowserToolbarDelegate, TabManagerDelegate, WKNavigationDelegate {
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

    func didBeginEditing() {
        let account = MockAccount()
        let controller = TabBarViewController(nibName: "TabBarViewController", bundle: nil)
        controller.account = account
        presentViewController(controller, animated: true, completion: nil)
    }

    func didClickBack() {
        tabManager.selectedTab?.goBack()
    }
    
    func didLongPressBack() {
        let controller = BackForwardListViewController()
        controller.listData = tabManager.selectedTab?.backList
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
    }

    func didClickForward() {
        tabManager.selectedTab?.goForward()
    }

    func didLongPressForward() {
        let controller = BackForwardListViewController()
        controller.listData = tabManager.selectedTab?.forwardList
        controller.tabManager = tabManager
        presentViewController(controller, animated: true, completion: nil)
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
        previous?.webView.hidden = true
        selected?.webView.hidden = false
        
        previous?.webView.navigationDelegate = nil
        selected?.webView.navigationDelegate = self
        toolbar.updateURL(selected?.url?)
    }

    func didAddTab(tab: Browser) {
        toolbar.updateTabCount(tabManager.count)

        tab.webView.hidden = true
        view.addSubview(tab.webView)
        tab.webView.snp_makeConstraints { make in
            make.top.equalTo(self.toolbar.snp_bottom)
            make.leading.trailing.bottom.equalTo(self.view)
        }
        tab.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.mozilla.org")!))
    }

    func didRemoveTab(tab: Browser) {
        toolbar.updateTabCount(tabManager.count)

        tab.webView.removeFromSuperview()
    }
    
    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        toolbar.updateURL(webView.URL);
    }
}