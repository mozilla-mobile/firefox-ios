// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import XCTest

@testable import Client

@MainActor
final class WebCompatReporterStateTests: XCTestCase {
    // MARK: - Initialization

    func test_initWithWindowUUID_returnsDefaultDraft() {
        let subject = createSubject()

        XCTAssertEqual(subject.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(subject.url, "")
        XCTAssertNil(subject.selectedCategory)
        XCTAssertNil(subject.selectedSubOptionID)
        XCTAssertEqual(subject.additionalDetails, "")
        XCTAssertTrue(subject.includeScreenshot)
        XCTAssertFalse(subject.includeBlockedList)
    }

    func test_canSubmitAndCanPreview_falseUntilCategorySelected() {
        let withoutCategory = createSubject()
        XCTAssertFalse(withoutCategory.canSubmit)
        XCTAssertFalse(withoutCategory.canPreview)

        let withCategory = WebCompatReporterState(
            windowUUID: .XCTestDefaultUUID,
            url: "https://example.com",
            selectedCategory: .siteNotUsable
        )
        XCTAssertTrue(withCategory.canSubmit)
        XCTAssertTrue(withCategory.canPreview)
    }

    // MARK: - Reducer - didLoadInitialDraft

    func test_didLoadInitialDraft_seedsURL() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterMiddlewareAction(
            url: "https://example.com",
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterMiddlewareActionType.didLoadInitialDraft
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.url, "https://example.com")
    }

    func test_didLoadInitialDraft_withNilURL_preservesExistingURL() {
        let initialState = WebCompatReporterState(windowUUID: .XCTestDefaultUUID, url: "https://existing.com")
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterMiddlewareActionType.didLoadInitialDraft
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.url, "https://existing.com")
    }

    // MARK: - Reducer - editURL

    func test_editURL_updatesURL() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            url: "https://edited.com",
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.editURL
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.url, "https://edited.com")
    }

    // MARK: - Reducer - selectCategory

    func test_selectCategory_setsCategory() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            category: .videoOrAudio,
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectCategory
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.selectedCategory, .videoOrAudio)
    }

    func test_selectCategory_clearsPreviousSubOption() {
        let initialState = WebCompatReporterState(
            windowUUID: .XCTestDefaultUUID,
            url: "",
            selectedCategory: .siteNotUsable,
            selectedSubOptionID: "page_not_loading"
        )
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            category: .designBroken,
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectCategory
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.selectedCategory, .designBroken)
        XCTAssertNil(newState.selectedSubOptionID)
    }

    func test_selectCategory_sameCategory_keepsSubOption() {
        let initialState = WebCompatReporterState(
            windowUUID: .XCTestDefaultUUID,
            url: "",
            selectedCategory: .siteNotUsable,
            selectedSubOptionID: "page_not_loading"
        )
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            category: .siteNotUsable,
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectCategory
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.selectedSubOptionID, "page_not_loading")
    }

    // MARK: - Reducer - selectSubOption

    func test_selectSubOption_setsSubOption() {
        let initialState = WebCompatReporterState(
            windowUUID: .XCTestDefaultUUID,
            url: "",
            selectedCategory: .siteNotUsable
        )
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            subOptionID: "missing_items",
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectSubOption
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.selectedSubOptionID, "missing_items")
    }

    // MARK: - Reducer - setAdditionalDetails

    func test_setAdditionalDetails_updatesDetails() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            additionalDetails: "Buttons are unresponsive",
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.setAdditionalDetails
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState.additionalDetails, "Buttons are unresponsive")
    }

    // MARK: - Reducer - toggles

    func test_toggleScreenshot_withoutValue_flipsCurrent() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.toggleScreenshot
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.includeScreenshot)
    }

    func test_toggleScreenshot_withExplicitValue_setsValue() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            includeScreenshot: false,
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.toggleScreenshot
        )

        let newState = reducer(initialState, action)

        XCTAssertFalse(newState.includeScreenshot)
    }

    func test_toggleBlockedList_withoutValue_flipsCurrent() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.toggleBlockedList
        )

        let newState = reducer(initialState, action)

        XCTAssertTrue(newState.includeBlockedList)
    }

    // MARK: - Edge Cases

    func test_unknownAction_returnsDefaultState() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        struct UnknownAction: Action {
            let windowUUID: WindowUUID
            let actionType: ActionType
        }

        let action = UnknownAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterMiddlewareActionType.didLoadInitialDraft
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState, initialState)
    }

    func test_actionWithDifferentWindowUUID_returnsDefaultState() {
        let initialState = WebCompatReporterState(windowUUID: .XCTestDefaultUUID, url: "https://example.com")
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            url: "https://other.com",
            windowUUID: WindowUUID(),
            actionType: WebCompatReporterViewActionType.editURL
        )

        let newState = reducer(initialState, action)

        XCTAssertEqual(newState, initialState)
    }

    // MARK: - Equality

    func test_equality_sameValues_returnsTrue() {
        let state1 = WebCompatReporterState(windowUUID: .XCTestDefaultUUID, url: "https://example.com")
        let state2 = WebCompatReporterState(windowUUID: .XCTestDefaultUUID, url: "https://example.com")

        XCTAssertEqual(state1, state2)
    }

    func test_equality_differentURL_returnsFalse() {
        let state1 = WebCompatReporterState(windowUUID: .XCTestDefaultUUID, url: "https://a.com")
        let state2 = WebCompatReporterState(windowUUID: .XCTestDefaultUUID, url: "https://b.com")

        XCTAssertNotEqual(state1, state2)
    }

    // MARK: - WebCompatIssueCategory

    func test_category_idMatchesRawValue() {
        for category in WebCompatIssueCategory.allCases {
            XCTAssertEqual(category.id, category.rawValue)
        }
    }

    func test_category_subOptionIDs_matchGleanReasonKeys() {
        XCTAssertEqual(
            WebCompatIssueCategory.siteNotUsable.subOptionIDs,
            ["browser_blocked", "page_not_loading", "missing_items", "buttons_not_working"]
        )
        XCTAssertEqual(
            WebCompatIssueCategory.designBroken.subOptionIDs,
            ["images_not_loaded", "items_overlapped", "items_misaligned", "items_not_visible"]
        )
        XCTAssertEqual(
            WebCompatIssueCategory.videoOrAudio.subOptionIDs,
            ["no_video", "no_audio", "media_controls_broken", "playback_fails", "captions_missing"]
        )
    }

    func test_category_other_hasNoSubOptions() {
        XCTAssertTrue(WebCompatIssueCategory.other.subOptionIDs.isEmpty)
    }

    // MARK: - Private Helpers

    private func createSubject() -> WebCompatReporterState {
        return WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
    }
}
