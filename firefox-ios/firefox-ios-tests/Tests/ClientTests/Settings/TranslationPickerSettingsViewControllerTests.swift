// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class TranslationPickerSettingsViewControllerTests: XCTestCase, StoreTestUtility {
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

    func test_init_noMemoryLeak() {
        let subject = createSubject()
        trackForMemoryLeaks(subject)
    }

    func test_init_setsTitle() {
        let subject = createSubject()
        XCTAssertEqual(subject.title, .Settings.Translation.Title)
    }

    // MARK: - newState

    func test_newState_withTranslationsEnabled_doesNotCrash() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        let state = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: ["en", "fr"],
            supportedLanguages: ["en", "fr", "de"]
        )
        subject.newState(state: state)
    }

    func test_newState_withTranslationsDisabled_doesNotCrash() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        let state = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: false,
            preferredLanguages: [],
            supportedLanguages: []
        )
        subject.newState(state: state)
    }

    func test_newState_calledTwice_doesNotCrash() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        subject.newState(state: TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: ["en"],
            supportedLanguages: ["en", "fr"]
        ))
        subject.newState(state: TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: false,
            preferredLanguages: [],
            supportedLanguages: []
        ))
    }

    // MARK: - viewDidDisappear

    func test_viewDidDisappear_doesNotCrash() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        subject.viewDidDisappear(false)
    }

    // MARK: - applyTheme

    func test_applyTheme_doesNotCrash() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        subject.newState(state: TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: ["en"],
            supportedLanguages: ["en", "fr"]
        ))
        subject.applyTheme()
    }

    func test_applyTheme_withTranslationsDisabled_doesNotCrash() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        subject.newState(state: TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: false,
            preferredLanguages: [],
            supportedLanguages: []
        ))
        subject.applyTheme()
    }

    // MARK: - UICollectionViewDelegate

    func test_shouldSelectItemAt_withNoMatchingItem_returnsFalse() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        let result = subject.collectionView(
            UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()),
            shouldSelectItemAt: IndexPath(item: 99, section: 99)
        )
        XCTAssertFalse(result)
    }

    // MARK: - Toggle

    func test_didToggleTranslations_doesNotCrash() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        let toggle = UISwitch()
        subject.perform(Selector(("didToggleTranslations:")), with: toggle)
    }

    // MARK: - nativeName

    func test_nativeName_returnsNonEmptyString() {
        let name = TranslationPickerSettingsViewController.nativeName(for: "en")
        XCTAssertFalse(name.isEmpty)
    }

    func test_nativeName_forUnknownCode_returnsFallback() {
        let name = TranslationPickerSettingsViewController.nativeName(for: "xyz")
        XCTAssertEqual(name, "xyz")
    }

    // MARK: - localizedName

    func test_localizedName_returnsNonEmptyString() {
        let name = TranslationPickerSettingsViewController.localizedName(for: "fr")
        XCTAssertFalse(name.isEmpty)
    }

    func test_localizedName_forUnknownCode_returnsFallback() {
        let name = TranslationPickerSettingsViewController.localizedName(for: "xyz")
        XCTAssertEqual(name, "xyz")
    }

    // MARK: - StoreTestUtility

    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
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

    private func createSubject() -> TranslationPickerSettingsViewController {
        let subject = TranslationPickerSettingsViewController(windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
