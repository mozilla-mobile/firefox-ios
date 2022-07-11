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
    override func setUp() async throws {
        try? await super.setUp()

        profile = MockProfile(databasePrefix: "historyDeletion_tests")
        profile._reopen()

        await emptyDB()
    }

    override func tearDown() async throws {
        try? await super.tearDown()

        profile._shutdown()
        profile = nil
    }

    // MARK: - General Tests
    func testEmptyRead() async {
        Task {
            await assertDBIsEmpty()
        }
    }

    func testSingleDataExists() async {
        let testSites = [SiteElements(domain: "mozilla")]
        populateDBHistory(with: testSites)

        Task {
            await assertDBStateFor(testSites)
        }
    }

    // MARK: - Test url based deletion
    func testDeletingSingleItem() async {
        let testSites = [SiteElements(domain: "mozilla")]
        populateDBHistory(with: testSites)
        let siteEntry = createWebsiteFor(domain: "mozilla", with: "")

        Task {
            let result = await deletionWithExpectation([siteEntry.url])
            XCTAssertTrue(result)
            await assertDBIsEmpty()
        }
    }

   func testDeletingMultipleItemsEmptyingDatabase() async {
       let sitesToDelete = [SiteElements(domain: "mozilla"),
                            SiteElements(domain: "amazon"),
                            SiteElements(domain: "google")]
       populateDBHistory(with: sitesToDelete)

       let siteEntries = sitesToDelete
           .map { self.createWebsiteFor(domain: $0.domain, with: $0.path) }
           .map { $0.url }

       Task {
           let result = await deletionWithExpectation(siteEntries)
           XCTAssertTrue(result)
           await assertDBIsEmpty()
       }
   }

   func testDeletingMultipleTopLevelItems() async {
       let sitesToRemain = [SiteElements(domain: "cnn")]
       let sitesToDelete = [SiteElements(domain: "mozilla"),
                            SiteElements(domain: "google"),
                            SiteElements(domain: "amazon")]
       populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled())

       let siteEntries = sitesToDelete
           .map { self.createWebsiteFor(domain: $0.domain, with: $0.path) }
           .map { $0.url }

       Task {
           let result = await deletionWithExpectation(siteEntries)
           XCTAssertTrue(result)
           await assertDBStateFor(sitesToRemain)
       }
   }

   func testDeletingMultipleSpecificItems() async {
       let sitesToRemain = [SiteElements(domain: "cnn", path: "newsOne/test1.html")]
       let sitesToDelete = [SiteElements(domain: "cnn", path: "newsOne/test2.html"),
                            SiteElements(domain: "cnn", path: "newsOne/test3.html"),
                            SiteElements(domain: "cnn", path: "newsTwo/test1.html")]
       populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled())

       let siteEntries = sitesToDelete
           .map { self.createWebsiteFor(domain: $0.domain, with: $0.path) }
           .map { $0.url }

       Task {
           let result = await deletionWithExpectation(siteEntries)
           XCTAssertTrue(result)
           await assertDBStateFor(sitesToRemain)
       }
   }

    // MARK: - Test time based deletion
    // In these tests, we don't test the deletion of metadata. The assumption
    // is that A-S has its own testing. Furthermore, because we don't have an
    // API to control when the date at which a metadata item is created,
    // currently making testing these time frames, with the exception of
    // `.allTime` impossible to test.

    func testDeletingAllItemsInLastHour() async {
        guard let thirtyMinutesAgo = Calendar.current.date(byAdding: .minute,
                                                           value: -30,
                                                           to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .lastHour
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: thirtyMinutesAgo),
                             SiteElements(domain: "mozilla")]
        populateDBHistory(with: sitesToDelete)

        Task {
            let returnedTimeFrame = await deletionWithExpectation(since: timeframe)
            XCTAssertEqual(timeframe, returnedTimeFrame)
//            await assertDBIsEmpty(shouldSkipMetadata: true)
            await assertHistoryIsEmpty()
        }
    }

    func testDeletingItemsInLastHour_WithFurtherHistory() async {
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

        let timeframe: HistoryDeletionUtilityDateOptions = .lastHour
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: thirtyMinutesAgo)]
        let sitesToRemain = [SiteElements(domain: "mozilla", timeVisited: twoHoursAgo)]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled())

        Task {
            let returnedTimeFrame = await deletionWithExpectation(since: timeframe)
            XCTAssertEqual(timeframe, returnedTimeFrame)
            await assertDBHistoryStateFor(sitesToRemain)
        }
    }

    func testDeletingAllItemsInHistoryUsingToday() async {
        guard let someTimeToday = Calendar.current.date(
            byAdding: .minute,
            value: 1,
            to: Calendar.current.startOfDay(for: Date()))?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .today
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: someTimeToday),
                             SiteElements(domain: "mozilla")]
        populateDBHistory(with: sitesToDelete)

        Task {
            let returnedTimeFrame = await deletionWithExpectation(since: timeframe)
            XCTAssertEqual(timeframe, returnedTimeFrame)
//            await assertDBIsEmpty(shouldSkipMetadata: true)
            await assertHistoryIsEmpty()
        }
    }

    func testDeletingItemsInHistoryUsingToday_WithFurtherHistory() async {
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

        let timeframe: HistoryDeletionUtilityDateOptions = .today
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: someTimeToday)]
        let sitesToRemain = [SiteElements(domain: "mozilla", timeVisited: thirtyHoursAgo)]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled())

        Task {
            let returnedTimeFrame = await deletionWithExpectation(since: timeframe)
            XCTAssertEqual(timeframe, returnedTimeFrame)
            await assertDBHistoryStateFor(sitesToRemain)
        }
    }

    func testDeletingAllItemsInHistoryUsingYesterday() async {
        guard let someTimeYesterday = someTimeYesterday()?.toMicrosecondsSince1970() else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .yesterday
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: someTimeYesterday),
                             SiteElements(domain: "mozilla")]
        populateDBHistory(with: sitesToDelete)

        Task {
            let returnedTimeFrame = await deletionWithExpectation(since: timeframe)
            XCTAssertEqual(timeframe, returnedTimeFrame)
//            await assertDBIsEmpty(shouldSkipMetadata: true)
            await assertHistoryIsEmpty()
        }
    }

    func testDeletingItemsInHistoryUsingYesterday_WithFurtherHistory() async {
        guard let someTimeYesterday = someTimeYesterday()?.toMicrosecondsSince1970(),
              let ninetyHoursAgo = Calendar.current.date(byAdding: .hour,
                                                         value: -90,
                                                         to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .yesterday
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: someTimeYesterday)]
        let sitesToRemain = [SiteElements(domain: "mozilla", timeVisited: ninetyHoursAgo)]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled())

        Task {
            let returnedTimeFrame = await deletionWithExpectation(since: timeframe)
            XCTAssertEqual(timeframe, returnedTimeFrame)
            await assertDBHistoryStateFor(sitesToRemain)
        }
    }

    func testDeletingAllItemsInHistoryUsingAllTime() async {
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

        let timeframe: HistoryDeletionUtilityDateOptions = .allTime
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: earlierToday),
                             SiteElements(domain: "polygon", timeVisited: yesterday),
                             SiteElements(domain: "theverge", timeVisited: aFewDaysAgo),
                             SiteElements(domain: "macrumors", timeVisited: twoWeeksAgo),
                             SiteElements(domain: "doihaveinternet", timeVisited: lastMonth)]
        populateDBHistory(with: sitesToDelete)

        Task {
            let returnedTimeFrame = await deletionWithExpectation(since: timeframe)
            XCTAssertEqual(timeframe, returnedTimeFrame)
//            await assertDBIsEmpty(shouldSkipMetadata: true)
            await assertHistoryIsEmpty()
        }
//        runAsyncTests {
//            let returnedTimeFrame = await self.deletionWithExpectation(since: timeframe)
//            XCTAssertEqual(timeframe, returnedTimeFrame)
//            await self.assertDBIsEmpty(shouldSkipMetadata: true)
//        }
    }
}

// MARK: - Helper functions
private extension HistoryDeletionUtilityTests {

    private func runAsyncTests(_ completion: @escaping (() async -> Void)) {
        let expectation = XCTestExpectation(description: #function)

        Task {
            await completion()
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 30)
    }

//    func createDeletionUtility(file: StaticString = #filePath, line: UInt = #line) -> HistoryDeletionUtility {
//        let deletionUtility = HistoryDeletionUtility(with: profile)
//        trackForMemoryLeaks(deletionUtility, file: file, line: line)
//
//        return deletionUtility
//    }
//
    func deletionWithExpectation(_ siteEntries: [String]) async -> Bool {
        let deletionUtility = HistoryDeletionUtility(with: profile)
        let result = await deletionUtility.delete(siteEntries)

        return result
    }

    func deletionWithExpectation(
        since dateOption: HistoryDeletionUtilityDateOptions
    ) async -> HistoryDeletionUtilityDateOptions? {
        let deletionUtility = HistoryDeletionUtility(with: profile)
        let time = await deletionUtility.deleteHistoryFrom(dateOption)

        return time
    }

    func emptyDB(file: StaticString = #filePath, line: UInt = #line) async {
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess, file: file, line: line)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess, file: file, line: line)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess, file: file, line: line)

        XCTAssertTrue(profile.history.removeHistoryFromDate(Date(timeIntervalSince1970: 0)).value.isSuccess, file: file, line: line)
    }

    // `shouldSkipMetadata` is a  parameter to deal with the case where AS doesn't allow
    // for entering a custom date for metadata. If this is set to `true`, then the
    // metadata check will not run, and only the history check will run.
    func assertDBIsEmpty(
        shouldSkipMetadata: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        if !shouldSkipMetadata { await assertMetadataIsEmpty(file: file, line: line) }
        await assertHistoryIsEmpty(file: file, line: line)
    }

    func assertMetadataIsEmpty(file: StaticString = #filePath, line: UInt = #line) async {
        let emptyMetadata = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(emptyMetadata.isSuccess, file: file, line: line)
        XCTAssertNotNil(emptyMetadata.successValue, file: file, line: line)
        XCTAssertEqual(emptyMetadata.successValue!.count, 0, "Metadata", file: file, line: line)
    }

    func assertHistoryIsEmpty(file: StaticString = #filePath, line: UInt = #line) async {
        let emptyHistory = profile.history.getSitesByLastVisit(limit: 100, offset: 0).value
        XCTAssertTrue(emptyHistory.isSuccess, file: file, line: line)
        XCTAssertNotNil(emptyHistory.successValue, file: file, line: line)
        XCTAssertEqual(emptyHistory.successValue!.count, 0, "History", file: file, line: line)
    }

    func assertDBStateFor(
        _ sites: [SiteElements],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        await assertDBMetadataStateFor(sites)
        await assertDBHistoryStateFor(sites)
    }

    func assertDBMetadataStateFor(
        _ sites: [SiteElements],
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
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
    ) async {
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
