// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class PDFScreen {
    private let app: XCUIApplication
    private let sel: PDFSelectorsSet

    init(app: XCUIApplication, selectors: PDFSelectorsSet = PDFSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var webView: XCUIElement {
        return sel.WEB_VIEW.element(in: app)
    }

    func tapOnLinkInPdf(atIndex index: Int) {
        let allLinks = webView.links

        // Wait for at least one link to exist before trying to access the index
        BaseTestCase().mozWaitForElementToExist(allLinks.firstMatch)

        // Access the specific link by its index from the query
        let linkElement = allLinks.element(boundBy: index)

        BaseTestCase().mozWaitForElementToExist(linkElement)
        linkElement.tapOnApp()
    }
}
