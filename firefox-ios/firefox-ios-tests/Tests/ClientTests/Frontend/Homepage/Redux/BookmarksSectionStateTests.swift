// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared
import Storage
import XCTest

@testable import Client

final class BookmarksSectionStateTests: XCTestCase {
    private var mockProfile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        await DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        mockProfile = nil
        try await super.tearDown()
    }

    func tests_initialState_returnsExpectedState() {
        let initialState = createSubject()

        XCTAssertEqual(initialState.windowUUID, .XCTestDefaultUUID)
        XCTAssertEqual(initialState.bookmarks, [])
    }

    @MainActor
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

    @MainActor
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

    @MainActor
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

    @MainActor
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

    func test_storiesDisabled_returnsExpectedState() {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)

        let initialState = createSubject()
        XCTAssertTrue(initialState.shouldShowSection)
    }

    func test_storiesEnabled_returnsExpectedState() {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: true)

        let initialState = createSubject()
        XCTAssertFalse(initialState.shouldShowSection)
    }

    func test_storiesDisabled_prefDisabled_returnsExpectedState() {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.BookmarksSection)

        let initialState = createSubject()
        XCTAssertFalse(initialState.shouldShowSection)
    }

    func test_storiesDisabled_prefEnabled_returnsExpectedState() {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: false)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.HomepageSettings.BookmarksSection)

        let initialState = createSubject()
        XCTAssertTrue(initialState.shouldShowSection)
    }

    func test_storiesEnabled_prefDisabled_returnsExpectedState() {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: true)
        mockProfile.prefs.setBool(false, forKey: PrefsKeys.HomepageSettings.BookmarksSection)

        let initialState = createSubject()
        XCTAssertFalse(initialState.shouldShowSection)
    }

    func test_storiesEnabled_prefEnabled_returnsExpectedState() {
        setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: true)
        mockProfile.prefs.setBool(true, forKey: PrefsKeys.HomepageSettings.BookmarksSection)

        let initialState = createSubject()
        XCTAssertFalse(initialState.shouldShowSection)
    }

    // MARK: - Private
    private func createSubject() -> BookmarksSectionState {
        return BookmarksSectionState(profile: mockProfile, windowUUID: .XCTestDefaultUUID)
    }

    private func bookmarksSectionReducer() -> Reducer<BookmarksSectionState> {
        return BookmarksSectionState.reducer
    }

    private func setupNimbusHomepageRedesignTesting(storiesRedesignEnabled: Bool) {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            return HomepageRedesignFeature(
                storiesRedesign: storiesRedesignEnabled
            )
        }
    }
}
