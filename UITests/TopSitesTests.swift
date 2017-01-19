/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import EarlGrey
@testable import Storage
@testable import Client

class TopSitesTests: KIFTestCase {
    private var profile: Profile!

    override func setUp() {
        
        profile = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!
		BrowserUtils.dismissFirstRunUI()
    }

    func test_RemovingSite() {
        // Populate history (Each page has 6 sites listed)
        for i in 1...6 {
            BrowserUtils.addHistoryEntry("", url: NSURL(string: "https://test\(i).com")!)
        }
        // Switch to the Bookmarks panel and back so we can later reload Top Sites.
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Bookmarks")).performAction(grey_tap())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Top sites")).performAction(grey_tap())
        
        // Remove the first site and verify that all other sites shift to replace it.
        // Get the first cell.
        deleteHistoryTopsite()
        
        // clear rest of the history
		deleteHistoryTopsite(5)
    }

    func test_RemovingSuggestedSites() {
        // Switch to the Bookmarks panel and back so we can later reload Top Sites.
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Bookmarks")).performAction(grey_tap())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Top sites")).performAction(grey_tap())
        
        let collection = tester().waitForViewWithAccessibilityIdentifier("AS Top Sites View") as! UICollectionView
        let firstCell = collection.visibleCells().first!
		
		// Delete the site, and verify that the tile we removed is removed
		deleteSuggestedTopsite(firstCell.accessibilityLabel!)
    }

    func test_EmptyState() {
        // Switch to the Bookmarks panel and back so we can later reload Top Sites.
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Bookmarks")).performAction(grey_tap())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Top sites")).performAction(grey_tap())
        
        // Delete all of the suggested tiles (with suggested site, they are marked hidden,
		// not removed completely)
        var collection = tester().waitForViewWithAccessibilityIdentifier("AS Top Sites View") as! UICollectionView
        while collection.visibleCells().count > 0 {
            let firstCell = collection.visibleCells().first!
            if (firstCell.isVisibleInViewHierarchy() == false) {
                break
            } else {
                deleteSuggestedTopsite(firstCell.accessibilityLabel!)
            }
        }

        // Add a new history item
        // Verify that empty state no longer appears
        BrowserUtils.addHistoryEntry("", url: NSURL(string: "https://mozilla.org")!)

        // Switch to the Bookmarks panel and back so we can later reload Top Sites.
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Bookmarks")).performAction(grey_tap())
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Top sites")).performAction(grey_tap())
        
        collection = tester().waitForViewWithAccessibilityIdentifier("AS Top Sites View") as! UICollectionView
        // 1 topsite from history is populated: no default topsites are re-populated
        XCTAssertEqual(collection.visibleCells().count, 1)
        
        // Delete the history item cell for cleanup
        let firstCell = collection.visibleCells().first!
        deleteSuggestedTopsite(firstCell.accessibilityLabel!)

    }

    private func deleteSuggestedTopsite(accessibilityLabel: String) {
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel(accessibilityLabel))
            .inRoot(grey_kindOfClass(NSClassFromString("Client.TopSiteItemCell")))
            .performAction(grey_longPress())
        
        EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Remove"))
            .inRoot(grey_kindOfClass(NSClassFromString("Client.ActionOverlayTableViewCell")))
            .performAction(grey_tap())
        
        let disappeared = GREYCondition(name: "Wait for icon to disappear", block: { _ in
			var errorOrNil: NSError?
			let matcher = grey_allOfMatchers(grey_accessibilityLabel(accessibilityLabel),
                grey_kindOfClass(NSClassFromString("UILabel")),
                grey_notVisible())
            
            EarlGrey().selectElementWithMatcher(matcher)
			.assertWithMatcher(grey_notNil(), error: &errorOrNil)
			let success = errorOrNil == nil
			return success
        }).waitWithTimeout(5)
		
		GREYAssertTrue(disappeared, reason: "Failed to disappear")
    }
    
    private func deleteHistoryTopsite(siteCount: Int = 1) {
        
        for _ in 1...siteCount {
			var collection = self.tester().waitForViewWithAccessibilityIdentifier("AS Top Sites View") as! UICollectionView
            let firstCell = collection.visibleCells().first!
			let accessibilityLabel = firstCell.accessibilityLabel
			
			EarlGrey().selectElementWithMatcher(grey_accessibilityLabel(accessibilityLabel))
				.inRoot(grey_kindOfClass(NSClassFromString("Client.TopSiteItemCell")))
				.performAction(grey_longPress())
			
			EarlGrey().selectElementWithMatcher(grey_accessibilityLabel("Remove"))
				.inRoot(grey_kindOfClass(NSClassFromString("Client.ActionOverlayTableViewCell")))
				.performAction(grey_tap())
        
			let disappeared = GREYCondition(name: "Wait for icon to disappear", block: { _ in
				collection = self.tester().waitForViewWithAccessibilityIdentifier("AS Top Sites View") as! UICollectionView
				for index in 1...collection.visibleCells().count {
					if (collection.visibleCells()[index-1].accessibilityLabel == accessibilityLabel) {
						return false
					}
				}
				return true
			}).waitWithTimeout(5)
			
			GREYAssertTrue(disappeared, reason: "Failed to disappear")
		}
    }
    
    override func tearDown() {
        profile.prefs.setObject([], forKey: "topSites.deletedSuggestedSites")
        BrowserUtils.resetToAboutHome(tester())
    }
 
}
