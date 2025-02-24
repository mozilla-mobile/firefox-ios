// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import WebKit

class MockTabWebView: TabWebView {
    var loadCalled = 0
    var loadedRequest: URLRequest?
    var goBackCalled = 0
    var goForwardCalled = 0
    var reloadFromOriginCalled = 0
    var stopLoadingCalled = 0
    var loadedURL: URL?
    override var url: URL? {
        return loadedURL
    }

    override func load(_ request: URLRequest) -> WKNavigation? {
        loadCalled += 1
        loadedRequest = request
        loadedURL = request.url
        return nil
    }

    override func reloadFromOrigin() -> WKNavigation? {
        reloadFromOriginCalled += 1
        return nil
    }

    override func goBack() -> WKNavigation? {
        goBackCalled += 1
        return nil
    }

    override func goForward() -> WKNavigation? {
        goForwardCalled += 1
        return nil
    }

    override func stopLoading() {
        stopLoadingCalled += 1
    }
}
