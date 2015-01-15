/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import WebKit

private let StatusBarHeight: CGFloat = 20 // TODO: Can't assume this is correct. Status bar height is dynamic.
private let ToolbarHeight: CGFloat = 44

class BrowserViewController: UIViewController {
    private var toolbar: BrowserToolbar!
    private let tabManager = TabManager()
    private let navigationView = BrowserNotification()

    override func viewDidLoad() {
        let headerView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.ExtraLight))
        view.addSubview(headerView);
        
        headerView.snp_makeConstraints { make in
            make.top.equalTo(self.view.snp_top)
            make.height.equalTo(ToolbarHeight + StatusBarHeight)
            make.leading.trailing.equalTo(self.view)
        }
        
        toolbar = BrowserToolbar()
        toolbar.backgroundColor = UIColor.clearColor()
        headerView.addSubview(toolbar)

        toolbar.snp_makeConstraints { make in
            make.top.equalTo(headerView.snp_top)
            make.left.equalTo(headerView.snp_left)
            make.bottom.equalTo(headerView.snp_bottom)
            make.right.equalTo(headerView.snp_right)
        }

        self.view.addSubview(navigationView)
        
        navigationView.snp_remakeConstraints { make in
            let myView = self.view!
            make.left.equalTo(myView)
            make.top.equalTo(self.toolbar.snp_bottom)
            make.width.equalTo(myView)
            make.height.equalTo(myView).offset(self.toolbar.bounds.size.height)
        }

        toolbar.browserToolbarDelegate = self
        tabManager.delegate = self

        tabManager.addTab()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationView.hideNotification()
    }
}

extension BrowserViewController: BrowserToolbarDelegate {
    func didBeginEditing() {
        let profile = MockAccountProfile()
        let controller = TabBarViewController()
        controller.profile = profile
        controller.delegate = self
        controller.url = tabManager.selectedTab?.url
        controller.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
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
}

extension BrowserViewController: TabBarViewControllerDelegate {
    func didEnterURL(url: NSURL) {
        toolbar.updateURL(url)
        tabManager.selectedTab?.loadRequest(NSURLRequest(URL: url))
    }
}

extension BrowserViewController: TabManagerDelegate {
    func didSelectedTabChange(selected: Browser?, previous: Browser?) {
        previous?.webView.hidden = true
        selected?.webView.hidden = false

        previous?.webView.navigationDelegate = nil
        selected?.webView.navigationDelegate = self
        toolbar.updateURL(selected?.url)
        toolbar.updateProgressBar(0.0)
        if let selected = selected {
            toolbar.updateBackStatus(selected.canGoBack)
            toolbar.updateFowardStatus(selected.canGoForward)
        }
    }

    func didAddTab(tab: Browser) {
        toolbar.updateTabCount(tabManager.count)

        tab.webView.hidden = true
        view.insertSubview(tab.webView, atIndex: 0)
        tab.webView.scrollView.contentInset = UIEdgeInsetsMake(ToolbarHeight + StatusBarHeight, 0, 0, 0)
        tab.webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(ToolbarHeight + StatusBarHeight, 0, 0, 0)
        tab.webView.snp_makeConstraints { make in
            make.top.equalTo(self.view.snp_top)
            make.leading.trailing.bottom.equalTo(self.view)
        }
        tab.webView.addObserver(self, forKeyPath: "estimatedProgress", options: .New, context: nil)
        tab.loadRequest(NSURLRequest(URL: NSURL(string: "http://www.mozilla.org")!))
    }

    func didRemoveTab(tab: Browser) {
        toolbar.updateTabCount(tabManager.count)

        tab.webView.removeObserver(self, forKeyPath: "estimatedProgress")
        tab.webView.removeFromSuperview()
    }
}

extension BrowserViewController: WKNavigationDelegate {

    func webView(webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    }

    func webView(webView: WKWebView, didCommitNavigation navigation: WKNavigation!) {
        toolbar.updateURL(webView.URL);
        toolbar.updateBackStatus(webView.canGoBack)
        toolbar.updateFowardStatus(webView.canGoForward)
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        webView.stopLoading()
        navigationView.notification(error)
    }

    func webView(webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: NSError) {
        webView.stopLoading()
        navigationView.notification(error)
    }

    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
    }

    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
    }

    func webView(webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object:
        AnyObject, change:[NSObject: AnyObject], context:
        UnsafeMutablePointer<Void>) {
            if keyPath == "estimatedProgress" && object as? WKWebView == tabManager.selectedTab?.webView {
                if let progress = change[NSKeyValueChangeNewKey] as Float? {
                    toolbar.updateProgressBar(progress)
                }
            }
    }
}