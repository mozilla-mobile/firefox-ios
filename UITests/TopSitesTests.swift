/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
@testable import Storage
@testable import Client

// This test is only for devices that does not have Panel implementation (e.g. iPad):
// https://github.com/mozilla-mobile/firefox-ios/blob/master/Client/Frontend/Home/HomePanels.swift#L23
// When running on iPhone, this test will fail, because the Collectionview does not have an identifier, and 
// the deletion method is different
class TopSitesTests: KIFTestCase {
    fileprivate var webRoot: String!
    fileprivate var profile: Profile!

    override func setUp() {
        profile = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!
        profile.prefs.setObject([], forKey: "topSites.deletedSuggestedSites")
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    fileprivate func extractTextSizeFromThumbnail(_ thumbnail: ThumbnailCell) -> CGFloat? {
        return thumbnail.textLabel.font.pointSize
    }

    fileprivate func accessibilityLabelsForAllTopSites(_ collection: UICollectionView) -> [String] {
        return collection.visibleCells.reduce([], { arr, cell in
            if let label = cell.accessibilityLabel {
                return arr + [label]
            }
            return arr
        })
    }

/*
    func testChangingDyamicFontOnTopSites() {
        DynamicFontUtils.restoreDynamicFontSize(tester())

        let collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        let thumbnail = collection.visibleCells().first as! ThumbnailCell

        let size = extractTextSizeFromThumbnail(thumbnail)

        DynamicFontUtils.bumpDynamicFontSize(tester())
        let bigSize = extractTextSizeFromThumbnail(thumbnail)

        DynamicFontUtils.lowerDynamicFontSize(tester())
        let smallSize = extractTextSizeFromThumbnail(thumbnail)

        XCTAssertGreaterThan(bigSize!, size!)
        XCTAssertGreaterThanOrEqual(size!, smallSize!)
    }
*/
    func testRemovingSite() {
        // Switch to the Bookmarks panel so we can later reload Top Sites.
        tester().tapView(withAccessibilityLabel: "Bookmarks")

        // Load a set of dummy domains.
        for i in 1...10 {
            BrowserUtils.addHistoryEntry("", url: URL(string: "https://test\(i).com")!)
        }

        // Switch back to the Top Sites panel.
        tester().tapView(withAccessibilityLabel: "Top sites")

        // Remove the first site and verify that all other sites shift to replace it.
        let collection = tester().waitForView(withAccessibilityIdentifier: "Top Sites View") as! UICollectionView

        // Get the first cell (test10.com).
        let cell = collection.cellForItem(at: IndexPath(item: 0, section: 0))!

        let cellToDeleteLabel = cell.accessibilityLabel
        tester().longPressView(withAccessibilityLabel: cellToDeleteLabel, duration: 1)
        tester().waitForView(withAccessibilityLabel: "Remove page - \(cellToDeleteLabel!)")
        cell.tap(at: CGPoint.zero)

        // Close editing mode.
        tester().tapView(withAccessibilityLabel: "Done")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Remove page")

        let postDeletedLabels = accessibilityLabelsForAllTopSites(collection)
        XCTAssertFalse(postDeletedLabels.contains(cellToDeleteLabel!))
    }

    func testRemovingSuggestedSites() {
        // Switch to the Bookmarks panel so we can later reload Top Sites.
        tester().tapView(withAccessibilityLabel: "Bookmarks")
        tester().tapView(withAccessibilityLabel: "Top sites")

        var collection = tester().waitForView(withAccessibilityIdentifier: "Top Sites View") as! UICollectionView
        let firstCell = collection.cellForItem(at: IndexPath(item: 0, section: 0))!
        let cellToDeleteLabel = firstCell.accessibilityLabel
        tester().longPressView(withAccessibilityLabel: cellToDeleteLabel, duration: 1)
        tester().tapView(withAccessibilityLabel: "Remove page - \(cellToDeleteLabel!)")
        tester().waitForAnimationsToFinish()

        // Close editing mode
        tester().tapView(withAccessibilityLabel: "Done")

        // Verify that the tile we removed is removed

        collection = tester().waitForView(withAccessibilityIdentifier: "Top Sites View") as! UICollectionView
        XCTAssertFalse(accessibilityLabelsForAllTopSites(collection).contains(cellToDeleteLabel!))
    }

  // Disabled since deleted sites reappear during automation.  Manually this is not reproducible.  Seems to be the KIFTest update issue
    /*
    func testEmptyState() {
        // Delete all of the suggested tiles
        var collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        while collection.visibleCells().count > 0 {
            let firstCell = collection.visibleCells().first!
            firstCell.longPressAtPoint(CGPointZero, duration: 3)
            tester().tapViewWithAccessibilityLabel("Remove page - \(firstCell.accessibilityLabel!)")
            tester().waitForAnimationsToFinish()
        }

        // Close editing mode
        tester().tapViewWithAccessibilityLabel("Done")

        // Check for empty state
        XCTAssertTrue(tester().viewExistsWithLabel("Welcome to Top Sites"))

        // Add a new history item

        // Verify that empty state no longer appears
        //BrowserUtils.addHistoryEntry("", url: NSURL(string: "https://mozilla.org")!)

        tester().tapViewWithAccessibilityLabel("Bookmarks")
        tester().tapViewWithAccessibilityLabel("Top sites")
        tester().waitForAnimationsToFinish()

        collection = tester().waitForViewWithAccessibilityIdentifier("Top Sites View") as! UICollectionView
        // 4 default topsites are re-populated
        XCTAssertEqual(collection.visibleCells().count, 1)
        XCTAssertFalse(tester().viewExistsWithLabel("Welcome to Top Sites"))
    }
*/
    override func tearDown() {
        //DynamicFontUtils.restoreDynamicFontSize(tester())
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
}
