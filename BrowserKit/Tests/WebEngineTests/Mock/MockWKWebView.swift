// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

/// Used in some tests cases instead of `MockWKEngineWebView` since some delegate methods need a concrete `WKWebView` object
/// and an abstraction cannot be used.
class MockWKWebView: WKWebView {
    var mockURL: URL?
    var loadCalled = 0
    var reloadCalled = 0

    override var url: URL? {
        return mockURL
    }

    override func load(_ request: URLRequest) -> WKNavigation? {
        loadCalled += 1
        mockURL = request.url
        return nil
    }

    override func reload() -> WKNavigation? {
        reloadCalled += 1
        return nil
    }
}
