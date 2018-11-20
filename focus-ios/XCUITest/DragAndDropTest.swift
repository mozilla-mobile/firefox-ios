//
//  DragAndDropTest.swift
//  XCUITest
//
//  Created by Sawyer Blatz on 6/18/18.
//  Copyright © 2018 Mozilla. All rights reserved.
//

import XCTest

class DragAndDropTest: BaseTestCase {
    let websiteWithSearchField = ["url": "https://developer.mozilla.org/en-US/search", "urlSearchField": "Search the docs"]

    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func testDragElement() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            let urlBarTextField = app.textFields["URLBar.urlText"]
            loadWebPage("developer.mozilla.org/en-US/search")

            // Check the text in the search field before dragging and dropping the url text field
            XCTAssertEqual(app.webViews.searchFields[websiteWithSearchField["urlSearchField"]!].placeholderValue, "Search the docs")
            // DragAndDrop the url for only one second so that the TP menu is not shown and the search box is not covered
            urlBarTextField.press(forDuration: 1, thenDragTo: app.webViews.searchFields[websiteWithSearchField["urlSearchField"]!])
            // Verify that the text in the search field is the same as the text in the url text field
            XCTAssertEqual(app.webViews.searchFields[websiteWithSearchField["urlSearchField"]!].value as? String, websiteWithSearchField["url"]!)
        }
    }
}
