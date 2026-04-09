// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import XCTest

@testable import Client

@MainActor
final class TranslationLanguagePickerViewControllerTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        resetStore()
        try await super.tearDown()
    }

    // MARK: - Init

    func test_init_setsTitle() {
        let subject = createSubject()
        XCTAssertEqual(subject.title, .Settings.Translation.LanguagePicker.NavTitle)
    }

    // MARK: - Row count

    func test_numberOfRows_withNoPreferred_equalsAllSupported() {
        let subject = createSubject(
            preferredLanguages: [],
            supportedLanguages: ["en", "fr", "de"]
        )
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.tableView(UITableView(), numberOfRowsInSection: 0), 3)
    }

    func test_numberOfRows_excludesAlreadyPreferredLanguages() {
        let subject = createSubject(
            preferredLanguages: ["en"],
            supportedLanguages: ["en", "fr", "de"]
        )
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.tableView(UITableView(), numberOfRowsInSection: 0), 2)
    }

    func test_numberOfRows_withAllLanguagesPreferred_returnsZero() {
        let subject = createSubject(
            preferredLanguages: ["en", "fr"],
            supportedLanguages: ["en", "fr"]
        )
        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.tableView(UITableView(), numberOfRowsInSection: 0), 0)
    }

    // MARK: - Search filtering

    func test_updateSearchResults_withEmptyQuery_showsAllLanguages() {
        let subject = createSubject(
            preferredLanguages: [],
            supportedLanguages: ["en", "fr", "de"]
        )
        subject.loadViewIfNeeded()

        subject.updateSearchResults(for: UISearchController())

        XCTAssertEqual(subject.tableView(UITableView(), numberOfRowsInSection: 0), 3)
    }

    // MARK: - Selection

    func test_didSelectRow_dispatchesAddLanguageAction() throws {
        let subject = createSubject(
            preferredLanguages: [],
            supportedLanguages: ["fr", "de"]
        )
        subject.loadViewIfNeeded()

        subject.tableView(UITableView(), didSelectRowAt: IndexPath(row: 0, section: 0))

        let dispatchedAction = try XCTUnwrap(mockStore.dispatchedActions.first as? TranslationSettingsViewAction)
        let dispatchedActionType = try XCTUnwrap(dispatchedAction.actionType as? TranslationSettingsViewActionType)
        XCTAssertEqual(dispatchedActionType, TranslationSettingsViewActionType.addLanguage)
        XCTAssertNotNil(dispatchedAction.languageCode)
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        return AppState(
            presentedComponents: PresentedComponentsState(
                components: [
                    .translationSettings(
                        TranslationSettingsState(windowUUID: .XCTestDefaultUUID)
                    )
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }

    // MARK: - Helpers

    private func createSubject(
        preferredLanguages: [String] = [],
        supportedLanguages: [String] = ["en", "fr"],
        localeCode: String = "en"
    ) -> TranslationLanguagePickerViewController {
        let preferred = Set(preferredLanguages)
        let available = supportedLanguages.filter { !preferred.contains($0) }
        let subject = TranslationLanguagePickerViewController(
            windowUUID: .XCTestDefaultUUID,
            languages: available,
            localeProvider: MockLocaleProvider(current: Locale(identifier: localeCode))
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
