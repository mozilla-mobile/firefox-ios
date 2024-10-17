// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class PocketStateTests: XCTestCase {
    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.pocketData, [])
        XCTAssertEqual(initialState.pocketDiscoverTitle, "")
    }

    func test_retrievedUpdatedStoriesAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = pocketReducer()

        let feedStories: [PocketFeedStory] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        let stories = feedStories.compactMap {
            PocketStoryState(story: PocketStory(pocketFeedStory: $0))
        }

        let newState = reducer(
            initialState,
            PocketAction(
                pocketStories: stories,
                windowUUID: .XCTestDefaultUUID,
                actionType: PocketMiddlewareActionType.retrievedUpdatedStories
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.pocketData.count, 3)
        XCTAssertEqual(newState.pocketData.compactMap { $0.title }, ["feed1", "feed2", "feed3"])
        XCTAssertEqual(newState.pocketDiscoverTitle, .FirefoxHomepage.Pocket.DiscoverMore)
    }

    // MARK: - Private
    private func createSubject() -> PocketState {
        return PocketState(windowUUID: .XCTestDefaultUUID)
    }

    private func pocketReducer() -> Reducer<PocketState> {
        return PocketState.reducer
    }
}
