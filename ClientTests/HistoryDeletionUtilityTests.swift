// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client
@testable import Storage

// A few tests here have built in assumptions:
// 1. HistoryHighlights write&delete data correctly
// 2. History write&delete data correctly
// These basic cases are not tested here as they are tested in
// `HistoryHighlightsManagerTests` and `TestHistory` respectively
class HistoryDeletionUtilityTests: XCTestCase {
    typealias manager = HistoryHighlightsManager

    private var profile: MockProfile!
    private var tabManager: TabManager!
    private var deletionUtility: HistoryDeletionUtility!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "historyDeletion_tests")
        profile._reopen()
        tabManager = TabManager(profile: profile, imageStore: nil)
        deletionUtility = HistoryDeletionUtility(with: profile)
    }

    override func tearDown() {
        super.tearDown()

        deletionUtility = nil
        profile._shutdown()
        profile = nil
        tabManager = nil
    }

    func testEmptyRead() {
        emptyDB()
        assertDBIsEmpty()
    }

    func testSingleDataExists() {
        emptyDB()

        let testSites = [("mozilla", "")]
        createHistoryEntry(siteEntry: testSites)

        assertDBStateFor(testSites)
    }

    func testDeletingSingleItem() {
        emptyDB()

        let testSites = [("mozilla", "")]
        createHistoryEntry(siteEntry: testSites)

        let siteEntry = createWebsiteEntry(named: "mozilla", with: "")
        deletionUtility.delete([siteEntry.url])

        assertDBIsEmpty()
    }

   func testDeletingMultipleItemsEmptyingDatabase() {
       emptyDB()

       let sitesToDelete = [("mozilla", ""),
                            ("amazon", ""),
                            ("google", "")]
       createHistoryEntry(siteEntry: sitesToDelete)

       let siteEntries = sitesToDelete
           .map { self.createWebsiteEntry(named: $0.1, with:  $0.1) }
           .map { $0.url }
       deletionUtility.delete(siteEntries)

       assertDBIsEmpty()
   }

   func testDeletingMultipleTopLevelItems() {
       emptyDB()

       let testSites = [("cnn", ""),
                        ("macrumors", "")]
       let sitesToDelete = [("mozilla", ""),
                            ("google", ""),
                            ("amazon", "")]
       var randomizedSites = (testSites + sitesToDelete).shuffled()
       createHistoryEntry(siteEntry: randomizedSites)

       let siteEntries = sitesToDelete
           .map { self.createWebsiteEntry(named: $0.1, with:  $0.1) }
           .map { $0.url }
       deletionUtility.delete(siteEntries)

       // Assert DB contains only the expected number of things
       assertDBStateFor(testSites)
   }

   func testDeletingMultipleSpecificItems() {
       emptyDB()

       let testSites = [("cnn", "newsOne/test1.html"),
                        ("mozilla", "fancypants.html"),
                        ("cnn", "newsTwo/test2.html")]
       let sitesToDelete = [("cnn", "newsOne/test2.html"),
                            ("cnn", "newsOne/test3.html"),
                            ("cnn", "newsTwo/test1.html")]
       var randomizedSites = (testSites + sitesToDelete).shuffled()
       createHistoryEntry(siteEntry: randomizedSites)

       let siteEntries = sitesToDelete
         .map { self.createWebsiteEntry(named: $0.1, with:  $0.1) }
         .map { $0.url }
       deletionUtility.delete(siteEntries)

       // Assert DB contains only the expected number of things
       assertDBStateFor(testSites)
   }

    // MARK: - Helper functions

    private func emptyDB() {
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess)

        XCTAssertTrue(profile.history.removeHistoryFromDate(Date(timeIntervalSince1970: 0)).value.isSuccess)
    }

    private func assertDBIsEmpty() {
        assertMetadataIsEmpty()
        assertHistoryIsEmpty()
    }

    private func assertMetadataIsEmpty() {
        let emptyMetadata = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(emptyMetadata.isSuccess)
        XCTAssertNotNil(emptyMetadata.successValue)
        XCTAssertEqual(emptyMetadata.successValue!.count, 0)
    }

    private func assertHistoryIsEmpty() {
        let emptyHistory = profile.history.getSitesByLastVisit(limit: 100, offset: 0).value
        XCTAssertTrue(emptyHistory.isSuccess)
        XCTAssertNotNil(emptyHistory.successValue)
        XCTAssertEqual(emptyHistory.successValue!.count, 0)
    }

    private func assertDBStateFor(_ sites: [(String, String)]) {
        let metadataItems = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(metadataItems.isSuccess)
        XCTAssertNotNil(metadataItems.successValue)
        XCTAssertEqual(metadataItems.successValue!.count, sites.count)

        let historyItems = profile.history.getSitesByLastVisit(limit: 100, offset: 0).value
        XCTAssertTrue(historyItems.isSuccess)
        XCTAssertNotNil(historyItems.successValue)
        XCTAssertEqual(historyItems.successValue!.count, sites.count)

        for (index, site) in sites.enumerated() {
            XCTAssertEqual(metadataItems.successValue![index].url, "https://www.\(site.0).com/\(site.1)")
            XCTAssertEqual(metadataItems.successValue![index].title?.lowercased(), "\(site) test")
            XCTAssertEqual(metadataItems.successValue![index].documentType, DocumentType.regular)
            XCTAssertEqual(metadataItems.successValue![index].totalViewTime, 1)

            XCTAssertEqual(historyItems.successValue![index]?.url, "https://www.\(site.0).com/\(site.1)")
            XCTAssertEqual(historyItems.successValue![index]?.title.lowercased(), "\(site) test")
        }
    }

    private func createHistoryEntry(siteEntry: [(String, String)]) {
        for (siteText, suffix) in siteEntry {
            let site = createWebsiteEntry(named: siteText, with: suffix)
            addHistory(site: site)
            setupMetadataItem(forTestURL: site.url,
                              withTitle: site.title,
                              andViewTime: 1)
        }
    }

    private func createWebsiteEntry(named name: String, with sufix: String = "") -> Site {
        let urlString = "https://www.\(name).com/\(sufix)"
        let urlTitle = "\(name) test"

        return Site(url: urlString, title: urlTitle)
    }

    private func addHistory(site: Site) {
        let visit = SiteVisit(site: site, date: Date.nowMicroseconds())
        XCTAssertTrue(profile.history.addLocalVisit(visit).value.isSuccess, "Site added: \(site.url).")
    }

    private func setupMetadataItem(forTestURL siteURL: String, withTitle title: String, andViewTime viewTime: Int32) {
        let metadataKey1 = HistoryMetadataKey(url: siteURL, searchTerm: title, referrerUrl: nil)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: nil,
                title: title
            )
        ).value.isSuccess)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: viewTime,
                documentType: nil,
                title: nil
            )
        ).value.isSuccess)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: .regular,
                title: nil
            )
        ).value.isSuccess)
    }

//    private func checkHistorySites(urls: [String: String], s: Bool = true) {
//        // Retrieve the entry.
//        let history = profile.history
//        if let cursor = history.getSitesByLastVisit(limit: 100, offset: 0).value.successValue {
//            XCTAssertEqual(cursor.status, CursorStatus.success,
//                           "Returned success \(cursor.statusMessage).")
//            XCTAssertEqual(cursor.count, urls.count,
//                           "Cursor has \(urls.count) entries.")
//
//            for index in 0..<cursor.count {
//                let s = cursor[index]!
//                XCTAssertNotNil(s, "Cursor has a site for entry.")
//                let title = urls[s.url]
//                XCTAssertNotNil(title, "Found right URL.")
//                XCTAssertEqual(s.title, title!, "Found right title.")
//            }
//        } else {
//            XCTFail("Couldn't get cursor.")
//        }
//    }

//    private func checkHistoryVisits(url: String) {
//        let history = profile.history
//        let expectation = self.expectation(description: "Wait for history")
//        history.getSitesByLastVisit(limit: 100, offset: 0).upon { result in
//            XCTAssertTrue(result.isSuccess)
//            history.getFrecentHistory().getSites(matchingSearchQuery: url, limit: 100).upon { result in
//                XCTAssertTrue(result.isSuccess)
//                let cursor = result.successValue!
//                XCTAssertEqual(cursor.status, CursorStatus.success, "returned success \(cursor.statusMessage)")
//                expectation.fulfill()
//            }
//        }
//        self.waitForExpectations(timeout: 100, handler: nil)
//    }
}
