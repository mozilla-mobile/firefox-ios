// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit

class MockWebView: WKWebView {
    var overridenURL: URL

    init(_ url: URL) {
        self.overridenURL = url
        super.init(frame: .zero, configuration: WKWebViewConfiguration())
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override var url: URL {
        return overridenURL
    }
}
