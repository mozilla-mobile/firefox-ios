// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

@MainActor
class StoryProviderTests: XCTestCase, FeatureFlaggable {
    func testFetchingStories_forHomepage_returnsList() async {
        let stories: [RecommendationDataItem] = (0..<150).map { .makeItem("feed\($0)") }
        let expectedNumberOfStories = 100
        let expectedResult = MerinoStoryResponse(
            stories: Array(stories.prefix(expectedNumberOfStories))
                .map(MerinoStory.init)
                .compactMap({ MerinoStoryConfiguration(story: $0) })
        )

        let subject = createSubject(with: MockMerinoAPI(result: .success(stories)))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched, expectedResult)
    }

    func testFetchingStories_forHomepage_returnsEmptyList() async {
        let subject = createSubject(with: MockMerinoAPI(result: .success([])))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched.stories?.count, 0)
    }

    func testFetchingStories_forHomepage_withError_returnsEmptyList() async {
        let subject = createSubject(with: MockMerinoAPI(result: .failure(TestError.default)))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched.stories?.count, 0)
    }

    private func createSubject(
        with merinoAPI: MockMerinoAPI,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> StoryProvider {
        let subject = StoryProvider(merinoAPI: merinoAPI)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}

extension StoryProviderTests {
    enum TestError: Error {
        case `default`
    }
}
