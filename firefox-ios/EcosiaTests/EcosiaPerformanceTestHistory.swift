// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/**
 * EcosiaPerformanceTestHistory
 *
 * Context:
 * As part of PR #731, we addressed an issue with blank migrated tabs during an upgrade. While the issue was fixed for new upgrades, users who had already upgraded continued to experience this problem. This class was created to ensure that tabs without URLs can be restored by fetching the URLs from an alternative source, specifically the places database (`places.db`).
 *
 * This class extends `ProfileTest` and is designed to test the performance of the `getSitesWithBound` function
 * in the `RustPlaces` API. It performs a series of performance tests with different limits and numbers of entries
 * in the database to measure and analyze execution times.
 *
 * Approach inspired by `TestHistory.swift`:
 * The class contains helper methods gotten from the above mentioned class:
 * - It can add either individual or multiple site entries into the database, facilitating bulk data insertion for testing purposes.
 * - It includes a method to clear the database, ensuring a clean state before each test run.
 * - The core testing function measures and logs the performance of the `getSitesWithBound` function under varying conditions.
 *
 * Each test method is tailored to a specific combination of limit and entry count.
 */

@testable import Client
import Foundation
import Storage
import MozillaAppServices
import XCTest

final class EcosiaPerformanceTestHistory: ProfileTest {

    private func addSite(_ places: RustPlaces, url: String, title: String, bool: Bool = true, visitType: VisitType = .link) {
        _ = places.reopenIfClosed()
        let site = Site(url: url, title: title)
        let visit = VisitObservation(url: site.url, title: site.title, visitType: visitType)
        let res = places.applyObservation(visitObservation: visit).value
        XCTAssertEqual(bool, res.isSuccess, "Site added: \(url)., error value: \(res.failureValue ?? "wow")")
    }

    private func addSites(_ places: RustPlaces, count: Int) {
        for index in 0..<count {
            self.addSite(places, url: "https://example\(index).com/", title: "Title \(index)")
        }
    }

    private func clear(_ places: RustPlaces) {
        XCTAssertTrue(places.deleteEverythingHistory().value.isSuccess, "History cleared.")
    }

    // Function to test getSitesWithBound performance
    fileprivate func testGetSitesWithBoundPerformance(limit: Int, entries: Int) {
        withTestProfile { profile in
            let places = profile.places

            // Add the specified number of sites
            self.addSites(places, count: entries)

            self.measure {
                let expectation = self.expectation(description: "getSitesWithBound completes")

                let startTime = Date()

                let deferred = places.getSitesWithBound(limit: limit, offset: 0, excludedTypes: VisitTransitionSet(0))
                deferred.upon { cursorResult in
                    let endTime = Date()
                    let duration = endTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds

                    switch cursorResult {
                    case .success(let cursor):
                        XCTAssertGreaterThan(cursor.count, 0, "No sites were retrieved")
                    case .failure(let error):
                        XCTFail("Failed to retrieve sites: \(error)")
                    }

                    expectation.fulfill()
                }

                self.waitForExpectations(timeout: 10.0, handler: nil)
            }

            self.clear(places)
        }
    }

    // Tests for each row in the table
    func testGetSitesWithBoundPerformance_Limit100_500Entries() {
        testGetSitesWithBoundPerformance(limit: 100, entries: 500)
    }

    func testGetSitesWithBoundPerformance_Limit400_500Entries() {
        testGetSitesWithBoundPerformance(limit: 400, entries: 500)
    }

    func testGetSitesWithBoundPerformance_Limit600_500Entries() {
        testGetSitesWithBoundPerformance(limit: 600, entries: 500)
    }

    func testGetSitesWithBoundPerformance_Limit1000_500Entries() {
        testGetSitesWithBoundPerformance(limit: 1000, entries: 500)
    }

    func testGetSitesWithBoundPerformance_Limit100_1000Entries() {
        testGetSitesWithBoundPerformance(limit: 100, entries: 1000)
    }

    func testGetSitesWithBoundPerformance_Limit400_1000Entries() {
        testGetSitesWithBoundPerformance(limit: 400, entries: 1000)
    }

    func testGetSitesWithBoundPerformance_Limit600_1000Entries() {
        testGetSitesWithBoundPerformance(limit: 600, entries: 1000)
    }

    func testGetSitesWithBoundPerformance_Limit1000_1000Entries() {
        testGetSitesWithBoundPerformance(limit: 1000, entries: 1000)
    }
}
