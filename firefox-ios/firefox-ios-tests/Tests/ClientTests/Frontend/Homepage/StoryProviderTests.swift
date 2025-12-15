// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

@MainActor
class StoryProviderTests: XCTestCase, FeatureFlaggable {
    func testFetchingStories_forHomepage_returnsList() async {
        let stories: [RecommendationDataItem] = (0..<30).map { .makeItem("feed\($0)") }
        let expectedNumberOfStories = isAnyStoriesRedesignEnabled ? 9 : 12
        let expectedResult = Array(stories.prefix(expectedNumberOfStories)).map(MerinoStory.init)

        let subject = createSubject(with: MockMerinoAPI(result: .success(stories)))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched, expectedResult)
    }

    func testFetchingStories_forHomepage_returnsEmptyList() async {
        let subject = createSubject(with: MockMerinoAPI(result: .success([])))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched.count, 0)
    }

    func testFetchingStories_forHomepage_withError_returnsEmptyList() async {
        let subject = createSubject(with: MockMerinoAPI(result: .failure(TestError.default)))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched.count, 0)
    }

    func testFetchingStories_forStoriesFeed_returnsList() async {
        let stories: [RecommendationDataItem] = (0..<20).map { .makeItem("feed\($0)") }
        let expectedResult = stories.map(MerinoStory.init)

        let subject = createSubject(with: MockMerinoAPI(result: .success(stories)))
        let fetched = await subject.fetchDiscoverMoreStories()

        XCTAssertEqual(Set(fetched), Set(expectedResult))
    }

    func testFetchingStories_forStoriesFeed_returnsEmptyList() async {
        let subject = createSubject(with: MockMerinoAPI(result: .success([])))
        let fetched = await subject.fetchDiscoverMoreStories()

        XCTAssertEqual(fetched.count, 0)
    }

    func testFetchingStories_forStoriesFeed_withError_returnsEmptyList() async {
        let subject = createSubject(with: MockMerinoAPI(result: .failure(TestError.default)))
        let fetched = await subject.fetchDiscoverMoreStories()

        XCTAssertEqual(fetched.count, 0)
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
