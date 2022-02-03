// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client
@testable import Storage

class HistoryHighlightsTests: XCTestCase {
    typealias manager = HistoryHighlightsManager

    var profile: MockProfile!
    var tabManager: TabManager!

    override func setUp() {
        profile = MockProfile(databasePrefix: "historyHighlights_tests")
        tabManager = TabManager(profile: profile, imageStore: nil)
    }

    override func tearDown() {
        profile = nil
        tabManager = nil
    }

    func testEmptyRead() {
        emptyDB()

        let emptyRead = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(emptyRead.isSuccess)
        XCTAssertNotNil(emptyRead.successValue)
        XCTAssertEqual(emptyRead.successValue!.count, 0)
    }

    func testSingleDataExists() {
        emptyDB()
        setupData(forTestURL: "https://www.mozilla.com", withTitle: "Mozilla Test", andViewTime: 1)

        let singleItemRead = profile.places.getHistoryMetadataSince(since: 0).value
        XCTAssertTrue(singleItemRead.isSuccess)
        XCTAssertNotNil(singleItemRead.successValue)
        XCTAssertEqual(singleItemRead.successValue!.count, 1)
        XCTAssertEqual(singleItemRead.successValue![0].title, "Mozilla Test")
        XCTAssertEqual(singleItemRead.successValue![0].documentType, DocumentType.regular)
        XCTAssertEqual(singleItemRead.successValue![0].totalViewTime, 1)
    }

    func testHistoryHighlightsDontExist() {
        emptyDB()

        let expectation = expectation(description: "Highlights")

        manager.getHighlightsData(with: profile, and: [Tab]()) { highlights in
            XCTAssertNil(highlights, "Highlights should be nil if the DB is empty")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlightExists() {
        emptyDB()

        let testSites = ["mozilla", "wikipedia", "amazon"]

        for siteText in testSites {
            let site = createWebsiteEntry(named: siteText)
            add(site: site)
            setupData(forTestURL: site.url, withTitle: site.title, andViewTime: 1)
        }

        let expectation = expectation(description: "Highlights")
        let expectedCount = 3

        manager.getHighlightsData(with: profile, and: [Tab]()) { highlights in

            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be one history highlight")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlightExists_RemovingExistingTab() {
        emptyDB()

        let testSites = ["mozilla", "wikipedia", "amazon"]

        for siteText in testSites {
            let site = createWebsiteEntry(named: siteText)
            add(site: site)
            setupData(forTestURL: site.url, withTitle: site.title, andViewTime: 1)
        }

        let tabs = createTabs(named: "mozilla")

        let expectation = expectation(description: "Highlights")
        let expectedCount = 2

        manager.getHighlightsData(with: profile, and: [tabs]) { highlights in

            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be one history highlight")
            XCTAssertEqual(highlights.count, expectedCount, "There should be one history highlight")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }

    func testSingleHistoryHighlightExists_withGroupingEnabled() {
        emptyDB()

        let testSites = [("mozilla", ""),
                         ("wikipedia", ""),
                         ("amazon", ""),
                         ("mozilla", "redirect"),
                         ("amazon", "redirect")]

        for (domain, suffix) in testSites {
            let site = createWebsiteEntry(named: domain, with: suffix)
            add(site: site)
            setupData(forTestURL: site.url, withTitle: site.title, andViewTime: 1)
        }

        let expectation = expectation(description: "Highlights")
        let expectedCount = 2

        manager.getHighlightsData(with: profile, and: [Tab](), shouldGroupHighlights: true) { highlights in

            guard let highlights = highlights else {
                XCTFail("Highlights should not be nil.")
                return
            }

            XCTAssertEqual(highlights.count, expectedCount, "There should be one history highlight")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5, handler: nil)
    }


    // MARK: - Helper functions

    private func emptyDB() {
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess)
    }

    private func createWebsiteEntry(named name: String, with sufix: String = "") -> Site {
        let urlString = "https://www.\(name).com\(sufix)"
        let urlTitle = "\(name) test"

        return Site(url: urlString, title: urlTitle)
    }

    private func createTabs(named name: String) -> Tab {
        guard let url = URL(string:"https://www.\(name).com") else {
            return tabManager.addTab()
        }

        let urlRequest = URLRequest(url: url)
        return tabManager.addTab(urlRequest)
    }

    private func setupData(forTestURL siteURL: String, withTitle title: String, andViewTime viewTime: Int32) {
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

    private func add(site: Site) {
        let visit = SiteVisit(site: site, date: Date.nowMicroseconds())
        XCTAssertTrue(profile.history.addLocalVisit(visit).value.isSuccess, "Site added: \(site.url).")
    }
}
