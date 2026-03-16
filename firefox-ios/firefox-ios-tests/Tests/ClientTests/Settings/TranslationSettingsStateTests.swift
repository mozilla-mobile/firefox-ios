// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

@MainActor
final class TranslationSettingsStateTests: XCTestCase {
    // MARK: - Initialization Tests

    func test_initWithWindowUUID_returnsDefaultState() {
        let subject = createSubject()

        XCTAssertEqual(subject.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(subject.isTranslationsEnabled)
        XCTAssertEqual(subject.preferredLanguages, [])
        XCTAssertEqual(subject.supportedLanguages, [])
    }

    func test_initWithAllParameters_returnsConfiguredState() {
        let subject = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: false,
            preferredLanguages: ["en", "fr"],
            supportedLanguages: ["en", "fr", "de"]
        )

        XCTAssertEqual(subject.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(subject.isTranslationsEnabled)
        XCTAssertEqual(subject.preferredLanguages, ["en", "fr"])
        XCTAssertEqual(subject.supportedLanguages, ["en", "fr", "de"])
    }

    // MARK: - Reducer Tests - didLoadSettings

    @MainActor
    func test_didLoadSettings_updatesAllValues() {
        let initialState = createSubject()
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsMiddlewareAction(
            isTranslationsEnabled: false,
            preferredLanguages: ["en", "fr"],
            supportedLanguages: ["en", "fr", "de"],
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.isTranslationsEnabled)
        XCTAssertEqual(newState.preferredLanguages, ["en", "fr"])
        XCTAssertEqual(newState.supportedLanguages, ["en", "fr", "de"])
    }

    @MainActor
    func test_didLoadSettings_withNilValues_preservesExistingState() {
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: false,
            preferredLanguages: ["en"],
            supportedLanguages: ["en", "de"]
        )
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.isTranslationsEnabled)
        XCTAssertEqual(newState.preferredLanguages, ["en"])
        XCTAssertEqual(newState.supportedLanguages, ["en", "de"])
    }

    // MARK: - Reducer Tests - didUpdateSettings

    @MainActor
    func test_didUpdateSettings_updatesTranslationsEnabled() {
        let initialState = createSubject()
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsMiddlewareAction(
            isTranslationsEnabled: false,
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsMiddlewareActionType.didUpdateSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.isTranslationsEnabled)
        XCTAssertEqual(newState.preferredLanguages, initialState.preferredLanguages)
        XCTAssertEqual(newState.supportedLanguages, initialState.supportedLanguages)
    }

    @MainActor
    func test_didUpdateSettings_preservesLanguagesWhenNil() {
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: ["en", "fr"],
            supportedLanguages: ["en", "fr", "de"]
        )
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsMiddlewareAction(
            isTranslationsEnabled: false,
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsMiddlewareActionType.didUpdateSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.isTranslationsEnabled)
        XCTAssertEqual(newState.preferredLanguages, ["en", "fr"])
        XCTAssertEqual(newState.supportedLanguages, ["en", "fr", "de"])
    }

    // MARK: - Equality Tests

    func test_equality_sameValues_returnsTrue() {
        let state1 = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: ["en"],
            supportedLanguages: ["en", "fr"]
        )
        let state2 = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: ["en"],
            supportedLanguages: ["en", "fr"]
        )

        XCTAssertEqual(state1, state2)
    }

    func test_equality_differentIsTranslationsEnabled_returnsFalse() {
        let state1 = createSubject()
        let state2 = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: false,
            preferredLanguages: [],
            supportedLanguages: []
        )

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentPreferredLanguages_returnsFalse() {
        let state1 = createSubject()
        let state2 = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: ["en"],
            supportedLanguages: []
        )

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentSupportedLanguages_returnsFalse() {
        let state1 = createSubject()
        let state2 = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: [],
            supportedLanguages: ["en"]
        )

        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - Edge Cases

    @MainActor
    func test_unknownAction_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = translationSettingsReducer()

        struct UnknownAction: Action {
            let windowUUID: WindowUUID
            let actionType: ActionType
        }

        let action = UnknownAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState, initialState)
    }

    @MainActor
    func test_actionWithDifferentWindowUUID_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsMiddlewareAction(
            isTranslationsEnabled: false,
            windowUUID: WindowUUID(),
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState, initialState)
    }

    // MARK: - Private Helpers

    private func createSubject() -> TranslationSettingsState {
        return TranslationSettingsState(windowUUID: .XCTestDefaultUUID)
    }

    private func translationSettingsReducer() -> Reducer<TranslationSettingsState> {
        return TranslationSettingsState.reducer
    }
}
