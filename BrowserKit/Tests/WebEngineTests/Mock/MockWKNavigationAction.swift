// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

class MockWKNavigationAction: WKNavigationAction {
    private let _url: URL

    override var request: URLRequest {
        return URLRequest(url: _url)
    }

    init(url: URL) {
        _url = url
        super.init()
    }
}
