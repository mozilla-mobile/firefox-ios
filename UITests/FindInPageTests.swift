/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class FindInPageTests: KIFTestCase {
    fileprivate static let LongPressDuration: TimeInterval = 2
    
    fileprivate var webRoot: String!
    
    override func setUp() {
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }
    
    override func tearDown() {
        super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
    
    // The WkWebView accepts first long press, then becomes non-responsive afterwards, failing at the
    // second openFindInPageBar(webView) call
    func testFindFromSelection() {
        let testURL = "\(webRoot)/findPage.html"
        
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(testURL)\n")
        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        tester().waitForWebViewElementWithAccessibilityLabel("nullam")
        
        // Ensure the find-in-page bar is visible by looking at views.
        openFindInPageBar(webView)
        XCTAssertTrue(tester().viewExistsWithLabel("Done"))
        XCTAssertTrue(tester().viewExistsWithLabel("Next in-page result"))
        XCTAssertTrue(tester().viewExistsWithLabel("Previous in-page result"))
        
        // Test previous/next buttons.
        try! tester().tryFindingView(withAccessibilityLabel: "1/4")
        clickFindNext()
        try! tester().tryFindingView(withAccessibilityLabel: "2/4")
        clickFindNext()
        try! tester().tryFindingView(withAccessibilityLabel: "3/4")
        clickFindNext()
        try! tester().tryFindingView(withAccessibilityLabel: "4/4")
        clickFindNext()
        try! tester().tryFindingView(withAccessibilityLabel: "1/4")
        clickFindPrevious()
        try! tester().tryFindingView(withAccessibilityLabel: "4/4")
        clickFindPrevious()
        try! tester().tryFindingView(withAccessibilityLabel: "3/4")
        clickFindPrevious()
        try! tester().tryFindingView(withAccessibilityLabel: "2/4")
        clickFindPrevious()
        try! tester().tryFindingView(withAccessibilityLabel: "1/4")
        
        // Test a query with no matches.
        let findTextField = tester().waitForViewWithAccessibilityValue("nullam") as! UITextField
        findTextField.becomeFirstResponder()
        tester().enterText(intoCurrentFirstResponder: "z")
        let resultsView = tester().waitForView(withAccessibilityLabel: "0/0")
        XCTAssertFalse((resultsView?.isHidden)!)
        tester().clearTextFromFirstResponder()
        XCTAssertTrue((resultsView?.isHidden)!)
        
        // Make sure the selection menu still works with the bar already visible.
        openFindInPageBar(webView)
        try! tester().tryFindingView(withAccessibilityLabel: "1/4")
        
        // Make sure the bar disappears when reloading.
        tester().tapView(withAccessibilityLabel: "Reload")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "nullam")
        
        // Make sure the bar disappears when opening the tabs tray.
        openFindInPageBar(webView)
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Find Page")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "nullam")
        
        // Test that Done dismisses the toolbar.
        openFindInPageBar(webView)
        tester().tapView(withAccessibilityLabel: "Done")
        XCTAssertFalse(tester().viewExistsWithLabel("Done"))
        XCTAssertFalse(tester().viewExistsWithLabel("Next in-page result"))
        XCTAssertFalse(tester().viewExistsWithLabel("Previous in-page result"))
    }
    
    fileprivate func openFindInPageBar(_ webView: WKWebView) {
        // For some reason, we sometimes have to tap the web view to make
        // it respond to long press events (tests only).
        webView.tap(at: CGPoint.zero)

        // Make the selection menu appear. To keep things simple, the page has absolutely
        // positioned text at the top-left corner.
        webView.longPress(at: CGPoint.zero, duration: FindInPageTests.LongPressDuration)

        tester().tapView(withAccessibilityLabel: "Find in Page")
        tester().waitForViewWithAccessibilityValue("nullam")
    }
    
    fileprivate func clickFindNext() {
        tester().tapView(withAccessibilityLabel: "Next in-page result")
    }
    
    fileprivate func clickFindPrevious() {
        tester().tapView(withAccessibilityLabel: "Previous in-page result")
    }
    
    func testOpenFindInPageFromMenu() {
        let testURL = "\(webRoot)/findPage.html"
        
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(testURL)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("nullam")
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Find In Page")
        XCTAssertTrue(tester().viewExistsWithLabel("Done"))
        tester().tapView(withAccessibilityLabel: "Done")
    }
}
