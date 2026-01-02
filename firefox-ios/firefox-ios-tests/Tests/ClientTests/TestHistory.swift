// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Storage
import XCTest

@testable import Client

@MainActor
class TestHistory: XCTestCase {
    var profile: MockProfile!
    let numThreads = 5

    override func setUp() async throws {
        try await super.setUp()
        continueAfterFailure = false

        // Setup mock profile
        profile = MockProfile(databasePrefix: "history-test")
        profile.reopen()
    }

    override func tearDown() async throws {
        self.clear(profile.places)
        profile.shutdown()
        profile = nil
        try await super.tearDown()
    }

    // This is a very basic test. Adds an entry, retrieves it, and then clears the database.
    func testHistory() {
        let helper = TestHistoryHelper()
        let places = profile.places
        // Add 5 sites
        let numSites = 5
        var siteDictionary: [String: String] = [:]
        for i in 0..<numSites {
            let newSite = (url: "http://url\(i)/", title: "title \(i)")
            siteDictionary[newSite.url] = newSite.title
            helper.addSite(places, url: newSite.url, title: newSite.title)
        }

        // Test
        self.checkSites(places, urls: siteDictionary)
        for entry in siteDictionary {
            self.checkVisits(places, url: entry.key)
        }
    }

    func testSearchHistory_WithResults() {
        let helper = TestHistoryHelper()
        let expectation = self.expectation(description: "Wait for search history")
        let places = profile.places

        helper.addSite(places, url: "http://amazon.com/", title: "Amazon")
        helper.addSite(places, url: "http://mozilla.org/", title: "Mozilla")
        helper.addSite(places, url: "https://apple.com/", title: "Apple")
        helper.addSite(places, url: "https://apple.developer.com/", title: "Apple Developer")

        places.queryAutocomplete(matchingSearchQuery: "App", limit: 25).upon { result in
            XCTAssertTrue(result.isSuccess)
            let results = result.successValue!
            XCTAssertEqual(results.count, 2)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testSearchHistory_WithResultsByTitle() {
        let helper = TestHistoryHelper()
        let expectation = self.expectation(description: "Wait for search history")

        let places = profile.places
        helper.addSite(places, url: "http://amazon.com/", title: "Amazon")
        helper.addSite(places, url: "http://mozilla.org/", title: "Mozilla internet")
        helper.addSite(places, url: "http://mozilla.dev.org/", title: "Internet dev")
        helper.addSite(places, url: "https://apple.com/", title: "Apple")

        places.queryAutocomplete(matchingSearchQuery: "int", limit: 25).upon { result in
            XCTAssertTrue(result.isSuccess)
            let results = result.successValue!
            XCTAssertEqual(results.count, 2)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testSearchHistory_WithResultsByUrl() {
        let helper = TestHistoryHelper()
        let expectation = self.expectation(description: "Wait for search history")
        let places = profile.places
        helper.addSite(places, url: "http://amazon.com/", title: "Amazon")
        helper.addSite(places, url: "http://mozilla.developer.org/", title: "Mozilla")
        helper.addSite(places, url: "https://apple.developer.com/", title: "Apple")

        places.queryAutocomplete(matchingSearchQuery: "dev", limit: 25).upon { result in
            XCTAssertTrue(result.isSuccess)
            let results = result.successValue!
            XCTAssertEqual(results.count, 2)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 10, handler: nil)
    }

    func testSearchHistory_NoResults() {
        let helper = TestHistoryHelper()
        let expectation = self.expectation(description: "Wait for search history")
        let places = profile.places
        helper.addSite(places, url: "http://amazon.com/", title: "Amazon")
        helper.addSite(places, url: "http://mozilla.org/", title: "Mozilla internet")
        helper.addSite(places, url: "https://apple.com/", title: "Apple")

        places.queryAutocomplete(matchingSearchQuery: "red", limit: 25).upon { result in
            XCTAssertTrue(result.isSuccess)
            let results = result.successValue!
            XCTAssertEqual(results.count, 0)
            expectation.fulfill()
        }

        self.waitForExpectations(timeout: 100, handler: nil)
    }

    // TODO: Renable as part of fix for FXIOS-8904
//    // Test different visit types and their conversions
//    func testVisitTypes() {
//        withTestProfile { profile -> Void in
//            let places = profile.places
//            self.addSite(
//                places,
//                url: "http://url1/",
//                title: "title 1",
//                visitType: .link
//            )
//            self.addSite(
//                places,
//                url: "http://url2/",
//                title: "title 2",
//                visitType: .bookmark
//            )
//            self.addSite(
//                places,
//                url: "http://url3/",
//                title: "title 3",
//                visitType: .reload
//            )
//
//            if let cursor = places.getSitesWithBound(
//                limit: 100,
//                offset: 0,
//                excludedTypes: VisitTransitionSet(0)
//            ).value.successValue {
//                XCTAssertEqual(
//                    cursor.status,
//                    CursorStatus.success,
//                    "Returned success \(cursor.statusMessage)."
//                )
//                XCTAssertEqual(cursor.count, 3)
//
//                // Sites will be in order of latest visited (so url3)
//                var site = cursor[0]!
//                XCTAssertEqual(site.title, "title 3")
//                XCTAssertEqual(site.url, "http://url3/")
//                var visitType = site.latestVisit!.type
//                XCTAssertEqual(visitType, .reload)
//                XCTAssertEqual(visitType.rawValue, 9)
//
//                site = cursor[1]!
//                XCTAssertEqual(site.title, "title 2")
//                XCTAssertEqual(site.url, "http://url2/")
//                visitType = site.latestVisit!.type
//                XCTAssertEqual(visitType, .bookmark)
//                XCTAssertEqual(visitType.rawValue, 3)
//
//                site = cursor[2]!
//                XCTAssertEqual(site.title, "title 1")
//                XCTAssertEqual(site.url, "http://url1/")
//                visitType = site.latestVisit!.type
//                XCTAssertEqual(visitType, .link)
//                XCTAssertEqual(visitType.rawValue, 1)
//            } else {
//                XCTFail("Couldn't get cursor.")
//            }
//            self.clear(places)
//        }
//    }

    func testAboutUrls() {
        let helper = TestHistoryHelper()
        let places = profile.places
        helper.addSite(
            places,
            url: "about:home",
            title: "About Home"
        )
        self.clear(places)
    }

    func testGetPerformance() {
        let helper = TestHistoryHelper()
        let places = profile.places
        var index = 0
        var urls = [String: String]()

        for _ in 0..<helper.numCmds {
            helper.addSite(
                places,
                url: "https://someurl\(index).com/",
                title: "title \(index)"
            )
            urls["https://someurl\(index).com/"] = "title \(index)"
            index += 1
        }

        self.measure({ () in
            self.checkSites(places, urls: urls)
            return
        })
    }

    // Fuzzing tests. These fire random insert/query/clear commands into the history database from threads.
    // The don't check the results. Just look for crashes.
    func testRandomThreading() throws {
        throw XCTSkip("Skipping this test since https://mozilla-hub.atlassian.net/browse/FXIOS-12339")
//        let queue = DispatchQueue(
//            label: "My Queue",
//            qos: DispatchQoS.default,
//            attributes: DispatchQueue.Attributes.concurrent,
//            autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
//            target: nil
//        )
//        var counter = 0
//
//        let expectation = self.expectation(description: "Wait for history")
//        for _ in 0..<self.numThreads {
//            var places = profile.places
//            self.runRandom(&places, queue: queue, completion: { () in
//                counter += 1
//                if counter == self.numThreads {
//                    self.profile.places.deleteEverythingHistory().uponQueue(.global()) { result in
//                        XCTAssertTrue(result.isSuccess, "History cleared.")
//                        expectation .fulfill()
//                    }
//                }
//            })
//        }
//        self.waitForExpectations(timeout: 10, handler: nil)
    }

    // Same as testRandomThreading, but uses one history connection for all threads
    func testRandomThreading2() {
        let helper = TestHistoryHelper()
        let queue = DispatchQueue(
            label: "My Queue",
            qos: DispatchQoS.default,
            attributes: DispatchQueue.Attributes.concurrent,
            autoreleaseFrequency: DispatchQueue.AutoreleaseFrequency.inherit,
            target: nil
        )
        var places = profile.places
        nonisolated(unsafe) var counter = 0

        let expectation = expectation(description: "Wait for history")
        for _ in 0..<self.numThreads {
            helper.runRandom(&places, queue: queue, completion: { [numThreads] () in
                counter += 1
                if counter == numThreads {
                    expectation.fulfill()
                }
            })
        }
        self.waitForExpectations(timeout: 10, handler: nil)
    }

    // MARK: - Private helper

    private func checkSites(
        _ places: RustPlaces,
        urls: [String: String]
    ) {
        // Retrieve the entry.
        if let cursor = places.getSitesWithBound(
            limit: 100,
            offset: 0,
            excludedTypes: VisitTransitionSet(0)
        ).value.successValue {
            XCTAssertEqual(cursor.status, CursorStatus.success, "Returned success \(cursor.statusMessage).")
            XCTAssertEqual(cursor.count, urls.count, "Cursor has \(cursor.count) entries. Duplicates are filtered out.")

            for index in 0..<cursor.count {
                guard let site = cursor[index] else {
                    XCTFail("Cursor has a site for entry.")
                    return
                }

                guard let title = urls[site.url] else {
                    XCTFail("Bad test input data")
                    return
                }

                XCTAssertEqual(site.title, title)
            }
        } else {
            XCTFail("Couldn't get cursor.")
        }
    }

    private func clear(_ places: RustPlaces) {
        let expectation = expectation(description: "Wait for clear history")

        profile.places.deleteEverythingHistory().uponQueue(.global()) { result in
            expectation .fulfill()
            XCTAssertTrue(result.isSuccess, "History cleared.")
        }

        waitForExpectations(timeout: 10)
    }

    private func checkVisits(_ places: RustPlaces, url: String) {
        let expectation = expectation(description: "Wait for history")
        places.getSitesWithBound(limit: 100, offset: 0, excludedTypes: VisitTransitionSet(0)).upon { result in
            XCTAssertTrue(result.isSuccess)
            places.queryAutocomplete(matchingSearchQuery: url, limit: 100).upon { result in
                XCTAssertTrue(result.isSuccess)
                // XXX - We don't allow querying much info about visits here anymore, so there isn't a lot to do
                expectation.fulfill()
            }
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
}

struct TestHistoryHelper {
    let numCmds = 10

    // Runs a random command on a database. Calls cb when finished.
    func runRandom(
        _ places: inout RustPlaces,
        cmdIn: Int,
        completion: @escaping @Sendable () -> Void
    ) {
        var cmd = cmdIn
        if cmd < 0 {
            cmd = Int(arc4random() % 5)
        }

        switch cmd {
        case 0...1:
            let url = "https://randomurl.com/\(arc4random() % 100)"
            let title = "title \(arc4random() % 100)"
            addSite(places, url: url, title: title)
            completion()
        case 2...3:
            innerCheckSites(places) { cursor in
                for site in cursor {
                    _ = site!
                }
            }
            completion()
        default:
            places.deleteEverythingHistory().upon { success in completion() }
        }
    }

    // Calls numCmds random methods on this database. val is a counter used by
    // this internally (i.e. always pass zero for it). Calls cb when finished.
    private func runMultiRandom(
        _ places: inout RustPlaces,
        val: Int,
        numCmds: Int,
        completion: @escaping @Sendable () -> Void
    ) {
        if val == numCmds {
            completion()
            return
        } else {
            runRandom(&places, cmdIn: -1) { [places] in
                var places = places
                self.runMultiRandom(&places, val: val+1, numCmds: numCmds, completion: completion)
            }
        }
    }

    // Helper for starting a new thread running NumCmds random methods on it. Calls cb when done.
    func runRandom(
        _ places: inout RustPlaces,
        queue: DispatchQueue,
        completion: @escaping @Sendable () -> Void
    ) {
        queue.async { [places, numCmds] in
            var places = places
            // Each thread creates its own history provider
            self.runMultiRandom(&places, val: 0, numCmds: numCmds) {
                DispatchQueue.main.async(execute: completion)
            }
        }
    }

    func addSite(
        _ places: RustPlaces,
        url: String,
        title: String,
        bool: Bool = true,
        visitType: VisitType = .link
    ) {
        _ = places.reopenIfClosed()
        let site = Site.createBasicSite(url: url, title: title)
        let visit = VisitObservation(url: site.url, title: site.title, visitType: visitType)
        let res = places.applyObservation(visitObservation: visit).value
        XCTAssertEqual(
            bool,
            res.isSuccess,
            "Site added: \(url)., error value: \(res.failureValue ?? "wow")"
        )
    }

    private func innerCheckSites(_ places: RustPlaces, callback: @escaping @Sendable (_ cursor: Cursor<Site>) -> Void) {
        // Retrieve the entry
        places.getSitesWithBound(limit: 100, offset: 0, excludedTypes: VisitTransitionSet(0)).upon {
            do {
                XCTAssertTrue($0.isSuccess)
                let successValue = try XCTUnwrap($0.successValue)
                callback(successValue)
            } catch {
                XCTFail("Should not receive a nil successValue")
                callback(Cursor<Site>())
            }
        }
    }
}
