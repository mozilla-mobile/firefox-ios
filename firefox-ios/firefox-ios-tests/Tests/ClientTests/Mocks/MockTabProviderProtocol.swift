// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest
@testable import Client

@MainActor
final class MockTabProviderProtocol: TabProviderProtocol {
    var isFxHomeTab = false
    var isFindInPageMode = false
    var isLoading = false

    var onLoadingStateChanged: (@MainActor () -> Void)?

    var scrollView: UIScrollView?
    var pullToRefreshAddCount = 0
    var pullToRefreshRemoveCount = 0

    init(_ tab: Tab) {
        self.scrollView = tab.webView?.scrollView
    }

    func addPullToRefresh(onReload: @escaping () -> Void) {
        pullToRefreshAddCount += 1
    }
    func removePullToRefresh() {
        pullToRefreshRemoveCount += 1
    }

    func reloadPage() {}
}
