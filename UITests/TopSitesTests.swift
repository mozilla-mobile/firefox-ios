/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import EarlGrey
@testable import Storage
@testable import Client

class TopSitesTests: KIFTestCase {
    fileprivate var profile: Profile!
    
    override func setUp() {
        profile = (UIApplication.shared.delegate as! AppDelegate).profile!
        BrowserUtils.dismissFirstRunUI()
    }
    
    func test_RemovingSite() {
        // Populate history (Each page has 6 sites listed)
        for i in 1...6 {
            BrowserUtils.addHistoryEntry("", url: URL(string: "https://test\(i).com")!)
        }
        // Switch to the Bookmarks panel and back so we can later reload Top Sites.
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Top sites")).perform(grey_tap())
        
        // Remove the first site and verify that all other sites shift to replace it.
        // Get the first cell.
        deleteHistoryTopsite()
        
        // clear rest of the history
        deleteHistoryTopsite(5)
    }
    
    func test_RemovingSuggestedSites() {
        // Switch to the Bookmarks panel and back so we can later reload Top Sites.
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Top sites")).perform(grey_tap())
        
        let topSiteCell = tester().waitForView(withAccessibilityIdentifier: "TopSitesCell") as! ASHorizontalScrollCell
        let collection = topSiteCell.collectionView
        let firstCell = collection.visibleCells.first!
        
        // Delete the site, and verify that the tile we removed is removed
        deleteSuggestedTopsite(firstCell.accessibilityLabel!)
    }
    
    func test_EmptyState() {
        // Switch to the Bookmarks panel and back so we can later reload Top Sites.
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Top sites")).perform(grey_tap())
        
        // Delete all of the suggested tiles (with suggested site, they are marked hidden,
        // not removed completely)
        var topSiteCell = tester().waitForView(withAccessibilityIdentifier: "TopSitesCell") as! ASHorizontalScrollCell
        var collection = topSiteCell.collectionView
        
        while collection.visibleCells.count > 0 {
            let firstCell = collection.visibleCells.first!
            if firstCell.isVisibleInViewHierarchy() == false {
                break
            } else {
                deleteSuggestedTopsite(firstCell.accessibilityLabel!)
            }
        }
        
        // Add a new history item
        // Verify that empty state no longer appears
        BrowserUtils.addHistoryEntry("", url: URL(string: "https://mozilla.org")!)
        
        // Switch to the Bookmarks panel and back so we can later reload Top Sites.
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Bookmarks")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Top sites")).perform(grey_tap())
        
        topSiteCell = tester().waitForView(withAccessibilityIdentifier: "TopSitesCell") as! ASHorizontalScrollCell
        collection = topSiteCell.collectionView
        // 1 topsite from history is populated: no default topsites are re-populated
        XCTAssertEqual(collection.visibleCells.count, 1)
        
        // Delete the history item cell for cleanup
        let firstCell = collection.visibleCells.first!
        deleteSuggestedTopsite(firstCell.accessibilityLabel!)
        
    }
    
    fileprivate func deleteSuggestedTopsite(_ accessibilityLabel: String) {
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel(accessibilityLabel))
            .inRoot(grey_kindOfClass(NSClassFromString("Client.TopSiteItemCell")))
            .perform(grey_longPress())
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Remove"))
            .inRoot(grey_kindOfClass(NSClassFromString("Client.ActionOverlayTableViewCell")))
            .perform(grey_tap())
        
        let disappeared = GREYCondition(name: "Wait for icon to disappear", block: { _ in
            var errorOrNil: NSError?
            
            let matcher = grey_allOfMatchers([grey_accessibilityLabel(accessibilityLabel),
                                              grey_kindOfClass(NSClassFromString("UILabel")),
                                              grey_notVisible()])
            
            EarlGrey.select(elementWithMatcher: matcher!).assert(with: grey_notNil(), error:  &errorOrNil)
            let success = errorOrNil == nil
            return success
        }).wait(withTimeout: 5)
        
        GREYAssertTrue(disappeared, reason: "Failed to disappear")
    }
    
    fileprivate func deleteHistoryTopsite(_ siteCount: Int = 1) {
        
        let topSiteCell = tester().waitForView(withAccessibilityIdentifier: "TopSitesCell") as! ASHorizontalScrollCell
        let collection = topSiteCell.collectionView
        for _ in 1...siteCount {
            let firstCell = collection.visibleCells.first!
            let accessibilityLabel = firstCell.accessibilityLabel
            
            EarlGrey.select(elementWithMatcher: grey_accessibilityLabel(accessibilityLabel))
                .inRoot(grey_kindOfClass(NSClassFromString("Client.TopSiteItemCell")))
                .perform(grey_longPress())
            EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Remove"))
                .inRoot(grey_kindOfClass(NSClassFromString("Client.ActionOverlayTableViewCell")))
                .perform(grey_tap())
            
            let disappeared = GREYCondition(name: "Wait for icon to disappear", block: { _ in
                var errorOrNil: NSError?
                EarlGrey.select(elementWithMatcher:grey_accessibilityLabel(accessibilityLabel))
                    .assert(with: grey_notNil(), error:  &errorOrNil)
                let success = errorOrNil != nil
                return success
            }).wait(withTimeout: 5)
            
            GREYAssertTrue(disappeared, reason: "Failed to disappear")
        }
    }
    
    override func tearDown() {
        profile.prefs.setObject([], forKey: "topSites.deletedSuggestedSites")
        BrowserUtils.resetToAboutHome(tester())
    }
    
}
