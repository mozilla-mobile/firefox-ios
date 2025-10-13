// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol PDFSelectorsSet {
    var WEB_VIEW: Selector { get }
    func linkInWebView(atIndex index: Int) -> Selector
    var all: [Selector] { get }
}

struct PDFSelectors: PDFSelectorsSet {
    let WEB_VIEW = Selector.webView(
        description: "The main web view for displaying the PDF",
        groups: ["pdf"]
    )

    func linkInWebView(atIndex index: Int) -> Selector {
        return Selector.link(
            description: "A link within the PDF web view at index \(index)",
            groups: ["pdf"]
        )
    }

    var all: [Selector] {
        return [WEB_VIEW]
    }
}
