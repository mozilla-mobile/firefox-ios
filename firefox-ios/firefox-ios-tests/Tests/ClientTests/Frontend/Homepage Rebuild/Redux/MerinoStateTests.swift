// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import MozillaAppServices
import XCTest

@testable import Client

final class MerinoStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.merinoData, [])
    }

    func test_retrievedUpdatedStoriesAction_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = pocketReducer()

        let feedStories: [RecommendationDataItem] = [
            .make(title: "feed1"),
            .make(title: "feed2"),
            .make(title: "feed3"),
        ]

        let stories = feedStories.compactMap {
            MerinoStoryConfiguration(story: MerinoStory(from: $0))
        }

        let newState = reducer(
            initialState,
            MerinoAction(
                merinoStories: stories,
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoMiddlewareActionType.retrievedUpdatedStories
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.merinoData.count, 3)
        XCTAssertEqual(newState.merinoData.compactMap { $0.title }, ["feed1", "feed2", "feed3"])
    }

    func test_toggleShowSectionSetting_withToggleOn_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = pocketReducer()

        let newState = reducer(
            initialState,
            MerinoAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoActionType.toggleShowSectionSetting
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.shouldShowSection)
    }

    func test_toggleShowSectionSetting_withToggleOff_returnsExpectedState() throws {
        let initialState = createSubject()
        let reducer = pocketReducer()

        let newState = reducer(
            initialState,
            MerinoAction(
                isEnabled: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: MerinoActionType.toggleShowSectionSetting
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.shouldShowSection)
    }

    // MARK: - Private
    private func createSubject() -> MerinoState {
        return MerinoState(windowUUID: .XCTestDefaultUUID)
    }

    private func pocketReducer() -> Reducer<MerinoState> {
        return MerinoState.reducer
    }
}
