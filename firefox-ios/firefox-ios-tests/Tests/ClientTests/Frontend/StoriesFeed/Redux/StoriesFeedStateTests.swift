// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import MozillaAppServices
import XCTest

@testable import Client

final class StoriesFeedStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.storiesData, [])
    }

    @MainActor
    func test_retrievedUpdatedStoriesAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = storiesFeedReducer()

        let feedStories: [RecommendationDataItem] = [
            .makeItem("feed1"),
            .makeItem("feed2"),
            .makeItem("feed3"),
        ]

        let stories = feedStories.compactMap {
            MerinoStoryConfiguration(story: MerinoStory(from: $0))
        }

        let newState = reducer(
            initialState,
            MerinoAction(
                merinoStories: stories,
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedStoriesFeedStories
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.storiesData.count, 3)
        XCTAssertEqual(newState.storiesData.compactMap { $0.title }, ["feed1", "feed2", "feed3"])
    }

    // MARK: - Private
    private func createSubject() -> StoriesFeedState {
        return StoriesFeedState(windowUUID: .XCTestDefaultUUID)
    }

    private func storiesFeedReducer() -> Reducer<StoriesFeedState> {
        return StoriesFeedState.reducer
    }
}
