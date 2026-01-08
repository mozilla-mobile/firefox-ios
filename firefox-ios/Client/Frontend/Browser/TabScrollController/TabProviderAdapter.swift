// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

@MainActor
protocol TabProviderProtocol: AnyObject {
    var scrollView: UIScrollView? { get }
    var isFxHomeTab: Bool { get }
    var isFindInPageMode: Bool { get }
    var isLoading: Bool { get }
    // Pull to refresh related
    var onLoadingStateChanged: (@MainActor () -> Void)? { get set }
    func removePullToRefresh()
    func addPullToRefresh(onReload: @escaping () -> Void)
    func reloadPage()
}

final class TabProviderAdapter: TabProviderProtocol {
    private unowned let tab: Tab

    init(_ tab: Tab) {
        self.tab = tab
    }

    var isFxHomeTab: Bool { tab.isFxHomeTab }
    var isFindInPageMode: Bool { tab.isFindInPageMode }
    var isLoading: Bool { tab.isLoading }
    var scrollView: UIScrollView? { tab.webView?.scrollView }

    var onLoadingStateChanged: (@MainActor () -> Void)? {
        get { tab.onWebViewLoadingStateChanged }
        set { tab.onWebViewLoadingStateChanged = newValue }
    }

    func addPullToRefresh(onReload: @escaping () -> Void) {
        tab.webView?.addPullRefresh(onReload: onReload)
    }

    func removePullToRefresh() {
        tab.webView?.removePullRefresh()
    }

    func reloadPage() {
        tab.reloadPage()
    }
}
