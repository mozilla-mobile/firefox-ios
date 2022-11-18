// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Core
@testable import Client


class EcosiaNTPNewsViewModelTests: XCTestCase {

    func testFilterItems() throws {
        let filterTerm = "filter_me_out"
        let anyUrl = URL(string:  "https://ecosia.org")!
        let model1 = NewsModel(id: 1, text: "", language: .en, publishDate: .init(), imageUrl: anyUrl, targetUrl: anyUrl, trackingName: filterTerm)
        let model2 = NewsModel(id: 2, text: "", language: .en, publishDate: .init(), imageUrl: anyUrl, targetUrl: anyUrl, trackingName: "foo")

        let items = [model1, model2].map { NewsCell.ViewModel(model: $0, promo: nil)
        }

        let filteredItems = NTPNewsViewModel.filter(items: items, excluding: filterTerm)
        XCTAssertTrue(filteredItems.count == 1)
        XCTAssertTrue(filteredItems.first!.trackingName != filterTerm)
        XCTAssertTrue(filteredItems.first!.trackingName == "foo")
    }
}
