// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

class StoryProviderTests: XCTestCase, FeatureFlaggable {
    var subject: StoryProvider!

    override func tearDown() {
        super.tearDown()
        subject = nil
    }

    func testFetchingStories_forHomepage_returnsList() async {
        let stories: [RecommendationDataItem] = (0...30).map { .makeItem("feed\($0)") }
        let expectedNumberOfStories = featureFlags.isFeatureEnabled(.homepageStoriesRedesign, checking: .buildOnly) ? 9 : 12
        let expectedResult = Array(stories.prefix(expectedNumberOfStories)).map(MerinoStory.init)

        subject = StoryProvider(merinoAPI: MockMerinoAPI(result: .success(stories)))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched, expectedResult)
    }

    func testFetchingStories_forDiscoverMore_returnsList() async {
        let stories: [RecommendationDataItem] = (0...30).map { .makeItem("feed\($0)") }
        let expectedResult = Array(stories.prefix(25)).map(MerinoStory.init)

        subject = StoryProvider(merinoAPI: MockMerinoAPI(result: .success(stories)))
        let fetched = await subject.fetchDiscoverMoreStories()

        XCTAssertEqual(fetched, expectedResult)
    }
}

extension StoryProviderTests {
    enum TestError: Error {
        case `default`
    }
}
