// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

class PocketStoryProviderTests: XCTestCase, FeatureFlaggable {
    var subject: StoryProvider!

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    func tesFetchingStories_ReturnsList() async {
        let stories: [RecommendationDataItem] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        subject = StoryProvider(
            merinoAPI: MockMerinoAPI(result: .success(stories))
        )

        let fetched = await subject.fetchStories()
        XCTAssertEqual(fetched, stories.map(MerinoStory.init))
    }
}

extension PocketStoryProviderTests {
    enum TestError: Error {
        case `default`
    }
}

extension RecommendationDataItem {
    static func make(title: String) -> RecommendationDataItem {
        RecommendationDataItem(
            corpusItemId: "",
            scheduledCorpusItemId: "",
            url: "www.google.com",
            title: title,
            excerpt: "",
            topic: "",
            publisher: "",
            isTimeSensitive: false,
            imageUrl: "www.google.com",
            iconUrl: "",
            tileId: 0,
            receivedRank: 0
        )
    }
}
