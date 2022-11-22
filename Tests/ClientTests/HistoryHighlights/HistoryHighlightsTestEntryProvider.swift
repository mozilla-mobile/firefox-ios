// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client
import XCTest

class HistoryHighlightsTestEntryProvider {
    private var profile: MockProfile!
    private var tabManager: TabManager!

    init(with profile: MockProfile, and tabManager: TabManager) {
        self.profile = profile
        self.tabManager = tabManager
    }

    func emptyDB() {
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: 0).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: INT64_MAX).value.isSuccess)
        XCTAssertTrue(profile.places.deleteHistoryMetadataOlderThan(olderThan: -1).value.isSuccess)
    }

    func createHistoryEntry(siteEntry: [(String, String)]) {
        for (siteText, suffix) in siteEntry {
            let site = createWebsiteEntry(named: siteText, with: suffix)
            add(site: site)
            setupData(forTestURL: site.url, withTitle: site.title, andViewTime: 1)
        }
    }

    func setupData(forTestURL siteURL: String, withTitle title: String, andViewTime viewTime: Int32) {
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

    // MARK: - Helper methods

    private func add(site: Site) {
        let visit = VisitObservation(url: site.url, title: site.title, visitType: nil)
        XCTAssertTrue(profile.places.applyObservation(visitObservation: visit).value.isSuccess, "Site added: \(site.url).")
    }

    private func createWebsiteEntry(named name: String, with sufix: String = "") -> Site {
        let urlString = "https://www.\(name).com/\(sufix)"
        let urlTitle = "\(name) test"

        return Site(url: urlString, title: urlTitle)
    }

    func createTabs(named name: String) -> Tab {
        guard let url = URL(string: "https://www.\(name).com/") else {
            return tabManager.addTab()
        }

        let urlRequest = URLRequest(url: url)
        return tabManager.addTab(urlRequest)
    }
}
