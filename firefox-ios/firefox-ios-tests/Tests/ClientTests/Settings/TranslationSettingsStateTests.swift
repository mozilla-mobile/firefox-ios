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
        let languages = makeLanguages(["en", "fr"])
        let subject = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: false,
            preferredLanguages: languages,
            supportedLanguages: ["en", "fr", "de"]
        )

        XCTAssertEqual(subject.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(subject.isTranslationsEnabled)
        XCTAssertEqual(subject.preferredLanguages, languages)
        XCTAssertEqual(subject.supportedLanguages, ["en", "fr", "de"])
    }

    // MARK: - Reducer Tests - didLoadSettings

    func test_didLoadSettings_updatesAllValues() {
        let initialState = createSubject()
        let reducer = translationSettingsReducer()
        let languages = makeLanguages(["en", "fr"])

        let action = TranslationSettingsMiddlewareAction(
            isTranslationsEnabled: false,
            preferredLanguages: languages,
            supportedLanguages: ["en", "fr", "de"],
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.isTranslationsEnabled)
        XCTAssertEqual(newState.preferredLanguages, languages)
        XCTAssertEqual(newState.supportedLanguages, ["en", "fr", "de"])
    }

    func test_didLoadSettings_withNilValues_preservesExistingState() {
        let languages = makeLanguages(["en"])
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: false,
            preferredLanguages: languages,
            supportedLanguages: ["en", "de"]
        )
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.isTranslationsEnabled)
        XCTAssertEqual(newState.preferredLanguages, languages)
        XCTAssertEqual(newState.supportedLanguages, ["en", "de"])
    }

    // MARK: - Reducer Tests - isAutoTranslateEnabled

    func test_reduceMiddlewareAction_didLoadSettings_updatesAutoTranslate() {
        let initialState = createSubject()
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsMiddlewareAction(
            isAutoTranslateEnabled: true,
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.isAutoTranslateEnabled)
    }

    func test_reduceMiddlewareAction_didLoadSettings_preservesAutoTranslate_whenNil() {
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            isAutoTranslateEnabled: true,
            preferredLanguages: [],
            supportedLanguages: []
        )
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsMiddlewareActionType.didLoadSettings
        )

        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.isAutoTranslateEnabled)
    }

    // MARK: - Reducer Tests - enterEditMode

    func test_enterEditMode_setsIsEditingAndCopiesPreferredToPending() {
        let languages = makeLanguages(["en", "fr"])
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: languages,
            supportedLanguages: []
        )
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.enterEditMode
        )

        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.isEditing)
        XCTAssertEqual(newState.pendingLanguages, languages)
        XCTAssertEqual(newState.preferredLanguages, languages)
    }

    // MARK: - Reducer Tests - cancelEditMode

    func test_cancelEditMode_clearsIsEditingAndPendingLanguages() {
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            isEditing: true,
            pendingLanguages: makeLanguages(["fr"]),
            preferredLanguages: makeLanguages(["en", "fr"]),
            supportedLanguages: []
        )
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.cancelEditMode
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.isEditing)
        XCTAssertNil(newState.pendingLanguages)
        XCTAssertEqual(newState.preferredLanguages, makeLanguages(["en", "fr"]))
    }

    // MARK: - Reducer Tests - reorderLanguages

    func test_reorderLanguages_updatesPendingLanguagesWithNewOrder() {
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            isEditing: true,
            pendingLanguages: makeLanguages(["en", "fr"]),
            preferredLanguages: makeLanguages(["en", "fr"]),
            supportedLanguages: []
        )
        let reordered = makeLanguages(["fr", "en"])
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsViewAction(
            pendingLanguages: reordered,
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.reorderLanguages
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.pendingLanguages, reordered)
        XCTAssertEqual(newState.preferredLanguages, makeLanguages(["en", "fr"]))
    }

    // MARK: - Reducer Tests - removeLanguage

    func test_removeLanguage_removesFromPendingLanguages() {
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            isEditing: true,
            pendingLanguages: makeLanguages(["en", "fr", "de"]),
            preferredLanguages: makeLanguages(["en", "fr", "de"]),
            supportedLanguages: []
        )
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsViewAction(
            languageCode: "fr",
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.removeLanguage
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.pendingLanguages?.map { $0.code }, ["en", "de"])
        XCTAssertEqual(newState.preferredLanguages, makeLanguages(["en", "fr", "de"]))
    }

    func test_removeLanguage_whenNoPending_removesFromPreferred() {
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            isEditing: true,
            preferredLanguages: makeLanguages(["en", "fr"]),
            supportedLanguages: []
        )
        let reducer = translationSettingsReducer()

        let action = TranslationSettingsViewAction(
            languageCode: "en",
            windowUUID: .XCTestDefaultUUID,
            actionType: TranslationSettingsViewActionType.removeLanguage
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.pendingLanguages?.map { $0.code }, ["fr"])
    }

    // MARK: - Reducer Tests - didUpdateSettings

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

    func test_didUpdateSettings_preservesLanguagesWhenNil() {
        let languages = makeLanguages(["en", "fr"])
        let initialState = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: languages,
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
        XCTAssertEqual(newState.preferredLanguages, languages)
        XCTAssertEqual(newState.supportedLanguages, ["en", "fr", "de"])
    }

    // MARK: - Equality Tests

    func test_equality_sameValues_returnsTrue() {
        let languages = makeLanguages(["en"])
        let state1 = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: languages,
            supportedLanguages: ["en", "fr"]
        )
        let state2 = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: languages,
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
            preferredLanguages: makeLanguages(["en"]),
            supportedLanguages: []
        )

        XCTAssertNotEqual(state1, state2)
    }

    func test_equality_differentAutoTranslate_notEqual() {
        let state1 = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            isAutoTranslateEnabled: false,
            preferredLanguages: [],
            supportedLanguages: []
        )
        let state2 = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            isAutoTranslateEnabled: true,
            preferredLanguages: [],
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

    private func makeLanguages(_ codes: [String]) -> [PreferredLanguageDetails] {
        return codes.map { PreferredLanguageDetails(code: $0, mainText: $0, subtitleText: nil) }
    }
}
