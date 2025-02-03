// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

class PocketStoryProviderTests: XCTestCase, FeatureFlaggable {
    var subject: StoryProvider!

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func tesFetchingStories_ReturnsList() async {
        let stories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        subject = StoryProvider(
            pocketAPI: MockPocketAPI(result: .success(stories))
        )

        let fetched = await subject.fetchPocketStories()
        XCTAssertEqual(fetched, stories.map(PocketStory.init))
    }
}

extension PocketStoryProviderTests {
    enum TestError: Error {
        case `default`
    }
}

extension PocketFeedStory {
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
