// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import MozillaAppServices

@testable import Client

@MainActor
final class MerinoManagerTests: XCTestCase {
    let storyProvider = MockStoryProvider()

    func test_getMerinoItems_withHomepageSource_returnExpectedStories() async {
        let subject = createSubject(with: storyProvider)
        let stories = await subject.getMerinoItems(source: .homepage)
        XCTAssertEqual(stories.count, 3)
        XCTAssertEqual(storyProvider.fetchHomepageStoriesCalled, 1)
    }

    func test_getMerinoItems_withStoriesFeedSource_returnExpectedStories() async {
        let subject = createSubject(with: storyProvider)
        let stories = await subject.getMerinoItems(source: .storiesFeed)
        XCTAssertEqual(stories.count, 3)
        XCTAssertEqual(storyProvider.fetchDiscoverMoreStoriesCalled, 1)
    }

    func test_prefetchStories_callsPrefetchStories() async {
        let subject = createSubject(with: storyProvider)
        await subject.prefetchStories()
        XCTAssertEqual(storyProvider.prefetchStoriesCalled, 1)
    }

    private func createSubject(
        with storyProvider: MockStoryProvider,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> MerinoManager {
        let subject = MerinoManager(storyProvider: storyProvider)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
