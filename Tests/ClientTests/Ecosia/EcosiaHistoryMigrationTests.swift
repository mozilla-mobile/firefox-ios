/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Client
import Foundation
import Storage
import Core

class EcosiaHistoryMigrationTests: TestHistory {

    func testImportHistory() {
        let url = URL(string:"https://ecosia.org")!

        withTestProfile { profile in
            let items = [(Date(), Core.Page(url: url, title: "Ecosia"))]
            EcosiaHistory.migrate(items, to: profile) { _ in }
            self.checkVisits(profile.history, url: url.absoluteString)
        }
    }

    func testHistoryPrepare() {
        let urls = [URL(string:"https://apple.com")!,
                    URL(string:"https://ecosia.org")!,
                    URL(string:"https://ecosia.org/blog")!,
                    URL(string:"https://ecosia.org/blog")!,
                    URL(string:"https://www.ecosia.org/blog")!]

        let items = urls.map { (Date(), Core.Page(url: $0, title: "Ecosia")) }
        let data = EcosiaHistory.prepare(history: items)
        XCTAssert(data.domains.count == 2)
        XCTAssert(data.domains["apple.com"] == 1)
        XCTAssert(data.domains["ecosia.org"] == 2)

        XCTAssert(data.sites.count == 4)
        XCTAssert(data.sites.first(where: {$0.0.url == "https://apple.com" })!.1 == 1)
        XCTAssert(data.sites.first(where: {$0.0.url == "https://ecosia.org" })!.1 == 2)
        XCTAssert(data.sites.first(where: {$0.0.url == "https://ecosia.org/blog" })!.1 == 2)
        XCTAssert(data.sites.first(where: {$0.0.url == "https://www.ecosia.org/blog" })!.1 == 2)

        XCTAssert(data.visits.count == 5)
        XCTAssert(data.visits[0].1 == 1)
        XCTAssert(data.visits[1].1 == 2)
        XCTAssert(data.visits[2].1 == 3)
        XCTAssert(data.visits[3].1 == 3)
        XCTAssert(data.visits[4].1 == 4)
    }

    func testImportFailureDescription() {
        let singleFailure = EcosiaImport.Failure(reasons: ["Reason 1"])
        XCTAssertEqual(singleFailure.description, "Reason 1")

        let fourFailures = EcosiaImport.Failure(reasons: ["Reason 1", "Reason 2", "Reason 3", "Reason 4"])
        let cappedDescription = fourFailures.description
        XCTAssertEqual(cappedDescription, "Reason 1 / Reason 2 / Reason 3")
    }


    func testHistoryCap() {
        let urls = [URL(string:"https://apple.com")!,
                    URL(string:"https://ecosia.org")!,
                    URL(string:"https://ecosia.org/blog")!,
                    URL(string:"https://ecosia.org/blog")!,
                    URL(string:"https://www.ecosia.org/blog")!]

        var items: [(Date, Core.Page)] = []
        for (i, url) in urls.enumerated() {
            let item = (Date(timeIntervalSinceNow: Double(-i * 24 * 60 * 60)), Core.Page(url: url, title: "Ecosia"))
            items.append(item)
        }

        let lastDay = EcosiaHistory.cap(items, for: 1)
        XCTAssert(lastDay.count == 1)
        XCTAssert(lastDay.first!.1.url.absoluteString == "https://apple.com")

        let last2Days = EcosiaHistory.cap(items, for: 2)
        XCTAssert(last2Days.count == 2)

        let allDays = EcosiaHistory.cap(items, for: 5)
        XCTAssert(allDays.count == 5)
    }

}
