// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

final class ThemeSettingsStateTests: XCTestCase {
    // MARK: - Initialization Tests

    func test_initWithWindowUUID_returnsDefaultState() {
        let subject = createSubject()

        XCTAssertEqual(subject.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(subject.useSystemAppearance)
        XCTAssertFalse(subject.isAutomaticBrightnessEnabled)
        XCTAssertEqual(subject.manualThemeSelected, .light)
        XCTAssertEqual(subject.userBrightnessThreshold, 0)
        XCTAssertEqual(subject.systemBrightness, 1)
    }

    func test_initWithAllParameters_returnsConfiguredState() {
        let subject = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: true,
            isAutomaticBrightnessEnable: true,
            manualThemeSelected: .dark,
            userBrightnessThreshold: 0.5,
            systemBrightness: 0.8
        )

        XCTAssertEqual(subject.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(subject.useSystemAppearance)
        XCTAssertTrue(subject.isAutomaticBrightnessEnabled)
        XCTAssertEqual(subject.manualThemeSelected, .dark)
        XCTAssertEqual(subject.userBrightnessThreshold, 0.5)
        XCTAssertEqual(subject.systemBrightness, 0.8)
    }

    // MARK: - Reducer Tests - receivedThemeManagerValues

    @MainActor
    func test_receivedThemeManagerValues_replacesEntireState() {
        let initialState = createSubject()
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: true,
            isAutomaticBrightnessEnable: true,
            manualThemeSelected: .dark,
            userBrightnessThreshold: 0.7,
            systemBrightness: 0.6
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.receivedThemeManagerValues
        )

        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.useSystemAppearance)
        XCTAssertTrue(newState.isAutomaticBrightnessEnabled)
        XCTAssertEqual(newState.manualThemeSelected, .dark)
        XCTAssertEqual(newState.userBrightnessThreshold, 0.7)
        XCTAssertEqual(newState.systemBrightness, 0.6)
    }

    @MainActor
    func test_receivedThemeManagerValues_withNilState_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = themeSettingsReducer()

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: nil,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.receivedThemeManagerValues
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.windowUUID, initialState.windowUUID)
        XCTAssertEqual(newState.useSystemAppearance, initialState.useSystemAppearance)
    }

    // MARK: - Reducer Tests - systemThemeChanged

    @MainActor
    func test_systemThemeChanged_toTrue_updatesUseSystemAppearance() {
        let initialState = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: true,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.systemThemeChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.useSystemAppearance)
        XCTAssertFalse(newState.isAutomaticBrightnessEnabled)
        XCTAssertEqual(newState.manualThemeSelected, .light)
    }

    @MainActor
    func test_systemThemeChanged_toFalse_updatesUseSystemAppearance() {
        let initialState = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: true,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.systemThemeChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.useSystemAppearance)
    }

    // MARK: - Reducer Tests - automaticBrightnessChanged

    @MainActor
    func test_automaticBrightnessChanged_toTrue_updatesIsAutomaticBrightnessEnabled() {
        let initialState = createSubject()
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: true,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.automaticBrightnessChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.isAutomaticBrightnessEnabled)
        XCTAssertFalse(newState.useSystemAppearance)
        XCTAssertEqual(newState.manualThemeSelected, .light)
    }

    @MainActor
    func test_automaticBrightnessChanged_toFalse_updatesIsAutomaticBrightnessEnabled() {
        let initialState = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: true,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.automaticBrightnessChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.isAutomaticBrightnessEnabled)
    }

    // MARK: - Reducer Tests - manualThemeChanged

    @MainActor
    func test_manualThemeChanged_toDark_updatesManualThemeSelected() {
        let initialState = createSubject()
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .dark,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.manualThemeChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.manualThemeSelected, .dark)
        XCTAssertFalse(newState.useSystemAppearance)
        XCTAssertFalse(newState.isAutomaticBrightnessEnabled)
    }

    @MainActor
    func test_manualThemeChanged_toLight_updatesManualThemeSelected() {
        let initialState = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .dark,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.manualThemeChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.manualThemeSelected, .light)
    }

    // MARK: - Reducer Tests - userBrightnessChanged

    @MainActor
    func test_userBrightnessChanged_updatesUserBrightnessThreshold() {
        let initialState = createSubject()
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0.75,
            systemBrightness: 1
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.userBrightnessChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.userBrightnessThreshold, 0.75)
        XCTAssertEqual(newState.systemBrightness, 1)
    }

    @MainActor
    func test_userBrightnessChanged_withZeroValue_updatesCorrectly() {
        let initialState = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0.5,
            systemBrightness: 1
        )
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.userBrightnessChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.userBrightnessThreshold, 0)
    }

    // MARK: - Reducer Tests - systemBrightnessChanged

    @MainActor
    func test_systemBrightnessChanged_updatesSystemBrightness() {
        let initialState = createSubject()
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 0.3
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.systemBrightnessChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.systemBrightness, 0.3)
        XCTAssertEqual(newState.userBrightnessThreshold, 0)
    }

    @MainActor
    func test_systemBrightnessChanged_withMaxValue_updatesCorrectly() {
        let initialState = createSubject()
        let reducer = themeSettingsReducer()

        let newStateData = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1.0
        )

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: newStateData,
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.systemBrightnessChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.systemBrightness, 1.0)
    }

    // MARK: - Equality Tests

    func test_equality_sameValues_returnsTrue() {
        let state1 = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: true,
            isAutomaticBrightnessEnable: true,
            manualThemeSelected: .dark,
            userBrightnessThreshold: 0.5,
            systemBrightness: 0.8
        )

        let state2 = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: true,
            isAutomaticBrightnessEnable: true,
            manualThemeSelected: .dark,
            userBrightnessThreshold: 0.5,
            systemBrightness: 0.8
        )

        XCTAssertEqual(state1, state2)
    }

    func test_equality_differentUseSystemAppearance_returnsFalse() {
        let state1 = createSubject()
        let state2 = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: true,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentIsAutomaticBrightnessEnabled_returnsFalse() {
        let state1 = createSubject()
        let state2 = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: true,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentManualThemeSelected_returnsFalse() {
        let state1 = createSubject()
        let state2 = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .dark,
            userBrightnessThreshold: 0,
            systemBrightness: 1
        )

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentUserBrightnessThreshold_returnsFalse() {
        let state1 = createSubject()
        let state2 = ThemeSettingsState(
            windowUUID: .XCTestDefaultUUID,
            useSystemAppearance: false,
            isAutomaticBrightnessEnable: false,
            manualThemeSelected: .light,
            userBrightnessThreshold: 0.5,
            systemBrightness: 1
        )

        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Edge Cases

    @MainActor
    func test_unknownAction_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = themeSettingsReducer()

        struct UnknownAction: Action {
            let windowUUID: WindowUUID
            let actionType: ActionType
        }

        let action = UnknownAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: ThemeSettingsMiddlewareActionType.systemThemeChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.windowUUID, initialState.windowUUID)
        XCTAssertEqual(newState.useSystemAppearance, initialState.useSystemAppearance)
    }

    @MainActor
    func test_actionWithDifferentWindowUUID_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = themeSettingsReducer()

        let action = ThemeSettingsMiddlewareAction(
            themeSettingsState: nil,
            windowUUID: WindowUUID()
        ,
            actionType: ThemeSettingsMiddlewareActionType.systemThemeChanged
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState, initialState)
    }

    // MARK: - Private Helpers

    private func createSubject() -> ThemeSettingsState {
        return ThemeSettingsState(windowUUID: .XCTestDefaultUUID)
    }

    private func themeSettingsReducer() -> Reducer<ThemeSettingsState> {
        return ThemeSettingsState.reducer
    }
}
