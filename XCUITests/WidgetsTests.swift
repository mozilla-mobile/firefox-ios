/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class WidgetTests: BaseTestCase {
    func testSearchWidgets() {
        // Set a url in the pasteboard
        UIPasteboard.general.string = "www.example.com"

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        // Open the app and set it to background
        app.activate()
        navigator.openURL("www.mozilla.org")
        sleep(1)
        XCUIDevice.shared.press(.home)

        // Swipe Right to go to Widgets view
        let window = springboard.children(matching: .window).element(boundBy: 0)
        window.swipeRight()
        window.swipeRight()

        // Swipe Up to get to the Edit and Add Widget buttons
        // This line is needed the first time widgets view is open
        springboard.alerts.firstMatch.scrollViews.otherElements.buttons.element(boundBy: 0).tap()

        let element = springboard/*@START_MENU_TOKEN@*/.scrollViews["left-of-home-scroll-view"]/*[[".otherElements[\"Home screen icons\"].scrollViews[\"left-of-home-scroll-view\"]",".scrollViews[\"left-of-home-scroll-view\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
        element.swipeUp()
        element.swipeUp()
        element.swipeUp()
//        springboard/*@START_MENU_TOKEN@*/.scrollViews["left-of-home-scroll-view"].otherElements.buttons["Edit"]/*[[".otherElements[\"Home screen icons\"].scrollViews[\"left-of-home-scroll-view\"].otherElements",".otherElements[\"WGMajorListViewControllerView\"].buttons[\"Edit\"]",".buttons[\"Edit\"]",".scrollViews[\"left-of-home-scroll-view\"].otherElements"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/
        springboard.scrollViews["left-of-home-scroll-view"].otherElements.buttons.firstMatch.tap()
        
        
        sleep(3)
    //7 app/*@START_MENU_TOKEN@*/.buttons["Añadir widget"]/*[[".otherElements[\"Home screen icons\"].buttons[\"Añadir widget\"]",".buttons[\"Añadir widget\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        springboard.otherElements["Home screen icons"].buttons.firstMatch.tap()
        
//        springboard.otherElements["Home screen icons"].buttons.firstMatch.tap()
        
        // Select Fennec (username)
        springboard.collectionViews.cells.element(boundBy: 4).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.tap()
//        springboard/*@START_MENU_TOKEN@*/.buttons[" Add Widget"].staticTexts[" Add Widget"]/*[[".buttons[\" Add Widget\"].staticTexts[\" Add Widget\"]",".staticTexts[\" Add Widget\"]"],[[[-1,1],[-1,0]]],[1]]@END_MENU_TOKEN@*/.tap()
        
        springboard.buttons.staticTexts.firstMatch.tap()

        // Dismiss the edit mode
        element.tap()

        // Wait for the Search in Firefox widget and tap on it
        print(springboard.debugDescription)
        waitForExistence(springboard.scrollViews.buttons["Search in\nFirefox"], timeout: 3)
        
        
        springboard.scrollViews.buttons["Search in\nFirefox"].tap()

        
        // Verify that the app is open in the corresponding view
        waitForExistence(app.collectionViews.cells["TopSitesCell"], timeout: 5)
        // Verify that < and QR buttons are shown that indicates the url is focused
        waitForExistence(app.buttons["urlBar-cancel"], timeout: 5)
        XCTAssertTrue(app.buttons["urlBar-cancel"].exists)

        // Set the app in Background to go and add the second widget
        XCUIDevice.shared.press(.home)
        window.swipeRight()
        window.swipeRight()

        springboard/*@START_MENU_TOKEN@*/.scrollViews["left-of-home-scroll-view"].otherElements.buttons["Edit"]/*[[".otherElements[\"Home screen icons\"].scrollViews[\"left-of-home-scroll-view\"].otherElements",".otherElements[\"WGMajorListViewControllerView\"].buttons[\"Edit\"]",".buttons[\"Edit\"]",".scrollViews[\"left-of-home-scroll-view\"].otherElements"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.tap()
        springboard/*@START_MENU_TOKEN@*/.buttons["Add Widget"]/*[[".otherElements[\"Home screen icons\"].buttons[\"Add Widget\"]",".buttons[\"Add Widget\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        springboard.collectionViews.cells.element(boundBy: 2).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element.swipeLeft()

        // Scroll to she second screen to select the other widget
        springboard.pageIndicators["page 1 of 2"].tap()
        springboard/*@START_MENU_TOKEN@*/.staticTexts[" Add Widget"]/*[[".buttons[\" Add Widget\"].staticTexts[\" Add Widget\"]",".staticTexts[\" Add Widget\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()

        // Dismiss the edit mode
        element.tap()

        // Wait for the Search in Firefox widget and tap on it
        waitForExistence(springboard.scrollViews.buttons["Go to\nCopied Link"], timeout: 3)
        // Verify that all buttons are shown
        XCTAssertTrue(springboard.scrollViews.buttons["Go to\nCopied Link"].exists)
        XCTAssertTrue(springboard.scrollViews.buttons["Close\nPrivate Tabs"].exists)
        XCTAssertTrue(springboard.scrollViews.buttons["Search in\nPrivate Tab"].exists)

        UIPasteboard.general.string = "www.example.com"
        // Tap on an option different than the first one
        springboard.scrollViews.buttons["Go to\nCopied Link"].tap()

        // Verify that the app is open in the corresponding view
        waitForExistence(app.links["More information..."])
        
        
        
        
//        let app = XCUIApplication()
//        let window = app.children(matching: .window).element(boundBy: 0)
//        window.swipeRight()
//        window.swipeRight()
//        window.swipeRight()
//        app.children(matching: .window).element(boundBy: 2).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.swipeUp()
//        app/*@START_MENU_TOKEN@*/.scrollViews["left-of-home-scroll-view"]/*[[".otherElements[\"Home screen icons\"].scrollViews[\"left-of-home-scroll-view\"]",".scrollViews[\"left-of-home-scroll-view\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.children(matching: .other).element.children(matching: .other).element(boundBy: 0).swipeUp()
//        app/*@START_MENU_TOKEN@*/.scrollViews["left-of-home-scroll-view"].otherElements.buttons["Editar"]/*[[".otherElements[\"Home screen icons\"].scrollViews[\"left-of-home-scroll-view\"].otherElements",".otherElements[\"WGMajorListViewControllerView\"].buttons[\"Editar\"]",".buttons[\"Editar\"]",".scrollViews[\"left-of-home-scroll-view\"].otherElements"],[[[-1,3,1],[-1,0,1]],[[-1,2],[-1,1]]],[0,0]]@END_MENU_TOKEN@*/.tap()
//        app/*@START_MENU_TOKEN@*/.buttons["Añadir widget"]/*[[".otherElements[\"Home screen icons\"].buttons[\"Añadir widget\"]",".buttons[\"Añadir widget\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
///
        
    }
}
