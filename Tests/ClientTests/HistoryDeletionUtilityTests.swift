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
    struct SiteElements {
        let domain: String
        let path: String

        init(domain: String, path: String = "") {
            self.domain = domain
            self.path = path
        }
    }

    private var profile: MockProfile!

    override func setUp() {
        super.setUp()

        profile = MockProfile(databasePrefix: "historyDeletion_tests")
        profile._reopen()

        emptyDB()
    }

    override func tearDown() {
        super.tearDown()

        profile._shutdown()
        profile = nil
    }

    func testEmptyRead() {
        assertDBIsEmpty()
    }

    func testSingleDataExists() {
        let testSites = [SiteElements(domain: "mozilla")]
        populateDBHistory(with: testSites)

        assertDBStateFor(testSites)
    }

    func testDeletingSingleItem() {
        let testSites = [SiteElements(domain: "mozilla")]
        populateDBHistory(with: testSites)

        let siteEntry = createWebsiteFor(domain: "mozilla", with: "")
        deletionWithExpectation([siteEntry.url]) { result in
            XCTAssertTrue(result)
            self.assertDBIsEmpty()
        }
    }

   func testDeletingMultipleItemsEmptyingDatabase() {
       let sitesToDelete = [SiteElements(domain: "mozilla"),
                            SiteElements(domain: "amazon"),
                            SiteElements(domain: "google")]
       populateDBHistory(with: sitesToDelete)

       let siteEntries = sitesToDelete
           .map { self.createWebsiteFor(domain: $0.domain, with: $0.path) }
           .map { $0.url }

       deletionWithExpectation(siteEntries) { result in
           XCTAssertTrue(result)
           self.assertDBIsEmpty()
       }
   }

   func testDeletingMultipleTopLevelItems() {
       let testSites = [SiteElements(domain: "cnn")]
       let sitesToDelete = [SiteElements(domain: "mozilla"),
                            SiteElements(domain: "google"),
                            SiteElements(domain: "amazon")]
       populateDBHistory(with: (testSites + sitesToDelete).shuffled())

       let siteEntries = sitesToDelete
           .map { self.createWebsiteFor(domain: $0.domain, with: $0.path) }
           .map { $0.url }

       deletionWithExpectation(siteEntries) { result in
           XCTAssertTrue(result)
           // Assert DB contains only the expected number of things
           self.assertDBStateFor(testSites)
       }
   }

   func testDeletingMultipleSpecificItems() {
       let testSites = [SiteElements(domain: "cnn", path: "newsOne/test1.html")]
       let sitesToDelete = [SiteElements(domain: "cnn", path: "newsOne/test2.html"),
                            SiteElements(domain: "cnn", path: "newsOne/test3.html"),
                            SiteElements(domain: "cnn", path: "newsTwo/test1.html")]
       populateDBHistory(with: (testSites + sitesToDelete).shuffled())

       let siteEntries = sitesToDelete
           .map { self.createWebsiteFor(domain: $0.domain, with: $0.path) }
           .map { $0.url }

       deletionWithExpectation(siteEntries) { result in
           XCTAssertTrue(result)
           // Assert DB contains only the expected number of things
           self.assertDBStateFor(testSites)
       }
   }
}

// MARK: - Helper functions
private extension HistoryDeletionUtilityTests {

    func createDeletionUtility(file: StaticString = #filePath, line: UInt = #line) -> HistoryDeletionUtility {
        let deletionUtility = HistoryDeletionUtility(with: profile)
        trackForMemoryLeaks(deletionUtility, file: file, line: line)

        return deletionUtility
    }

    func deletionWithExpectation(_ siteEntries: [String], completion: @escaping (Bool) -> Void) {
        let deletionUtility = createDeletionUtility()
        let expectation = expectation(description: "HistoryDeletionUtilityTest")

        deletionUtility.delete(siteEntries) { result in
            completion(result)
            expectation.fulfill()
        }

       waitForExpectations(timeout: 30, handler: nil)
    }

    func emptyDB(file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess, file: file, line: line)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess, file: file, line: line)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess, file: file, line: line)

        XCTAssertTrue(profile.history.removeHistoryFromDate(Date(timeIntervalSince1970: 0)).value.isSuccess, file: file, line: line)
    }

    func assertDBIsEmpty(file: StaticString = #filePath, line: UInt = #line) {
        assertMetadataIsEmpty(file: file, line: line)
        assertHistoryIsEmpty(file: file, line: line)
    }

    func assertMetadataIsEmpty(file: StaticString = #filePath, line: UInt = #line) {
        let emptyMetadata = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(emptyMetadata.isSuccess, file: file, line: line)
        XCTAssertNotNil(emptyMetadata.successValue, file: file, line: line)
        XCTAssertEqual(emptyMetadata.successValue!.count, 0, file: file, line: line)
    }

    func assertHistoryIsEmpty(file: StaticString = #filePath, line: UInt = #line) {
        let emptyHistory = profile.history.getSitesByLastVisit(limit: 100, offset: 0).value
        XCTAssertTrue(emptyHistory.isSuccess, file: file, line: line)
        XCTAssertNotNil(emptyHistory.successValue, file: file, line: line)
        XCTAssertEqual(emptyHistory.successValue!.count, 0, file: file, line: line)
    }

    func assertDBStateFor(_ sites: [SiteElements],
                                  file: StaticString = #filePath,
                                  line: UInt = #line
    ) {
        let metadataItems = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(metadataItems.isSuccess, file: file, line: line)
        XCTAssertNotNil(metadataItems.successValue, file: file, line: line)
        XCTAssertEqual(metadataItems.successValue!.count, sites.count, file: file, line: line)

        let historyItems = profile.history.getSitesByLastVisit(limit: 100, offset: 0).value
        XCTAssertTrue(historyItems.isSuccess, file: file, line: line)
        XCTAssertNotNil(historyItems.successValue, file: file, line: line)
        XCTAssertEqual(historyItems.successValue!.count, sites.count, file: file, line: line)

        for (index, site) in sites.enumerated() {
            guard let metadataURL = metadataItems.successValue?[index].url,
                  let metadataTitle = metadataItems.successValue?[index].title?.lowercased(),
                  let historyURL = historyItems.successValue?[index]?.url,
                  let historyTitle = historyItems.successValue?[index]?.title.lowercased()
            else {
                XCTFail("Items that should exist in the database, do not.")
                return
            }

            XCTAssertEqual(metadataURL, "https://www.\(site.domain).com/\(site.path)", file: file, line: line)
            XCTAssertEqual(metadataTitle, "\(site.domain) test", file: file, line: line)
            XCTAssertEqual(metadataItems.successValue![index].documentType, DocumentType.regular, file: file, line: line)
            XCTAssertEqual(metadataItems.successValue![index].totalViewTime, 1, file: file, line: line)

            XCTAssertEqual(historyURL, "https://www.\(site.domain).com/\(site.path)", file: file, line: line)
            XCTAssertEqual(historyTitle, "\(site.domain) test", file: file, line: line)
        }
    }

    func populateDBHistory(with entries: [SiteElements],
                                   file: StaticString = #filePath,
                                   line: UInt = #line
    ) {
        entries.forEach { entry in
            let site = createWebsiteFor(domain: entry.domain, with: entry.path)
            addToLocalHistory(site: site)
            setupMetadataItem(forTestURL: site.url,
                              withTitle: site.title,
                              andViewTime: 1)
        }
    }

    func createWebsiteFor(domain name: String, with path: String = "") -> Site {
        let urlString = "https://www.\(name).com/\(path)"
        let urlTitle = "\(name) test"

        return Site(url: urlString, title: urlTitle)
    }

    func addToLocalHistory(site: Site, file: StaticString = #filePath, line: UInt = #line) {
        let visit = SiteVisit(site: site, date: Date.nowMicroseconds())
        XCTAssertTrue(profile.history.addLocalVisit(visit).value.isSuccess, "Site added: \(site.url).", file: file, line: line)
    }

    func setupMetadataItem(forTestURL siteURL: String,
                                   withTitle title: String,
                                   andViewTime viewTime: Int32,
                                   file: StaticString = #filePath,
                                   line: UInt = #line
    ) {
        let metadataKey1 = HistoryMetadataKey(url: siteURL, searchTerm: title, referrerUrl: nil)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: nil,
                title: title
            )
        ).value.isSuccess, file: file, line: line)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: viewTime,
                documentType: nil,
                title: nil
            )
        ).value.isSuccess, file: file, line: line)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: .regular,
                title: nil
            )
        ).value.isSuccess, file: file, line: line)
    }
}
