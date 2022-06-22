// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class PocketStoryProviderTests: XCTestCase {
    
    
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
        
        func fetchStories(items: Int, completion: @escaping (SponsoredStoryResult) -> Void) {
            completion(.success(stories))
            return
        }
        
    }
    
    var sut: StoryProvider!

    func testIfSponsoredAreDisabled_FetchingStories_ReturnsTheNonSponsoredList() async {
        let stories: [PocketFeedStory] = [
            .make(title: "title1"),
            .make(title: "title2"),
            .make(title: "title3"),
        ]
        
        sut = StoryProvider(
            pocketAPI: MockPocketAPI(stories: stories),
            pocketSponsoredAPI: MockSponsoredPocketAPI(stories: []),
            showSponsoredStories: { false }
        )
        
        let fetched = await sut.fetchPocketStories()
        XCTAssertEqual(fetched, stories.map(PocketStory.init))
    }
}

extension PocketStoryProviderTests {
    
    func makePocketStories() -> [PocketFeedStory] {
        [
            .make(title: "title1"),
            .make(title: "title2"),
            .make(title: "title3"),
        ]
    }
    
    func makeSponsoredPocketStories() -> [PocketSponsoredStory] {
        [
            .make(title: "title1"),
            .make(title: "title2"),
            .make(title: "title3"),
        ]
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
