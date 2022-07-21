// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

class PocketStoryProviderTests: XCTestCase {
    var sut: StoryProvider!

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testIfSponsoredAreDisabled_FetchingStories_ReturnsTheNonSponsoredList() async {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        sut = StoryProvider(
            pocketAPI: MockPocketAPI(result: .success(stories)),
            pocketSponsoredAPI: MockSponsoredPocketAPI(result: .success([])),
            showSponsoredStories: { false }
        )

        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, stories.map(PocketStory.init))
    }

    func testIfSponsoredAreEnabled_FetchingStoriesWithZeroSponsors_ReturnsTheNonSponsoredList() async {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        sut = StoryProvider(
            pocketAPI: MockPocketAPI(result: .success(stories)),
            pocketSponsoredAPI: MockSponsoredPocketAPI(result: .success([])),
            showSponsoredStories: { true }
        )

        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, stories.map(PocketStory.init))
    }

    func testIfSponsoredAreEnabled_FetchingStoriesWithSponsors_ReturnsStoryList() async {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        let sponsoredStories: [PocketSponsoredStory] = [
            .make(title: "sponsored1"),
            .make(title: "sponsored2"),
            .make(title: "sponsored3"),
        ]

        sut = StoryProvider(
            pocketAPI: MockPocketAPI(result: .success(stories)),
            pocketSponsoredAPI: MockSponsoredPocketAPI(result: .success(sponsoredStories)),
            sponsoredIndices: [3, 4, 5],
            showSponsoredStories: { true }
        )

        let expected = (stories.map(PocketStory.init) + sponsoredStories.map(PocketStory.init))
        let fetched = await sut.fetchPocketStories()

        XCTAssertEqual(fetched, expected)
    }

    func testIfSponsoredAreEnabled_FetchingStoriesWithSponsors_ReturnsInCorrectOrder() async {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        let sponsoredStories: [PocketSponsoredStory] = [
            .make(title: "sponsored1"),
            .make(title: "sponsored2"),
            .make(title: "sponsored3"),
        ]

        sut = StoryProvider(
            pocketAPI: MockPocketAPI(result: .success(stories)),
            pocketSponsoredAPI: MockSponsoredPocketAPI(result: .success(sponsoredStories)),
            sponsoredIndices: [1, 3, 5],
            showSponsoredStories: { true }
        )

        let expected: [PocketStory] = [
            .init(pocketFeedStory: .make(title: "feed1")),
            .init(pocketSponsoredStory: .make(title: "sponsored1")),
            .init(pocketFeedStory: .make(title: "feed2")),
            .init(pocketSponsoredStory: .make(title: "sponsored2")),
            .init(pocketFeedStory: .make(title: "feed3")),
            .init(pocketSponsoredStory: .make(title: "sponsored3"))
        ]

        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, expected)
    }

    func testReturningMoreSponsores_ShowsOnlyTheCountFromIndeces() async {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
        ]

        let sponsoredStories: [PocketSponsoredStory] = [
            .make(title: "sponsored1"),
            .make(title: "sponsored2"),
            .make(title: "sponsored3"),
            .make(title: "sponsored4"),
            .make(title: "sponsored5"),
        ]

        sut = StoryProvider(
            pocketAPI: MockPocketAPI(result: .success(stories)),
            pocketSponsoredAPI: MockSponsoredPocketAPI(result: .success(sponsoredStories)),
            sponsoredIndices: [0, 1],
            showSponsoredStories: { true }
        )

        let expected: [PocketStory] = [
            .init(pocketSponsoredStory: .make(title: "sponsored1")),
            .init(pocketSponsoredStory: .make(title: "sponsored2")),
            .init(pocketFeedStory: .make(title: "feed1")),
            .init(pocketFeedStory: .make(title: "feed2"))
        ]

        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, expected)
    }

    func testReturningEmptyFeed_ShowsOnlyTheSponsoredStories() async {
        let sponsoredStories: [PocketSponsoredStory] = [
            .make(title: "sponsored1"),
            .make(title: "sponsored2"),
            .make(title: "sponsored3"),
            .make(title: "sponsored4"),
            .make(title: "sponsored5"),
        ]

        sut = StoryProvider(
            pocketAPI: MockPocketAPI(result: .success([])),
            pocketSponsoredAPI: MockSponsoredPocketAPI(result: .success(sponsoredStories)),
            sponsoredIndices: [0, 1],
            showSponsoredStories: { true }
        )

        let expected: [PocketStory] = [
            .init(pocketSponsoredStory: .make(title: "sponsored1")),
            .init(pocketSponsoredStory: .make(title: "sponsored2"))
        ]

        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, expected)
    }

    func testReturningFailureForSponsoredStories_ShowsOnlyTheFeed() async {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        sut = StoryProvider(
            pocketAPI: MockPocketAPI(result: .success(stories)),
            pocketSponsoredAPI: MockSponsoredPocketAPI(result: .failure(TestError.default)),
            sponsoredIndices: [0, 1],
            showSponsoredStories: { true }
        )

        let expected: [PocketStory] = [
            .init(pocketFeedStory: .make(title: "feed1")),
            .init(pocketFeedStory: .make(title: "feed2")),
            .init(pocketFeedStory: .make(title: "feed3")),
        ]

        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched.count, 3)
        XCTAssertEqual(fetched, expected)
    }

    func testReturningFailureForFeedStories_ShowsOnlyTheSponsored() async {
        let stories: [PocketSponsoredStory] = [
            .make(title: "sponsored1"),
            .make(title: "sponsored2"),
            .make(title: "sponsored3"),
        ]

        sut = StoryProvider(
            pocketAPI: MockPocketAPI(result: .failure(TestError.default)),
            pocketSponsoredAPI: MockSponsoredPocketAPI(result: .success(stories)),
            sponsoredIndices: [0, 1, 2],
            showSponsoredStories: { true }
        )

        let expected: [PocketStory] = stories.map(PocketStory.init)

        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, expected)
    }

    func testReturningFailureForSponsoredStories_ShowsOnlyTheRequestedNumberInFeed() async {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
            .make(title: "feed4"),
            .make(title: "feed5")
        ]

        sut = StoryProvider(
            pocketAPI: MockPocketAPI(result: .success(stories)),
            pocketSponsoredAPI: MockSponsoredPocketAPI(result: .failure(TestError.default)),
            numberOfPocketStories: 3,
            sponsoredIndices: [0, 1],
            showSponsoredStories: { true }
        )

        let expected: [PocketStory] = [
            .init(pocketFeedStory: .make(title: "feed1")),
            .init(pocketFeedStory: .make(title: "feed2")),
            .init(pocketFeedStory: .make(title: "feed3")),
        ]

        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched.count, 3)
        XCTAssertEqual(fetched, expected)
    }
}

extension PocketStoryProviderTests {
    enum TestError: Error {
        case `default`
    }

    class MockPocketAPI: PocketStoriesProviding {

        init(result: Result<[PocketFeedStory], Error>) {
            self.result = result
        }

        var result: Result<[PocketFeedStory], Error>

        func fetchStories(items: Int, completion: @escaping (StoryResult) -> Void) {
            switch result {
            case .success(let value):
                completion(.success(Array(value.prefix(items))))
            case .failure(let error):
                completion(.failure(error))
            }
            return
        }

    }

    class MockSponsoredPocketAPI: PocketSponsoredStoriesProviding {

        init(result: Result<[PocketSponsoredStory], Error>) {
            self.result = result
        }

        var result: Result<[PocketSponsoredStory], Error>

        func fetchSponsoredStories(timestamp: Timestamp, completion: @escaping (SponsoredStoryResult) -> Void) {
            completion(result)
        }
    }
}

fileprivate extension PocketFeedStory {
    static func make(title: String) -> PocketFeedStory {
        PocketFeedStory(
            title: title,
            url: URL(string: "www.google.com")!,
            domain: "",
            timeToRead: 1,
            storyDescription: "",
            imageURL: URL(string: "www.google.com")!
        )
    }
}

fileprivate extension PocketSponsoredStory {
    static func make(title: String) -> PocketSponsoredStory {
        PocketSponsoredStory(
            id: 1,
            flightId: 1,
            campaignId: 1,
            title: title,
            url: nil,
            domain: "",
            excerpt: "",
            priority: 1,
            context: "",
            rawImageSrc: URL(string: "www.google.com")!,
            imageURL: URL(string: "www.google.com")!,
            shim: .init(click: "", impression: "", delete: "", save: ""),
            caps: .init(lifetime: 1, campaign: .init(count: 1, period: 1), flight: .init(count: 1, period: 1)),
            sponsor: ""
        )
    }
}
