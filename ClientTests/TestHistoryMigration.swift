/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest
@testable import Client
import Foundation
import Storage
import Core

class TestHistoryMigration: TestHistory {

    func testEcosiaImportHistory() {
        let url = URL(string:"https://ecosia.org")!

        withTestProfile { profile in
            let items = [(Date(), Core.Page(url: url, title: "Ecosia"))]
            EcosiaHistory.migrateLowLevel(items, to: profile) { _ in }
            self.checkVisits(profile.history, url: url.absoluteString)
        }
    }

    func testEcosiaHistoryPrepare() {
        let urls = [URL(string:"https://apple.com")!,
                    URL(string:"https://ecosia.org")!,
                    URL(string:"https://ecosia.org/blog")!,
                    URL(string:"https://ecosia.org/blog")!]

        let items = urls.map{ (Date(), Core.Page(url: $0, title: "Ecosia")) }
        let data = EcosiaHistory.prepare(history: items)
        XCTAssert(data.domains["apple.com"] == 1)
        XCTAssert(data.domains["ecosia.org"] == 2)
        XCTAssert(data.domains.count == 2)
        XCTAssert(data.sites.count == 3)
        XCTAssert(data.visits.count == 4)
    }

}
