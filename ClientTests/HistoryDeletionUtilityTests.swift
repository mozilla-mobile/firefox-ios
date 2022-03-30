// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client
@testable import Storage

// This file has two built in assumptions:
// 1. HistoryHighlights writes&deletes data correctly
// 2. History writes&deletes data correctly
// These basic cases are not tested here as they are tested in
// `HistoryHighlightsManagerTests` and `TestHistory` respectively
class HistoryDeletionUtilityTests: XCTestCase {
    private struct SiteElements {
        let domain: String
        let path: String

        init(domain: String, path: String = "") {
            self.domain = domain
            self.path = path
        }
    }

    private var profile: MockProfile!
    private var deletionUtility: HistoryDeletionUtility!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "historyDeletion_tests")
        profile._reopen()
        deletionUtility = HistoryDeletionUtility(with: profile)
    }

    override func tearDown() {
        super.tearDown()

        deletionUtility = nil
        profile._shutdown()
        profile = nil
    }

    func testEmptyRead() {
        emptyDB()
        assertDBIsEmpty()
    }

    func testSingleDataExists() {
        emptyDB()

        let testSites = [SiteElements(domain: "mozilla")]
        populateDBHistory(with: testSites)

        assertDBStateFor(testSites)
    }

    func testDeletingSingleItem() {
        emptyDB()

        let testSites = [SiteElements(domain: "mozilla")]
        populateDBHistory(with: testSites)

        let siteEntry = createWebsiteFor(domain: "mozilla", with: "")
        deletionUtility.delete([siteEntry.url])

        assertDBIsEmpty()
    }

   func testDeletingMultipleItemsEmptyingDatabase() {
       emptyDB()

       let sitesToDelete = [SiteElements(domain: "mozilla"),
                            SiteElements(domain: "amazon"),
                            SiteElements(domain: "google")]
       populateDBHistory(with: sitesToDelete)

       let siteEntries = sitesToDelete
           .map { self.createWebsiteFor(domain: $0.domain, with:  $0.path) }
           .map { $0.url }
       deletionUtility.delete(siteEntries)

       assertDBIsEmpty()
   }

   func testDeletingMultipleTopLevelItems() {
       emptyDB()

       let testSites = [SiteElements(domain: "cnn"),
                        SiteElements(domain: "macrumors")]
       let sitesToDelete = [SiteElements(domain: "mozilla"),
                            SiteElements(domain: "google"),
                            SiteElements(domain: "amazon")]
       populateDBHistory(with: (testSites + sitesToDelete).shuffled())

       let siteEntries = sitesToDelete
           .map { self.createWebsiteFor(domain: $0.domain, with:  $0.path) }
           .map { $0.url }
       deletionUtility.delete(siteEntries)

       // Assert DB contains only the expected number of things
       assertDBStateFor(testSites)
   }

   func testDeletingMultipleSpecificItems() {
       emptyDB()

       let testSites = [SiteElements(domain: "cnn", path: "newsOne/test1.html"),
                        SiteElements(domain: "mozilla", path: "fancypants.html"),
                        SiteElements(domain: "cnn", path: "newsTwo/test2.html")]
       let sitesToDelete = [SiteElements(domain: "cnn", path: "newsOne/test2.html"),
                            SiteElements(domain: "cnn", path: "newsOne/test3.html"),
                            SiteElements(domain: "cnn", path: "newsTwo/test1.html")]
       populateDBHistory(with: (testSites + sitesToDelete).shuffled())

       let siteEntries = sitesToDelete
           .map { self.createWebsiteFor(domain: $0.domain, with:  $0.path) }
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

    private func assertDBStateFor(_ sites: [SiteElements]) {
        let metadataItems = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(metadataItems.isSuccess)
        XCTAssertNotNil(metadataItems.successValue)
        XCTAssertEqual(metadataItems.successValue!.count, sites.count)

        let historyItems = profile.history.getSitesByLastVisit(limit: 100, offset: 0).value
        XCTAssertTrue(historyItems.isSuccess)
        XCTAssertNotNil(historyItems.successValue)
        XCTAssertEqual(historyItems.successValue!.count, sites.count)

        for (index, site) in sites.enumerated() {
            XCTAssertEqual(metadataItems.successValue![index].url, "https://www.\(site.domain).com/\(site.path)")
            XCTAssertEqual(metadataItems.successValue![index].title?.lowercased(), "\(site.domain) test")
            XCTAssertEqual(metadataItems.successValue![index].documentType, DocumentType.regular)
            XCTAssertEqual(metadataItems.successValue![index].totalViewTime, 1)

            XCTAssertEqual(historyItems.successValue![index]?.url, "https://www.\(site.domain).com/\(site.path)")
            XCTAssertEqual(historyItems.successValue![index]?.title.lowercased(), "\(site.domain) test")
        }
    }

    private func populateDBHistory(with entries: [SiteElements]) {
        for entry in entries {
            let site = createWebsiteFor(domain: entry.domain, with: entry.path)
            addToLocalHistory(site: site)
            setupMetadataItem(forTestURL: site.url,
                              withTitle: site.title,
                              andViewTime: 1)
        }
    }

    private func createWebsiteFor(domain name: String, with path: String = "") -> Site {
        let urlString = "https://www.\(name).com/\(path)"
        let urlTitle = "\(name) test"

        return Site(url: urlString, title: urlTitle)
    }

    private func addToLocalHistory(site: Site) {
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
}
