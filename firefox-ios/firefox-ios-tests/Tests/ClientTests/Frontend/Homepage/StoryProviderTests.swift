// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

@MainActor
class StoryProviderTests: XCTestCase, LegacyFeatureFlaggable {
    func testFetchingStories_forHomepage_returnsList() async {
        let stories: [RecommendationDataItem] = (0..<150).map { .makeItem("feed\($0)") }
        let response = CuratedRecommendationsResponse.makeResponse(items: stories)
        let expectedResult = MerinoStoryResponse(
            stories: stories
                .map(MerinoStory.init)
                .compactMap({ MerinoStoryConfiguration(story: $0) })
        )

        let subject = createSubject(with: MockMerinoAPI(result: .success(response)))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched, expectedResult)
    }

    func testFetchingStories_forHomepage_returnsEmptyList() async {
        let response = CuratedRecommendationsResponse.makeResponse(items: [])
        let subject = createSubject(with: MockMerinoAPI(result: .success(response)))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched.stories?.count, 0)
    }

    func testFetchingStories_forHomepage_withError_returnsEmptyList() async {
        let subject = createSubject(with: MockMerinoAPI(result: .failure(TestError.default)))
        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched.stories?.count, 0)
    }

    func testFetchingStories_withFeeds_returnsCategories() async {
        let feeds = [
            FeedSection.makeSection(
                feedId: "travel",
                receivedFeedRank: 1,
                recommendations: [.makeItem("travel1")],
                title: "Travel"
            ),
            FeedSection.makeSection(
                feedId: "arts",
                receivedFeedRank: 2,
                recommendations: [.makeItem("arts1"), .makeItem("arts2")],
                title: "Arts"
            ),
        ]
        let response = CuratedRecommendationsResponse.makeResponse(items: [.makeItem("story1")], feeds: feeds)
        let subject = createSubject(with: MockMerinoAPI(result: .success(response)))

        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched.categories?.count, 2)
        XCTAssertEqual(fetched.categories?.first?.feedID, "travel")
        XCTAssertEqual(fetched.categories?.last?.feedID, "arts")
        XCTAssertEqual(fetched.categories?.last?.recommendations.count, 2)
    }

    func testFetchingStories_withNilFeeds_returnsNilCategories() async {
        let response = CuratedRecommendationsResponse.makeResponse(items: [.makeItem("story1")], feeds: nil)
        let subject = createSubject(with: MockMerinoAPI(result: .success(response)))

        let fetched = await subject.fetchHomepageStories()

        XCTAssertNil(fetched.categories)
    }

    func testFetchingStories_withEmptyFeeds_returnsEmptyCategories() async {
        let response = CuratedRecommendationsResponse.makeResponse(items: [.makeItem("story1")], feeds: [])
        let subject = createSubject(with: MockMerinoAPI(result: .success(response)))

        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched.categories?.count, 0)
    }

    func testFetchingStories_withFeedsAndStories_returnsBoth() async {
        let stories: [RecommendationDataItem] = [.makeItem("s1"), .makeItem("s2")]
        let feeds = [FeedSection.makeSection(feedId: "travel", recommendations: [.makeItem("t1")])]
        let response = CuratedRecommendationsResponse.makeResponse(items: stories, feeds: feeds)
        let subject = createSubject(with: MockMerinoAPI(result: .success(response)))

        let fetched = await subject.fetchHomepageStories()

        XCTAssertEqual(fetched.stories?.count, 2)
        XCTAssertEqual(fetched.categories?.count, 1)
        XCTAssertEqual(fetched.categories?.first?.feedID, "travel")
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
