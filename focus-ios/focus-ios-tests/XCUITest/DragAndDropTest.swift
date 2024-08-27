/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class DragAndDropTest: BaseTestCase {
    let websiteWithSearchField = ["url": "https://developer.mozilla.org/en-US/", "urlSearchField": "Search MDN"]

    // https://mozilla.testrail.io/index.php?/cases/view/2609718
    func testDragElement() {
        let urlBarTextField = app.textFields["URLBar.urlText"]
        loadWebPage(websiteWithSearchField["url"]!)
        waitForWebPageLoad()

        // Check the text in the search field before dragging and dropping the url text field
        if #unavailable(iOS 17) {
            waitForExistence(app.webViews.otherElements[websiteWithSearchField["urlSearchField"]!])
            urlBarTextField.firstMatch.press(forDuration: 1, thenDragTo: app.webViews.otherElements["search"].firstMatch)
        } else {
            waitForExistence(app.webViews.textFields[websiteWithSearchField["urlSearchField"]!])
            // DragAndDrop the url for only one second so that the TP menu is not shown and the search box is not covered
            urlBarTextField.firstMatch.press(forDuration: 1, thenDragTo: app.webViews.otherElements["search"].firstMatch)
            // Verify that the text in the search field is the same as the text in the url text field
            waitForValueContains(app.webViews.textFields[websiteWithSearchField["urlSearchField"]!].firstMatch, value: websiteWithSearchField["url"]!)
        }
    }
}
