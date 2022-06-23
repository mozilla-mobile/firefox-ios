// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

class PocketStoryProviderTests: XCTestCase {
    var sut: StoryProvider!

    func testIfSponsoredAreDisabled_FetchingStories_ReturnsTheNonSponsoredList() async {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]
        
        sut = StoryProvider(
            pocketAPI: MockPocketAPI(stories: stories),
            pocketSponsoredAPI: MockSponsoredPocketAPI(stories: []),
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
            pocketAPI: MockPocketAPI(stories: stories),
            pocketSponsoredAPI: MockSponsoredPocketAPI(stories: []),
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
            pocketAPI: MockPocketAPI(stories: stories),
            pocketSponsoredAPI: MockSponsoredPocketAPI(stories: sponsoredStories),
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
            pocketAPI: MockPocketAPI(stories: stories),
            pocketSponsoredAPI: MockSponsoredPocketAPI(stories: sponsoredStories),
            sponsoredIndices: [1, 3, 5],
            showSponsoredStories: { true }
        )
        
        let extected: [PocketStory] = [
            .init(pocketFeedStory: .make(title: "feed1")),
            .init(pocketSponsoredStory: .make(title: "sponsored1")),
            .init(pocketFeedStory: .make(title: "feed2")),
            .init(pocketSponsoredStory: .make(title: "sponsored2")),
            .init(pocketFeedStory: .make(title: "feed3")),
            .init(pocketSponsoredStory: .make(title: "sponsored3"))
        ]
        
        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, extected)
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
            pocketAPI: MockPocketAPI(stories: stories),
            pocketSponsoredAPI: MockSponsoredPocketAPI(stories: sponsoredStories),
            sponsoredIndices: [0, 1],
            showSponsoredStories: { true }
        )
        
        let extected: [PocketStory] = [
            .init(pocketSponsoredStory: .make(title: "sponsored1")),
            .init(pocketSponsoredStory: .make(title: "sponsored2")),
            .init(pocketFeedStory: .make(title: "feed1")),
            .init(pocketFeedStory: .make(title: "feed2"))
        ]
        
        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, extected)
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
            pocketAPI: MockPocketAPI(stories: []),
            pocketSponsoredAPI: MockSponsoredPocketAPI(stories: sponsoredStories),
            sponsoredIndices: [0, 1],
            showSponsoredStories: { true }
        )
        
        let extected: [PocketStory] = [
            .init(pocketSponsoredStory: .make(title: "sponsored1")),
            .init(pocketSponsoredStory: .make(title: "sponsored2"))
        ]
        
        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, extected)
    }
}

extension PocketStoryProviderTests {
    class MockPocketAPI: PocketStoriesProviding {
        init(stories: [PocketFeedStory]) {
            self.stories = stories
        }
        
        var stories: [PocketFeedStory]
        
        func fetchStories(items: Int, completion: @escaping (StoryResult) -> Void) {
            completion(.success(stories))
            return
        }
        
    }
    
    class MockSponsoredPocketAPI: PocketSponsoredStoriesProviding {
        
        init(stories: [PocketSponsoredStory]) {
            self.stories = stories
        }
        
        var stories: [PocketSponsoredStory]
        
        func fetchSponsoredStories(timestamp: Timestamp, completion: @escaping (SponsoredStoryResult) -> Void) {
            completion(.success(stories))
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
