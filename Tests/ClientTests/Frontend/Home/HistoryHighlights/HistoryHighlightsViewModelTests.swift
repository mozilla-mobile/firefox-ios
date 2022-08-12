// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import MozillaAppServices

class HistoryHighlightsViewModelTests: XCTestCase {

    private var sut: HistoryHighlightsViewModel!
    private var profile: MockProfile!
    private var tabManager: MockTabManager!
    private var dataAdaptor: MockHistoryHighlightsDataAdaptor!
    override func setUp() {
        super.setUp()

        profile = MockProfile()
        tabManager = MockTabManager()
        dataAdaptor = MockHistoryHighlightsDataAdaptor()
        sut = HistoryHighlightsViewModel(
            with: profile,
            isPrivate: false,
            tabManager: tabManager,
            urlBar: URLBarView(profile: profile),
            historyHighlightsDataAdaptor: dataAdaptor)
    }

    override func tearDown() {
        super.tearDown()

        profile = nil
        tabManager = nil
        dataAdaptor = nil
        sut = nil
    }

    func testGetItems_isMozilla() {
        let item1: HighlightItem = HistoryHighlight(
            score: 0,
            placeId: 0,
            url: "",
            title: "mozilla",
            previewImageUrl: "")
        dataAdaptor.mockHistoryItems = [item1]

        sut.didLoadNewData()

        XCTAssertEqual(sut.getItemDetailsAt(index: 0)?.displayTitle, "mozilla")
    }
}
