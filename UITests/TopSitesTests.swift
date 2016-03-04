/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
@testable import Storage
@testable import Client

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
        let thumbnail = tester().waitForViewWithAccessibilityLabel("Facebook")

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

    func testRotationAndDeleteShowsCorrectTile() {
        // Load in the top Alexa sites to populate some top site tiles with
        let topDomainsPath = NSBundle.mainBundle().pathForResource("topdomains", ofType: "txt")!
        let data = try! NSString(contentsOfFile: topDomainsPath, encoding: NSUTF8StringEncoding)
        let topDomains = data.componentsSeparatedByString("\n")
        var collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        let thumbnailCount = (collection.collectionViewLayout as! TopSitesLayout).thumbnailCount

        // Navigate to enough sites to fill top sites plus a couple of more
        (0..<thumbnailCount + 3).forEach { index in
            let site = topDomains[index]
            tester().tapViewWithAccessibilityIdentifier("url")
            tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(site)\n")
        }

        tester().waitForTimeInterval(2)

        // Open top sites
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().swipeViewWithAccessibilityIdentifier("Top Sites View", inDirection: .Down)
        tester().waitForAnimationsToFinish()

        // Rotate
        system().simulateDeviceRotationToOrientation(.LandscapeLeft)
        tester().waitForAnimationsToFinish()

        // Delete
        collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        let firstCell = collection.visibleCells().first!
        firstCell.longPressAtPoint(CGPointZero, duration: 3)
        tester().tapViewWithAccessibilityLabel("Remove page")

        // Rotate
        system().simulateDeviceRotationToOrientation(.Portrait)
        tester().waitForAnimationsToFinish()

        // Get last cell after rotation
        let lastCell = collection.visibleCells().last!

        // Verify that the last cell is not a default tile
        DefaultSuggestedSites.sites["default"]!.forEach { site in
            XCTAssertFalse(lastCell.accessibilityLabel == site.title)
        }

        // Close top sites
        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func testRemovingSuggestedSites() {
        // Delete the first three suggested tiles from top sites
        let collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        let firstCell = collection.visibleCells().first!
        firstCell.longPressAtPoint(CGPointZero, duration: 3)
        tester().tapViewWithAccessibilityLabel("Remove page")
        tester().waitForAnimationsToFinish()

        tester().tapViewWithAccessibilityLabel("Remove page")
        tester().waitForAnimationsToFinish()

        tester().tapViewWithAccessibilityLabel("Remove page")
        tester().waitForAnimationsToFinish()

        // Close editing mode
        tester().tapViewWithAccessibilityLabel("Done")

        // Open new tab to check if changes persisted
        createNewTab()

        // Check that there are two suggested tiles left
        XCTAssertTrue(collection.visibleCells().count == 2)

        // Close extra tab and prepare for tear down
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        let tabsView = tester().waitForViewWithAccessibilityLabel("Tabs Tray").subviews.first as! UICollectionView
        let cell = tabsView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0))!
        tester().swipeViewWithAccessibilityLabel(cell.accessibilityLabel, inDirection: KIFSwipeDirection.Left)
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("home")
    }

    override func tearDown() {
        DynamicFontUtils.restoreDynamicFontSize(tester())
        BrowserUtils.resetToAboutHome(tester())
    }
}
