// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices
import Shared
import XCTest

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

    // MARK: - General Tests
    func testEmptyRead() {
        let profile = profileSetup(named: "hsd_emptyTest")

        assertDBIsEmpty(with: profile)
    }

    func testSingleDataExists() {
        let profile = profileSetup(named: "hsd_singleDataExists")
        let testSites = [SiteElements(domain: "mozilla")]
        populateDBHistory(with: testSites, using: profile)

        assertDBStateFor(testSites, with: profile)
    }

    // MARK: - Test url based deletion
    func testDeletingSingleItem() {
        let profile = profileSetup(named: "hsd_deleteSingleItem")
        let testSites = [SiteElements(domain: "mozilla")]
        populateDBHistory(with: testSites, using: profile)
        let siteEntry = createWebsiteFor(domain: "mozilla", with: "")

        deletionWithExpectation(for: [siteEntry.url], using: profile) { result in
            XCTAssertTrue(result)
            self.assertDBIsEmpty(with: profile)
        }
    }

    func testDeletingMultipleItemsEmptyingDatabase() {
        let profile = profileSetup(named: "hsd_deleteMultipleItemsEmptyingDB")
        let sitesToDelete = [SiteElements(domain: "mozilla"),
                             SiteElements(domain: "amazon"),
                             SiteElements(domain: "google")]
        populateDBHistory(with: sitesToDelete, using: profile)

        let siteEntries = sitesToDelete
            .map { self.createWebsiteFor(domain: $0.domain, with: $0.path) }
            .map { $0.url }

        deletionWithExpectation(for: siteEntries, using: profile) { result in
            XCTAssertTrue(result)
            self.assertDBIsEmpty(with: profile)
        }
    }

    func testDeletingMultipleTopLevelItems() {
        let profile = profileSetup(named: "hsd_deleteMultipleItemsTopLevelItems")
        let sitesToRemain = [SiteElements(domain: "cnn")]
        let sitesToDelete = [SiteElements(domain: "mozilla"),
                             SiteElements(domain: "google"),
                             SiteElements(domain: "amazon")]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled(), using: profile)

        let siteEntries = sitesToDelete
            .map { self.createWebsiteFor(domain: $0.domain, with: $0.path) }
            .map { $0.url }

        deletionWithExpectation(for: siteEntries, using: profile) { result in
            XCTAssertTrue(result)
            self.assertDBStateFor(sitesToRemain, with: profile)
        }
    }

    func testDeletingMultipleSpecificItems() {
        let profile = profileSetup(named: "hsd_deleteMultipleSpecificItems")
        let sitesToRemain = [SiteElements(domain: "cnn", path: "newsOne/test1.html")]
        let sitesToDelete = [SiteElements(domain: "cnn", path: "newsOne/test2.html"),
                             SiteElements(domain: "cnn", path: "newsOne/test3.html"),
                             SiteElements(domain: "cnn", path: "newsTwo/test1.html")]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled(), using: profile)

        let siteEntries = sitesToDelete
            .map { self.createWebsiteFor(domain: $0.domain, with: $0.path) }
            .map { $0.url }

        deletionWithExpectation(for: siteEntries, using: profile) { result in
            XCTAssertTrue(result)
            self.assertDBStateFor(sitesToRemain, with: profile)
        }
    }

    // MARK: - Test time based deletion
    // In these tests, we don't test the deletion of metadata. The assumption
    // is that A-S has its own testing. Furthermore, because we don't have an
    // API to control when the date at which a metadata item is created,
    // currently making testing these time frames, with the exception of
    // `.allTime` impossible to test.

    func testDeletingAllItemsInLastHour() {
        let profile = profileSetup(named: "hsd_deleteLastHour")
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
        populateDBHistory(with: sitesToDelete, using: profile)

        deletionWithExpectation(since: timeframe, using: profile) { returnedTimeFrame in
            XCTAssertEqual(timeframe, returnedTimeFrame)
            self.assertDBIsEmpty(with: profile, shouldSkipMetadata: true)
        }
        deleteHistoryMetadataOlderThan(dateOption: timeframe, using: profile)
    }

    func testDeletingItemsInLastHour_WithFurtherHistory() {
        let profile = profileSetup(named: "hsd_deleteLastHour_WithFurtherHistory")
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
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled(), using: profile)

        deletionWithExpectation(since: timeframe, using: profile) { returnedTimeFrame in
            XCTAssertEqual(timeframe, returnedTimeFrame)
            self.assertDBHistoryStateFor(sitesToRemain, with: profile)
        }
        deleteHistoryMetadataOlderThan(dateOption: timeframe, using: profile)
    }

    func testDeletingAllItemsInHistoryUsingLastTwentyFourHours() {
        let profile = profileSetup(named: "hsd_deleteLastTwentyFourHours")
        guard let twelveHoursAgo = Calendar.current.date(
            byAdding: .hour,
            value: -12,
            to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .lastTwentyFourHours
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: twelveHoursAgo),
                             SiteElements(domain: "mozilla")]
        populateDBHistory(with: sitesToDelete, using: profile)

        deletionWithExpectation(since: timeframe, using: profile) { returnedTimeFrame in
            XCTAssertEqual(timeframe, returnedTimeFrame)
            self.assertDBIsEmpty(with: profile, shouldSkipMetadata: true)
        }
        deleteHistoryMetadataOlderThan(dateOption: timeframe, using: profile)
    }

    func testDeletingItemsInHistoryUsingLastTwentyFourHours_WithFurtherHistory() {
        let profile = profileSetup(named: "hsd_deleteLastTwentyFourHours_WithFurtherHistory")
        guard let twelveHoursAgo = Calendar.current.date(
            byAdding: .hour,
            value: -12,
            to: Date())?.toMicrosecondsSince1970(),
              let thirtyHoursAgo = Calendar.current.date(byAdding: .hour,
                                                         value: -30,
                                                         to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .lastTwentyFourHours
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: twelveHoursAgo)]
        let sitesToRemain = [SiteElements(domain: "mozilla", timeVisited: thirtyHoursAgo)]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled(), using: profile)

        deletionWithExpectation(since: timeframe, using: profile) { returnedTimeFrame in
            XCTAssertEqual(timeframe, returnedTimeFrame)
            self.assertDBHistoryStateFor(sitesToRemain, with: profile)
        }
        deleteHistoryMetadataOlderThan(dateOption: timeframe, using: profile)
    }

    func testDeletingAllItemsInHistoryUsingLastSevenDays() {
        let profile = MockProfile(databasePrefix: "hsd_deleteLastSevenDays")
        guard let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .lastSevenDays
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: threeDaysAgo),
                             SiteElements(domain: "mozilla")]
        populateDBHistory(with: sitesToDelete,
                          using: profile,
                          skippingMetadata: true)

        deletionWithExpectation(since: timeframe, using: profile) { returnedTimeFrame in
            XCTAssertEqual(timeframe, returnedTimeFrame)
            self.assertDBIsEmpty(with: profile, shouldSkipMetadata: true)
        }
        deleteHistoryMetadataOlderThan(dateOption: timeframe, using: profile)
    }

    func testDeletingItemsInHistoryUsingLastSevenDays_WithFurtherHistory() {
        let profile = MockProfile(databasePrefix: "hsd_deleteLastSevenDays_WithFurtherHistory")
        guard let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date())?.toMicrosecondsSince1970(),
              let tenDaysAgo = Calendar.current.date(byAdding: .day,
                                                     value: -10,
                                                     to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .lastSevenDays
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: threeDaysAgo)]
        let sitesToRemain = [SiteElements(domain: "mozilla", timeVisited: tenDaysAgo)]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled(),
                          using: profile,
                          skippingMetadata: true)

        deletionWithExpectation(since: timeframe, using: profile) { returnedTimeFrame in
            XCTAssertEqual(timeframe, returnedTimeFrame)
            self.assertDBHistoryStateFor(sitesToRemain, with: profile)
        }
        deleteHistoryMetadataOlderThan(dateOption: timeframe, using: profile)
    }

    func testDeletingAllItemsInHistoryUsingLastFourWeeks() {
        let profile = MockProfile(databasePrefix: "hsd_deleteLastFourWeeks")
        guard let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .lastFourWeeks
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: twoWeeksAgo),
                             SiteElements(domain: "mozilla")]
        populateDBHistory(with: sitesToDelete,
                          using: profile,
                          skippingMetadata: true)

        deletionWithExpectation(since: timeframe, using: profile) { returnedTimeFrame in
            XCTAssertEqual(timeframe, returnedTimeFrame)
            self.assertDBIsEmpty(with: profile, shouldSkipMetadata: true)
        }
        deleteHistoryMetadataOlderThan(dateOption: timeframe, using: profile)
    }

    func testDeletingItemsInHistoryUsingLastFourWeeks_WithFurtherHistory() {
        let profile = MockProfile(databasePrefix: "hsd_deleteLastFourWeeks_WithFurtherHistory")
        guard let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date())?.toMicrosecondsSince1970(),
              let thirtyDaysAgo = Calendar.current.date(byAdding: .day,
                                                        value: -30,
                                                        to: Date())?.toMicrosecondsSince1970()
        else {
            XCTFail("Unable to create date")
            return
        }

        let timeframe: HistoryDeletionUtilityDateOptions = .lastFourWeeks
        let sitesToDelete = [SiteElements(domain: "cnn", timeVisited: twoWeeksAgo)]
        let sitesToRemain = [SiteElements(domain: "mozilla", timeVisited: thirtyDaysAgo)]
        populateDBHistory(with: (sitesToRemain + sitesToDelete).shuffled(),
                          using: profile,
                          skippingMetadata: true)

        deletionWithExpectation(since: timeframe, using: profile) { returnedTimeFrame in
            XCTAssertEqual(timeframe, returnedTimeFrame)
            self.assertDBHistoryStateFor(sitesToRemain, with: profile)
        }
        deleteHistoryMetadataOlderThan(dateOption: timeframe, using: profile)
    }

    func testDeletingAllItemsInHistoryUsingAllTime() {
        let profile = MockProfile(databasePrefix: "hsd_deleteAllTime")
        guard let earlierToday = Calendar.current.date(byAdding: .hour,
                                                       value: -5,
                                                       to: Date())?.toMicrosecondsSince1970(),
              let yesterday = Calendar.current.date(byAdding: .hour,
                                                    value: -24,
                                                    to: Date())?.toMicrosecondsSince1970(),
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
        populateDBHistory(with: sitesToDelete,
                          using: profile,
                          skippingMetadata: true)

        deletionWithExpectation(since: timeframe, using: profile) { returnedTimeFrame in
            XCTAssertEqual(timeframe, returnedTimeFrame)
            self.assertDBIsEmpty(with: profile, shouldSkipMetadata: true)
        }
        deleteHistoryMetadataOlderThan(dateOption: timeframe, using: profile)
    }
}

// MARK: - Helper functions
private extension HistoryDeletionUtilityTests {
    func profileSetup(named dbPrefix: String) -> MockProfile {
        let profile = MockProfile(databasePrefix: dbPrefix)
        profile.reopen()
        trackForMemoryLeaks(profile)

        emptyDB(with: profile)

        return profile
    }

    func deletionWithExpectation(
        for siteEntries: [String],
        using profile: MockProfile,
        completion: @escaping (Bool) -> Void
    ) {
        let deletionUtility = HistoryDeletionUtility(with: profile)
        trackForMemoryLeaks(deletionUtility)
        let expectation = expectation(description: "HistoryDeletionUtilityTest")

        deletionUtility.delete(siteEntries) { result in
            completion(result)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func deletionWithExpectation(
        since dateOption: HistoryDeletionUtilityDateOptions,
        using profile: MockProfile,
        completion: @escaping (HistoryDeletionUtilityDateOptions?) -> Void
    ) {
        let deletionUtility = HistoryDeletionUtility(with: profile)
        trackForMemoryLeaks(deletionUtility)
        let expectation = expectation(description: "HistoryDeletionUtilityTest")

        deletionUtility.deleteHistoryFrom(dateOption) { time in
            completion(time)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func deleteHistoryMetadataOlderThan(dateOption: HistoryDeletionUtilityDateOptions,
                                        using profile: MockProfile) {
        let deletionUtility = HistoryDeletionUtility(with: profile)
        trackForMemoryLeaks(deletionUtility)
        deletionUtility.deleteHistoryMetadataOlderThan(dateOption)
        let emptyResultsRead = profile.places.getHistoryMetadataSince(
            since: deletionUtility.deletionReferenceValue(for: dateOption)
        ).value
        XCTAssertTrue(emptyResultsRead.isSuccess)
        XCTAssertNotNil(emptyResultsRead.successValue)
        XCTAssertEqual(emptyResultsRead.successValue!.count, 0)
    }

    func emptyDB(
        with profile: MockProfile,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            profile.places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess,
            file: file,
            line: line
        )
        XCTAssertTrue(
            profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess,
            file: file,
            line: line
        )
        XCTAssertTrue(
            profile.places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess,
            file: file,
            line: line
        )

        XCTAssertTrue(
            profile.places.deleteVisitsBetween(Date(timeIntervalSince1970: 0)).value.isSuccess,
            file: file,
            line: line
        )
    }

    // `shouldSkipMetadata` is a  parameter to deal with the case where AS doesn't allow
    // for entering a custom date for metadata. If this is set to `true`, then the
    // metadata check will not run, and only the history check will run.
    func assertDBIsEmpty(
        with profile: MockProfile,
        shouldSkipMetadata: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        if !shouldSkipMetadata { assertMetadataIsEmpty(with: profile, file: file, line: line) }
        assertHistoryIsEmpty(with: profile, file: file, line: line)
    }

    func assertMetadataIsEmpty(
        with profile: MockProfile,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let emptyMetadata = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(emptyMetadata.isSuccess, file: file, line: line)
        XCTAssertNotNil(emptyMetadata.successValue, file: file, line: line)
        XCTAssertEqual(emptyMetadata.successValue!.count, 0, "Metadata", file: file, line: line)
    }

    func assertHistoryIsEmpty(
        with profile: MockProfile,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let emptyHistory = profile.places.getSitesWithBound(
            limit: 100,
            offset: 0,
            excludedTypes: VisitTransitionSet(0)
        ).value
        XCTAssertTrue(emptyHistory.isSuccess, file: file, line: line)
        XCTAssertNotNil(emptyHistory.successValue, file: file, line: line)
        XCTAssertEqual(
            emptyHistory.successValue!.count,
            0,
            "History",
            file: file,
            line: line
        )
    }

    func assertDBStateFor(
        _ sites: [SiteElements],
        with profile: MockProfile,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        assertDBMetadataStateFor(sites, with: profile)
        assertDBHistoryStateFor(sites, with: profile)
    }

    func assertDBMetadataStateFor(
        _ sites: [SiteElements],
        with profile: MockProfile,
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

            XCTAssertEqual(
                metadataURL,
                "https://www.\(site.domain).com/\(site.path)",
                file: file,
                line: line
            )
            XCTAssertEqual(metadataTitle, "\(site.domain) test", file: file, line: line)
            XCTAssertEqual(
                metadataItems.successValue![index].documentType,
                DocumentType.regular,
                file: file,
                line: line
            )
            XCTAssertEqual(
                metadataItems.successValue![index].totalViewTime,
                1,
                file: file,
                line: line
            )
        }
    }

    func assertDBHistoryStateFor(
        _ sites: [SiteElements],
        with profile: MockProfile,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let historyItems = profile.places.getSitesWithBound(
            limit: 100,
            offset: 0,
            excludedTypes: VisitTransitionSet(0)
        ).value
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
        using profile: MockProfile,
        skippingMetadata shouldSkipMetadata: Bool = false,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        entries.forEach { entry in
            let site = createWebsiteFor(domain: entry.domain, with: entry.path)
            addToLocalHistory(site: site, timeVisited: entry.timeVisited, with: profile)

            if !shouldSkipMetadata {
                setupMetadataItem(forTestURL: site.url,
                                  withTitle: site.title,
                                  andViewTime: 1,
                                  with: profile,
                                  file: file,
                                  line: line)
            }
        }
    }

    func createWebsiteFor(domain name: String, with path: String = "") -> Site {
        let urlString = "https://www.\(name).com/\(path)"
        let urlTitle = "\(name) test"

        return Site.createBasicSite(url: urlString, title: urlTitle)
    }

    func addToLocalHistory(
        site: Site,
        timeVisited: MicrosecondTimestamp,
        with profile: MockProfile,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let visit = VisitObservation(url: site.url, title: site.title, visitType: .link, at: Int64(timeVisited) / 1000)
        let applied = profile.places.applyObservation(visitObservation: visit).value
        XCTAssertTrue(applied.isSuccess, "Site added: \(site.url).", file: file, line: line)
    }

    func setupMetadataItem(
        forTestURL siteURL: String,
        withTitle title: String,
        andViewTime viewTime: Int32,
        with profile: MockProfile,
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
            )).value.isSuccess,
                      "Metadata observation: title",
                      file: file,
                      line: line)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: viewTime,
                documentType: nil,
                title: nil
            )).value.isSuccess,
                      "Metadata observation: view time",
                      file: file,
                      line: line)

        XCTAssertTrue(profile.places.noteHistoryMetadataObservation(
            key: metadataKey1,
            observation: HistoryMetadataObservation(
                url: metadataKey1.url,
                viewTime: nil,
                documentType: .regular,
                title: nil
            )).value.isSuccess,
                      "Metadata observation: document type",
                      file: file,
                      line: line)
    }
}
