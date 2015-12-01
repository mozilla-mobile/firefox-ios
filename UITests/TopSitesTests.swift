/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class TopSitesTests: KIFTestCase {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    func createNewTab(){
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Add Tab")
        tester().waitForViewWithAccessibilityLabel("Search or enter address")
    }

    func openURLForPageNumber(pageNo: Int) {
        let url = "\(webRoot)/numberedPage.html?page=\(pageNo)"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page \(pageNo)")
    }

    func rotateToLandscape() {
        // Rotate to landscape.
        let value = UIInterfaceOrientation.LandscapeLeft.rawValue
        UIDevice.currentDevice().setValue(value, forKey: "orientation")
    }

    func rotateToPortrait() {
        // Rotate to landscape.
        let value = UIInterfaceOrientation.Portrait.rawValue
        UIDevice.currentDevice().setValue(value, forKey: "orientation")
    }

    // A bit internal :/
    func extractTextSizeFromThumbnail(thumbnail: UIView) -> CGFloat? {
        guard let contentView = thumbnail.subviews.first, let wrapper = contentView.subviews.first,
            let textWrapper = wrapper.subviews.last, let label = textWrapper.subviews.first as? UILabel else { return nil }

        return label.font.pointSize
    }

    func testRotatingOnTopSites() {
        // go to top sites. rotate to landscape, rotate back again. ensure it doesn't crash
        createNewTab()
        rotateToLandscape()
        rotateToPortrait()

        // go to top sites. rotate to landscape, switch to another tab, switch back to top sites, ensure it doesn't crash
        rotateToLandscape()
        tester().tapViewWithAccessibilityLabel("History")
        tester().tapViewWithAccessibilityLabel("Top sites")
        rotateToPortrait()

        // go to web page. rotate to landscape. click URL Bar, rotate to portrait. ensure it doesn't crash.
        openURLForPageNumber(1)
        rotateToLandscape()
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().waitForViewWithAccessibilityLabel("Top sites")
        rotateToPortrait()
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func testChangingDyamicFontOnTopSites() {
        DynamicFontUtils.restoreDynamicFontSize(tester())

        createNewTab()
        let thumbnail = tester().waitForViewWithAccessibilityLabel("The Mozilla Project")

        let size = extractTextSizeFromThumbnail(thumbnail)

        DynamicFontUtils.bumpDynamicFontSize(tester())
        let bigSize = extractTextSizeFromThumbnail(thumbnail)

        DynamicFontUtils.lowerDynamicFontSize(tester())
        let smallSize = extractTextSizeFromThumbnail(thumbnail)

        XCTAssertGreaterThan(bigSize!, size!)
        XCTAssertGreaterThanOrEqual(size!, smallSize!)

        openURLForPageNumber(1) // Needed for the teardown
    }

    func testRemovingSite() {
        // Load a page
        tester().tapViewWithAccessibilityIdentifier("url")
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Open top sites
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityLabel("Top sites")

        // Verify the row exists and that the Remove Page button is hidden
        let row = tester().waitForViewWithAccessibilityLabel("127.0.0.1")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Remove page")

        // Long press the row and click the remove button
        row.longPressAtPoint(CGPointZero, duration: 1)
        tester().tapViewWithAccessibilityLabel("Remove page")

        // Close editing mode
        tester().tapViewWithAccessibilityLabel("Done")

        // Close top sites
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    override func tearDown() {
        DynamicFontUtils.restoreDynamicFontSize(tester())
        BrowserUtils.resetToAboutHome(tester())
    }
}
