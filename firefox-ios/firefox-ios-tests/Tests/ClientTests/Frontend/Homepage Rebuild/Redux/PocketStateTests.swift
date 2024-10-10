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
    }

    func test_retrievedUpdatedStoriesAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = pocketReducer()

        let url = try XCTUnwrap(URL(string: "www.example.com"))
        let stories = [
            PocketItem(
                story: PocketStory(
                    pocketFeedStory: PocketFeedStory(
                        title: "test-title",
                        url: url,
                        domain: "test-domain",
                        timeToRead: nil,
                        storyDescription: "test-description",
                        imageURL: url
                    )
                )
            )
        ]

        let newState = reducer(
            initialState,
            PocketAction(
                pocketStories: stories,
                windowUUID: .XCTestDefaultUUID,
                actionType: PocketMiddlewareActionType.retrievedUpdatedStories
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.pocketData.count, 1)
        XCTAssertEqual(initialState.pocketData.first?.title, "test-url")
    }

    // MARK: - Private
    private func createSubject() -> PocketState {
        return PocketState(windowUUID: .XCTestDefaultUUID)
    }

    private func pocketReducer() -> Reducer<PocketState> {
        return PocketState.reducer
    }
}
