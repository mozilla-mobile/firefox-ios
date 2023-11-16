// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Common
@testable import Client

final class FakespotHighlightsCardViewModelTests: XCTestCase {
    func testShowMore_MultipleGroups() {
        var highlights = [FakespotHighlightGroup]()
        highlights.append(createGroup(type: .price, numberOfReviews: 2))
        highlights.append(createGroup(type: .packaging, numberOfReviews: 2))
        let viewModel = FakespotHighlightsCardViewModel(highlights: highlights)

        XCTAssertEqual(viewModel.shouldShowMoreButton, true)
        XCTAssertEqual(viewModel.shouldShowFadeInPreview, true)
    }

    func testShowMore_OneGroupMultipleReviews() {
        var highlights = [FakespotHighlightGroup]()
        highlights.append(createGroup(type: .price, numberOfReviews: 2))
        let viewModel = FakespotHighlightsCardViewModel(highlights: highlights)

        XCTAssertEqual(viewModel.shouldShowMoreButton, true)
        XCTAssertEqual(viewModel.shouldShowFadeInPreview, true)
    }

    func testShowMore_OneGroupOneReviews() {
        var highlights = [FakespotHighlightGroup]()
        highlights.append(createGroup(type: .price, numberOfReviews: 1))
        let viewModel = FakespotHighlightsCardViewModel(highlights: highlights)

        XCTAssertEqual(viewModel.shouldShowMoreButton, false)
        XCTAssertEqual(viewModel.shouldShowFadeInPreview, false)
    }

    func testShowMore_MultipleGroupsOneReviews() {
        var highlights = [FakespotHighlightGroup]()
        highlights.append(createGroup(type: .price, numberOfReviews: 1))
        highlights.append(createGroup(type: .packaging, numberOfReviews: 1))
        let viewModel = FakespotHighlightsCardViewModel(highlights: highlights)

        XCTAssertEqual(viewModel.shouldShowMoreButton, true)
        XCTAssertEqual(viewModel.shouldShowFadeInPreview, true)
    }

    // Helper
    func createGroup(type: FakespotHighlightType, numberOfReviews: Int) -> FakespotHighlightGroup {
        var reviews = [String]()

        for index in 1...numberOfReviews {
            reviews.append("Lorum ipsum \(index)")
        }

        return FakespotHighlightGroup(type: type, reviews: reviews)
    }
}
