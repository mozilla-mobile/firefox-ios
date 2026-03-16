// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

<<<<<<< HEAD
import UIKit
=======
>>>>>>> ea63855905 (Add TranslationPickerSettingsViewController unit tests)
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
<<<<<<< HEAD
        subject.newState(state: TranslationSettingsState(
=======
        let state = TranslationSettingsState(
>>>>>>> ea63855905 (Add TranslationPickerSettingsViewController unit tests)
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: ["en", "fr"],
            supportedLanguages: ["en", "fr", "de"]
<<<<<<< HEAD
        ))
=======
        )
        subject.newState(state: state)
>>>>>>> ea63855905 (Add TranslationPickerSettingsViewController unit tests)
    }

    func test_newState_withTranslationsDisabled_doesNotCrash() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
<<<<<<< HEAD
=======
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
>>>>>>> ea63855905 (Add TranslationPickerSettingsViewController unit tests)
        subject.newState(state: TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: false,
            preferredLanguages: [],
            supportedLanguages: []
        ))
    }

<<<<<<< HEAD
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
        subject.applyTheme()
    }

    // MARK: - collectionView delegate

    func test_shouldSelectItem_returnsFalse() {
        let subject = createSubject()
        subject.loadViewIfNeeded()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let result = subject.collectionView(collectionView, shouldSelectItemAt: IndexPath(item: 0, section: 0))
        XCTAssertFalse(result)
    }

=======
>>>>>>> ea63855905 (Add TranslationPickerSettingsViewController unit tests)
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

<<<<<<< HEAD
    func test_localizedName_withInjectedLocale_returnsExpectedString() {
        let name = TranslationPickerSettingsViewController.localizedName(for: "fr", locale: Locale(identifier: "en"))
        XCTAssertEqual(name, "French")
    }

    func test_localizedName_forUnknownCode_returnsFallback() {
        let name = TranslationPickerSettingsViewController.localizedName(for: "xyz", locale: Locale(identifier: "en"))
=======
    func test_localizedName_returnsNonEmptyString() {
        let name = TranslationPickerSettingsViewController.localizedName(for: "fr")
        XCTAssertFalse(name.isEmpty)
    }

    func test_localizedName_forUnknownCode_returnsFallback() {
        let name = TranslationPickerSettingsViewController.localizedName(for: "xyz")
>>>>>>> ea63855905 (Add TranslationPickerSettingsViewController unit tests)
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
