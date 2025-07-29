// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class HomepageStateTests: XCTestCase {
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

        XCTAssertFalse(initialState.headerState.isPrivate)
        XCTAssertFalse(initialState.headerState.showiPadSetup)
        XCTAssertFalse(initialState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(initialState.availableContentHeight, 0)
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                showiPadSetup: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.headerState.isPrivate)
        XCTAssertTrue(newState.headerState.showiPadSetup)
        XCTAssertFalse(newState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(newState.availableContentHeight, initialState.availableContentHeight)
    }

    func test_embeddedHomepageAction_withTrueZeroSearch_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                isZeroSearch: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.embeddedHomepage
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(newState.availableContentHeight, initialState.availableContentHeight)
    }

    func test_embeddedHomepageAction_withFalseZeroSearch_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                isZeroSearch: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.embeddedHomepage
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isZeroSearch)
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(newState.availableContentHeight, initialState.availableContentHeight)
    }

    func test_didSelectedTabChangeToHomepageAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            GeneralBrowserAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: GeneralBrowserActionType.didSelectedTabChangeToHomepage
            )
        )
        XCTAssertFalse(initialState.shouldTriggerImpression)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.isZeroSearch)
        XCTAssertTrue(newState.shouldTriggerImpression)
        XCTAssertEqual(newState.availableContentHeight, initialState.availableContentHeight)
    }

    func test_handleAvailableContentHeightChangeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = homepageReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                availableContentHeight: 500,
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.availableContentHeightDidChange
            )
        )

        XCTAssertEqual(newState.availableContentHeight, 500)
        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.shouldTriggerImpression)
        XCTAssertEqual(newState.isZeroSearch, initialState.isZeroSearch)
    }

    // MARK: - Private
    private func createSubject() -> HomepageState {
        return HomepageState(windowUUID: .XCTestDefaultUUID)
    }

    private func homepageReducer() -> Reducer<HomepageState> {
        return HomepageState.reducer
    }
}
