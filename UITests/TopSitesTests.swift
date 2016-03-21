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
        // Switch to the Bookmarks panel so we can later reload Top Sites.
        tester().tapViewWithAccessibilityLabel("Bookmarks")

        // Load a set of dummy domains.
        for i in 1...10 {
            BrowserUtils.addHistoryEntry("", url: NSURL(string: "https://test\(i).com")!)
        }

        // Switch back to the Top Sites panel.
        tester().tapViewWithAccessibilityLabel("Top sites")

        // Remove the first site and verify that all other sites shift to replace it.
        let collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView

        // Ensure that the last sites added are the first in the view. We don't know exactly
        // how many thumbnails are visible since that's device-specific, but we can check a few.
        verifyTopSites(collection, range: 5...10)

        // Get the first cell (test10.com).
        let cell = collection.visibleCells().first!

        // Each thumbnail will have a remove button with the "Remove site" accessibility label, so
        // we can't uniquely identify which remove button we want. Instead, just verify that "Remove site"
        // labels are visible, and click the thumbnail at the top left (where the remove button is).
        cell.longPressAtPoint(CGPointZero, duration: 1)
        tester().waitForViewWithAccessibilityLabel("Remove page")
        cell.tapAtPoint(CGPointZero)

        // test9.com should now be first, followed by test8.com, etc.
        verifyTopSites(collection, range: 4...9)

        // Simulate loading a page in the background.
        BrowserUtils.addHistoryEntry("", url: NSURL(string: "https://test99.com")!)

        // Close editing mode.
        tester().tapViewWithAccessibilityLabel("Done")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Remove page")

        // Remove our dummy sites.
        // TODO: This is painfully slow...let's find a better way to reset (bug 1191476).
        BrowserUtils.clearHistoryItems(tester())
    }

    private func verifyTopSites(collection: UICollectionView, range: Range<Int>) {
        var item = 0
        for i in range.reverse() {
            let expected = tester().waitForViewWithAccessibilityLabel("test\(i).com") as! UICollectionViewCell
            let cell = collection.cellForItemAtIndexPath(NSIndexPath(forItem: item, inSection: 0))
            XCTAssertEqual(cell, expected)
            item++
        }
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
