// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
@testable import Client

final class MockContentBlockerTab: ContentBlockerTab {
    var isPrivate = false
    var hasUncommittedNavigation = false
    var reloadCalled = 0
    var onReload: (() -> Void)?

    func currentURL() -> URL? { return nil }
    func currentWebView() -> WKWebView? { return nil }
    func imageContentBlockingEnabled() -> Bool { return false }

    func reload(bypassCache: Bool) {
        reloadCalled += 1
        onReload?()
    }
}
