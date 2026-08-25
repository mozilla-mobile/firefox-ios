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
        XCTAssertTrue(subject.includeBlockedList)
    }

    func test_canPreview_falseUntilCategorySelected() {
        XCTAssertFalse(createSubject().canPreview)

        let withCategory = WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
            .copy(url: "https://example.com")
            .copy(selectedCategory: .siteNotUsable)
        XCTAssertTrue(withCategory.canPreview)
    }

    func test_canSubmit_needsASubOptionUnlessTheCategoryHasNone() {
        XCTAssertFalse(createSubject().canSubmit)
        XCTAssertFalse(makeState(category: .siteNotUsable).canSubmit)
        XCTAssertTrue(
            makeState(category: .siteNotUsable, subOption: .pageNotLoading).canSubmit
        )
        XCTAssertTrue(makeState(category: .other).canSubmit)
    }

    func test_canSubmit_falseWhenTheURLHasBeenClearedOrIsBlank() {
        XCTAssertFalse(makeState(category: .other, url: "").canSubmit)
        XCTAssertFalse(makeState(category: .other, url: "   ").canSubmit)
    }

    func test_isURLValid_rejectsLookalikesAndBlocksSendAndPreview() {
        for url in ["https://example.com", "example.com", "ebay.com/deals?a=1", "https://sub.example.co.uk"] {
            XCTAssertTrue(makeState(category: .other, url: url).isURLValid, "Expected \(url) to be reportable")
        }
        for url in [" .com", ".com", "example..com", "example.com.", "https://exa mple.com", "https://", "foo"] {
            XCTAssertFalse(makeState(category: .other, url: url).isURLValid, "Expected \(url) to be rejected")
        }

        let subject = makeState(category: .other, url: ".com")
        XCTAssertFalse(subject.canSubmit)
        XCTAssertFalse(subject.canPreview)
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

        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState.url, "https://example.com")
    }

    func test_didLoadInitialDraft_withNilURL_preservesExistingURL() {
        let initialState = WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
            .copy(url: "https://existing.com")
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterMiddlewareActionType.didLoadInitialDraft
        )

        let newState = reducer.legacyReducer(initialState, action)

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

        let newState = reducer.legacyReducer(initialState, action)

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

        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState.selectedCategory, .videoOrAudio)
    }

    func test_selectCategory_clearsPreviousSubOption() {
        let initialState = WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
            .copy(selectedCategory: .siteNotUsable)
            .copy(selectedSubOptionID: "page_not_loading")
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            category: .designBroken,
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectCategory
        )

        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState.selectedCategory, .designBroken)
        XCTAssertNil(newState.selectedSubOptionID)
    }

    func test_selectCategory_sameCategory_keepsSubOption() {
        let initialState = WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
            .copy(selectedCategory: .siteNotUsable)
            .copy(selectedSubOptionID: "page_not_loading")
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            category: .siteNotUsable,
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectCategory
        )

        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState.selectedSubOptionID, "page_not_loading")
    }

    // MARK: - Reducer - selectSubOption

    func test_selectSubOption_setsSubOption() {
        let initialState = WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
            .copy(selectedCategory: .siteNotUsable)
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            subOptionID: "missing_items",
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.selectSubOption
        )

        let newState = reducer.legacyReducer(initialState, action)

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

        let newState = reducer.legacyReducer(initialState, action)

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

        let newState = reducer.legacyReducer(initialState, action)

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

        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertFalse(newState.includeScreenshot)
    }

    func test_toggleBlockedList_withoutValue_flipsCurrent() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.toggleBlockedList
        )

        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertFalse(newState.includeBlockedList)
    }

    // MARK: - didSubmit

    func test_didSubmit_setsShouldDismiss() {
        let initialState = createSubject()
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterMiddlewareActionType.didSubmit
        )

        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertTrue(newState.shouldDismiss)
    }

    func test_actionAfterDidSubmit_clearsShouldDismiss() {
        let reducer = WebCompatReporterState.reducer
        let submitted = reducer.legacyReducer(createSubject(), WebCompatReporterMiddlewareAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterMiddlewareActionType.didSubmit
        ))

        let newState = reducer.legacyReducer(submitted, WebCompatReporterViewAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: WebCompatReporterViewActionType.toggleBlockedList
        ))

        XCTAssertFalse(newState.shouldDismiss)
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

        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState, initialState)
    }

    func test_actionWithDifferentWindowUUID_returnsDefaultState() {
        let initialState = WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
            .copy(url: "https://example.com")
        let reducer = WebCompatReporterState.reducer

        let action = WebCompatReporterViewAction(
            url: "https://other.com",
            windowUUID: WindowUUID(),
            actionType: WebCompatReporterViewActionType.editURL
        )

        let newState = reducer.legacyReducer(initialState, action)

        XCTAssertEqual(newState, initialState)
    }

    // MARK: - previewPayload

    func test_didReadPageContext_carriesThePageContextIntoState() {
        let reducer = WebCompatReporterState.reducer
        let pageContext = WebCompatPageContext(languages: ["en-GB"], fastclick: true)

        let newState = reducer.legacyReducer(
            WebCompatReporterState(windowUUID: .XCTestDefaultUUID),
            WebCompatReporterMiddlewareAction(
                pageContext: pageContext,
                windowUUID: .XCTestDefaultUUID,
                actionType: WebCompatReporterMiddlewareActionType.didReadPageContext
            )
        )

        XCTAssertEqual(newState.pageContext, pageContext)
    }

    func test_pageContext_survivesLaterActions() {
        let reducer = WebCompatReporterState.reducer
        let initialState = WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
            .copy(url: "https://example.com")
            .copy(pageContext: WebCompatPageContext(languages: ["en-GB"]))

        let newState = reducer.legacyReducer(
            initialState,
            WebCompatReporterViewAction(
                category: .siteNotUsable,
                windowUUID: .XCTestDefaultUUID,
                actionType: WebCompatReporterViewActionType.selectCategory
            )
        )

        XCTAssertEqual(newState.pageContext?.languages, ["en-GB"])
    }

    func test_didBuildPreview_carriesThePayloadIntoState() {
        var payload = WebCompatReportPayload()
        payload.url = "https://example.com"
        let reducer = WebCompatReporterState.reducer

        let newState = reducer.legacyReducer(
            WebCompatReporterState(windowUUID: .XCTestDefaultUUID),
            WebCompatReporterMiddlewareAction(
                previewPayload: payload,
                windowUUID: .XCTestDefaultUUID,
                actionType: WebCompatReporterMiddlewareActionType.didBuildPreview
            )
        )

        XCTAssertEqual(newState.previewPayload, payload)
    }

    func test_previewPayload_doesNotSurviveTheNextAction() {
        // Without the clear, previewing twice without editing leaves state unchanged and never reopens.
        var payload = WebCompatReportPayload()
        payload.url = "https://example.com"
        let initialState = WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
            .copy(url: "https://example.com")
            .copy(previewPayload: payload)
        let reducer = WebCompatReporterState.reducer

        let newState = reducer.legacyReducer(
            initialState,
            WebCompatReporterViewAction(
                url: "https://changed.com",
                windowUUID: .XCTestDefaultUUID,
                actionType: WebCompatReporterViewActionType.editURL
            )
        )

        XCTAssertNil(newState.previewPayload)
    }

    // MARK: - Equality

    func test_equality_sameValues_returnsTrue() {
        let state1 = WebCompatReporterState(windowUUID: .XCTestDefaultUUID).copy(url: "https://example.com")
        let state2 = WebCompatReporterState(windowUUID: .XCTestDefaultUUID).copy(url: "https://example.com")

        XCTAssertEqual(state1, state2)
    }

    func test_equality_differentURL_returnsFalse() {
        let state1 = WebCompatReporterState(windowUUID: .XCTestDefaultUUID).copy(url: "https://a.com")
        let state2 = WebCompatReporterState(windowUUID: .XCTestDefaultUUID).copy(url: "https://b.com")

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
            WebCompatIssueCategory.siteNotUsable.subOptions.map(\.rawValue),
            ["browser_blocked", "page_not_loading", "missing_items", "buttons_not_working"]
        )
        XCTAssertEqual(
            WebCompatIssueCategory.designBroken.subOptions.map(\.rawValue),
            ["images_not_loaded", "items_overlapped", "items_misaligned", "items_not_visible"]
        )
        XCTAssertEqual(
            WebCompatIssueCategory.videoOrAudio.subOptions.map(\.rawValue),
            ["no_video", "no_audio", "media_controls_broken", "playback_fails", "captions_missing"]
        )
    }

    func test_category_other_hasNoSubOptions() {
        XCTAssertTrue(WebCompatIssueCategory.other.subOptions.isEmpty)
    }

    // MARK: - Private Helpers

    private func makeState(
        category: WebCompatIssueCategory,
        subOption: WebCompatSubOption? = nil,
        url: String = "https://example.com"
    ) -> WebCompatReporterState {
        return WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
            .copy(url: url)
            .copy(selectedCategory: category)
            .copy(selectedSubOptionID: subOption?.rawValue)
    }

    private func createSubject() -> WebCompatReporterState {
        return WebCompatReporterState(windowUUID: .XCTestDefaultUUID)
    }
}
