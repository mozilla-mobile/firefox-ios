// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Storage
import XCTest

@testable import Client

final class BookmarksSectionStateTests: XCTestCase {
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.bookmarks, [])
    }

    func test_initializeAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = bookmarksSectionReducer()

        let newState = reducer(
            initialState,
            HomepageAction(
                windowUUID: .XCTestDefaultUUID,
                actionType: HomepageActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.bookmarks.count, 0)
    }

    func test_fetchBookmarksAction_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = bookmarksSectionReducer()

        let newState = reducer(
            initialState,
            BookmarksAction(
                bookmarks: [BookmarkConfiguration(
                    site: Site.createBasicSite(
                        url: "www.mozilla.org",
                        title: "Bookmarks Title"
                    )
                )],
                windowUUID: .XCTestDefaultUUID,
                actionType: BookmarksMiddlewareActionType.initialize
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(newState.bookmarks.count, 1)
        XCTAssertEqual(newState.bookmarks.first?.site.url, "www.mozilla.org")
        XCTAssertEqual(newState.bookmarks.first?.site.title, "Bookmarks Title")
        XCTAssertEqual(newState.bookmarks.first?.accessibilityLabel, "Bookmarks Title")
    }

    func test_toggleShowSectionSetting_withToggleOn_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = bookmarksSectionReducer()

        let newState = reducer(
            initialState,
            BookmarksAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: BookmarksActionType.toggleShowSectionSetting
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertTrue(newState.shouldShowSection)
    }

    func test_toggleShowSectionSetting_withToggleOff_returnsExpectedState() {
        let initialState = createSubject()
        let reducer = bookmarksSectionReducer()

        let newState = reducer(
            initialState,
            BookmarksAction(
                isEnabled: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: BookmarksActionType.toggleShowSectionSetting
            )
        )

        XCTAssertEqual(newState.windowUUID, .XCTestDefaultUUID)
        XCTAssertFalse(newState.shouldShowSection)
    }

    func test_sectionFlagEnabled_withoutUserPref_returnsExpectedState() {
        setupNimbusHNTBookmarksSectionTesting(isEnabled: true)

        let initialState = createSubject()
        XCTAssertTrue(initialState.shouldShowSection)
    }

    func test_sectionFlagDisabled_withoutUserPref_returnsExpectedState() {
        setupNimbusHNTBookmarksSectionTesting(isEnabled: false)

        let initialState = createSubject()
        XCTAssertFalse(initialState.shouldShowSection)
    }

    func test_sectionFlagEnabled_withUserPref_returnsExpectedState() {
        setupNimbusHNTBookmarksSectionTesting(isEnabled: true)

        let initialState = createSubject()
        let reducer = bookmarksSectionReducer()

        // Updates the bookmarks section user pref
        let newState = reducer(
            initialState,
            BookmarksAction(
                isEnabled: false,
                windowUUID: .XCTestDefaultUUID,
                actionType: BookmarksActionType.toggleShowSectionSetting
            )
        )
        XCTAssertFalse(newState.shouldShowSection)
    }

    func test_sectionFlagDisabled_withUserPref_returnsExpectedState() {
        setupNimbusHNTBookmarksSectionTesting(isEnabled: false)

        let initialState = createSubject()
        let reducer = bookmarksSectionReducer()

        // Updates the bookmarks section user pref
        let newState = reducer(
            initialState,
            BookmarksAction(
                isEnabled: true,
                windowUUID: .XCTestDefaultUUID,
                actionType: BookmarksActionType.toggleShowSectionSetting
            )
        )
        XCTAssertTrue(newState.shouldShowSection)
    }

    // MARK: - Private
    private func createSubject() -> BookmarksSectionState {
        return BookmarksSectionState(windowUUID: .XCTestDefaultUUID)
    }

    private func bookmarksSectionReducer() -> Reducer<BookmarksSectionState> {
        return BookmarksSectionState.reducer
    }

    private func setupNimbusHNTBookmarksSectionTesting(isEnabled: Bool) {
        FxNimbus.shared.features.hntBookmarksSectionFeature.with { _, _ in
            return HntBookmarksSectionFeature(
                enabled: isEnabled
            )
        }
    }
}
