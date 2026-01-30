// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class OnboardingViewControllerStateTests: XCTestCase {
    private let windowUUID: WindowUUID = .XCTestDefaultUUID

    // MARK: - Initialization Tests
    func test_init_withWindowUUID_setsWindowUUID() {
        let subject = OnboardingViewControllerState(windowUUID: windowUUID)

        XCTAssertEqual(subject.windowUUID, windowUUID)
    }

    func test_init_withDifferentWindowUUID_setsCorrectUUID() {
        let subject = OnboardingViewControllerState(windowUUID: windowUUID)

        XCTAssertEqual(subject.windowUUID, windowUUID)
    }

    func test_init_withAppState_whenScreenStateDoesNotExist_usesDefaultInit() {
        let appState = AppState()
        let subject = OnboardingViewControllerState(appState: appState, uuid: windowUUID)

        XCTAssertEqual(subject.windowUUID, windowUUID)
    }

    // MARK: - Reducer Tests
    @MainActor
    func test_reducer_withMatchingWindowUUID_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = onboardingReducer()

        let action = ScreenAction(windowUUID: windowUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .onboardingViewController)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.windowUUID, windowUUID)
    }

    @MainActor
    func test_reducer_withUnavailableWindowUUID_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = onboardingReducer()

        let action = ScreenAction(windowUUID: .unavailable,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .onboardingViewController)
        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.windowUUID, windowUUID)
    }

    @MainActor
    func test_reducer_withDifferentWindowUUID_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = onboardingReducer()
        let differentUUID: WindowUUID = .XCTestDefaultUUID

        let action = ScreenAction(windowUUID: differentUUID,
                                  actionType: ScreenActionType.closeScreen,
                                  screen: .onboardingViewController)
        let newState = reducer(initialState, action)

        // Should return defaultState (preserves original windowUUID)
        XCTAssertEqual(newState.windowUUID, windowUUID)
    }

    // MARK: - defaultState Tests
    @MainActor
    func test_defaultState_preservesWindowUUID() {
        let state = createSubject()
        let defaultState = OnboardingViewControllerState.defaultState(from: state)

        XCTAssertEqual(defaultState.windowUUID, state.windowUUID)
    }

    @MainActor
    func test_defaultState_withDifferentUUID_preservesWindowUUID() {
        let state = OnboardingViewControllerState(windowUUID: windowUUID)
        let defaultState = OnboardingViewControllerState.defaultState(from: state)

        XCTAssertEqual(defaultState.windowUUID, windowUUID)
    }

    // MARK: - Private Helpers
    private func createSubject() -> OnboardingViewControllerState {
        return OnboardingViewControllerState(windowUUID: .XCTestDefaultUUID)
    }

    private func onboardingReducer() -> Reducer<OnboardingViewControllerState> {
        return OnboardingViewControllerState.reducer
    }
}
