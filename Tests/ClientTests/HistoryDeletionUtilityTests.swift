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
        let timeVisited: MicrosecondTimestamp

        init(domain: String,
             path: String = "",
             timeVisited: MicrosecondTimestamp = Date().toMicrosecondsSince1970()) {

            self.domain = domain
            self.path = path
            self.timeVisited = timeVisited
        }
    }

    private var profile: MockProfile!

    // MARK: - Setup & Teardown
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

    // MARK: - General Tests
    func testEmptyRead() {
        assertDBIsEmpty()
    }

    func testSingleDataExists() {
        let testSites = [SiteElements(domain: "mozilla")]
        populateDBHistory(with: testSites)

        assertDBStateFor(testSites)
    }

    // MARK: - Test url based deletion
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

    // MARK: - Test time based deletion
    // In these tests, we don't test the deletion of metadata. The assumption
    // is that A-S has it's own testing. Furthermore, this testing is currently
    // not possible because we don't have an API to control when the date
    // at which a metadata item is created, currently making testing these time
    // frames, with the exception of `.allTime` impossible to test.

    func testDeletingAllItemsInLastHour() {
        guard let thirtyMinutesAgo = Calendar.current.date(byAdding: .minute,
                                                           value: -30,
                                                           to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: thirtyMinutesAgo),
                             SiteElements(domain: "mozilla")]
        populateDBHistory(with: sitesToDelete)

        deletionWithExpectation(since: .lastHour) { result in
            XCTAssertTrue(result)
            self.assertDBIsEmpty(shouldSkipMetadata: true)
        }
    }

    func testDeletingItemsInLastHour_WithFurtherHistory() {
        guard let thirtyMinutesAgo = Calendar.current.date(byAdding: .minute,
                                                           value: -30,
                                                           to: Date())?.toMicrosecondsSince1970(),
              let twoHoursAgo = Calendar.current.date(byAdding: .minute,
                                                      value: -90,
                                                      to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: thirtyMinutesAgo)]
        let sitesToRemain = [SiteElements(domain: "mozilla", timeVisited: twoHoursAgo)]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled())

        deletionWithExpectation(since: .lastHour) { result in
            XCTAssertTrue(result)
            self.assertDBHistoryStateFor(sitesToRemain)
        }
    }

    func testDeletingAllItemsInHistoryUsingToday() {
        guard let someTimeToday = Calendar.current.date(
            byAdding: .minute,
            value: 1,
            to: Calendar.current.startOfDay(for: Date()))?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: someTimeToday),
                             SiteElements(domain: "mozilla")]
        populateDBHistory(with: sitesToDelete)

        deletionWithExpectation(since: .today) { result in
            XCTAssertTrue(result)
            self.assertDBIsEmpty(shouldSkipMetadata: true)
        }
    }

    func testDeletingItemsInHistoryUsingToday_WithFurtherHistory() {
        guard let someTimeToday = Calendar.current.date(
            byAdding: .minute,
            value: 1,
            to: Calendar.current.startOfDay(for: Date()))?.toMicrosecondsSince1970(),
              let thirtyHoursAgo = Calendar.current.date(byAdding: .hour,
                                                         value: -30,
                                                         to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: someTimeToday)]
        let sitesToRemain = [SiteElements(domain: "mozilla", timeVisited: thirtyHoursAgo)]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled())

        deletionWithExpectation(since: .today) { result in
            XCTAssertTrue(result)
            self.assertDBHistoryStateFor(sitesToRemain)
        }
    }

    func testDeletingAllItemsInHistoryUsingYesterday() {
        guard let someTimeYesterday = someTimeYesterday()?.toMicrosecondsSince1970() else {
            XCTFail("Unable to create date")
            return
        }

        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: someTimeYesterday),
                             SiteElements(domain: "mozilla")]
        populateDBHistory(with: sitesToDelete)

        deletionWithExpectation(since: .yesterday) { result in
            XCTAssertTrue(result)
            self.assertDBIsEmpty(shouldSkipMetadata: true)
        }
    }

    func testDeletingItemsInHistoryUsingYesterday_WithFurtherHistory() {
        guard let someTimeYesterday = someTimeYesterday()?.toMicrosecondsSince1970(),
              let ninetyHoursAgo = Calendar.current.date(byAdding: .hour,
                                                         value: -90,
                                                         to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: someTimeYesterday)]
        let sitesToRemain = [SiteElements(domain: "mozilla", timeVisited: ninetyHoursAgo)]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled())

        deletionWithExpectation(since: .yesterday) { result in
            XCTAssertTrue(result)
            self.assertDBHistoryStateFor(sitesToRemain)
        }
    }

    func testDeletingAllItemsInHistoryUsingAllTime() {
        guard let earlierToday = Calendar.current.date(byAdding: .hour,
                                                       value: -5,
                                                       to: Date())?.toMicrosecondsSince1970(),
              let yesterday = someTimeYesterday()?.toMicrosecondsSince1970(),
              let aFewDaysAgo = Calendar.current.date(byAdding: .hour,
                                                      value: -73,
                                                      to: Date())?.toMicrosecondsSince1970(),
              let twoWeeksAgo = Calendar.current.date(byAdding: .day,
                                                      value: -11,
                                                      to: Date())?.toMicrosecondsSince1970(),
              let lastMonth = Calendar.current.date(byAdding: .month,
                                                    value: -1,
                                                    to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: earlierToday),
                             SiteElements(domain: "polygon", timeVisited: yesterday),
                             SiteElements(domain: "theverge", timeVisited: aFewDaysAgo),
                             SiteElements(domain: "macrumors", timeVisited: twoWeeksAgo),
                             SiteElements(domain: "doihaveinternet", timeVisited: lastMonth)]
        populateDBHistory(with: sitesToDelete)

        deletionWithExpectation(since: .allTime) { result in
            XCTAssertTrue(result)
            self.assertDBIsEmpty(shouldSkipMetadata: true)
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

    func deletionWithExpectation(
        since dateOption: HistoryDeletionUtilityDateOptions,
        completion: @escaping (Bool) -> Void
    ) {
        let deletionUtility = createDeletionUtility()
        let expectation = expectation(description: "HistoryDeletionUtilityTest")

        deletionUtility.deleteHistoryFrom(dateOption) { _ in
            completion(true)
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

    // `shouldSkipMetadat` is a temporary parameter to deal with the case where
    // AS doesn't have a forward delete. If this is enabled, then the metadata check
    // is not ran.
    func assertDBIsEmpty(
        shouldSkipMetadata: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !shouldSkipMetadata { assertMetadataIsEmpty(file: file, line: line) }
        assertHistoryIsEmpty(file: file, line: line)
    }

    func assertMetadataIsEmpty(file: StaticString = #filePath, line: UInt = #line) {
        let emptyMetadata = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(emptyMetadata.isSuccess, file: file, line: line)
        XCTAssertNotNil(emptyMetadata.successValue, file: file, line: line)
        XCTAssertEqual(emptyMetadata.successValue!.count, 0, "Metadata", file: file, line: line)
    }

    func assertHistoryIsEmpty(file: StaticString = #filePath, line: UInt = #line) {
        let emptyHistory = profile.history.getSitesByLastVisit(limit: 100, offset: 0).value
        XCTAssertTrue(emptyHistory.isSuccess, file: file, line: line)
        XCTAssertNotNil(emptyHistory.successValue, file: file, line: line)
        XCTAssertEqual(emptyHistory.successValue!.count, 0, "History", file: file, line: line)
    }
    func assertDBStateFor(
        _ sites: [SiteElements],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertDBMetadataStateFor(sites)
        assertDBHistoryStateFor(sites)
    }

    func assertDBMetadataStateFor(
        _ sites: [SiteElements],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let metadataItems = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(metadataItems.isSuccess, file: file, line: line)
        XCTAssertNotNil(metadataItems.successValue, file: file, line: line)
        XCTAssertEqual(metadataItems.successValue!.count, sites.count, file: file, line: line)

        for (index, site) in sites.enumerated() {
            guard let metadataURL = metadataItems.successValue?[index].url,
                  let metadataTitle = metadataItems.successValue?[index].title?.lowercased()
            else {
                XCTFail("Items that should exist in the database, do not.")
                return
            }

            XCTAssertEqual(metadataURL, "https://www.\(site.domain).com/\(site.path)", file: file, line: line)
            XCTAssertEqual(metadataTitle, "\(site.domain) test", file: file, line: line)
            XCTAssertEqual(metadataItems.successValue![index].documentType, DocumentType.regular, file: file, line: line)
            XCTAssertEqual(metadataItems.successValue![index].totalViewTime, 1, file: file, line: line)
        }
    }

    func assertDBHistoryStateFor(
        _ sites: [SiteElements],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let historyItems = profile.history.getSitesByLastVisit(limit: 100, offset: 0).value
        XCTAssertTrue(historyItems.isSuccess, file: file, line: line)
        XCTAssertNotNil(historyItems.successValue, file: file, line: line)
        XCTAssertEqual(historyItems.successValue!.count, sites.count, file: file, line: line)

        for (index, site) in sites.enumerated() {
            guard let historyURL = historyItems.successValue?[index]?.url,
                  let historyTitle = historyItems.successValue?[index]?.title.lowercased()
            else {
                XCTFail("Items that should exist in the database, do not.")
                return
            }

            XCTAssertEqual(historyURL, "https://www.\(site.domain).com/\(site.path)", file: file, line: line)
            XCTAssertEqual(historyTitle, "\(site.domain) test", file: file, line: line)
        }
    }

    func populateDBHistory(
        with entries: [SiteElements],
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        entries.forEach { entry in
            let site = createWebsiteFor(domain: entry.domain, with: entry.path)
            addToLocalHistory(site: site, timeVisited: entry.timeVisited)
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

    func addToLocalHistory(
        site: Site,
        timeVisited: MicrosecondTimestamp,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let visit = SiteVisit(site: site, date: timeVisited)
        XCTAssertTrue(profile.history.addLocalVisit(visit).value.isSuccess, "Site added: \(site.url).", file: file, line: line)
    }

    func setupMetadataItem(
        forTestURL siteURL: String,
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

    private func someTimeYesterday() -> Date? {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()),
              let someTimeYesterday = Calendar.current.date(
                byAdding: .hour,
                value: 1,
                to: Calendar.current.startOfDay(for: yesterday))
        else { return nil }

        return someTimeYesterday
    }
}
