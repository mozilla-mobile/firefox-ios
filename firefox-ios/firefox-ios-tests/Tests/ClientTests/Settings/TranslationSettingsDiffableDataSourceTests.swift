// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class TranslationSettingsDiffableDataSourceTests: XCTestCase {
    private var collectionView: UICollectionView!
    private var subject: TranslationSettingsDiffableDataSource!

    override func setUp() {
        super.setUp()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        subject = makeDataSource(localeCode: "en")
    }

    override func tearDown() {
        subject = nil
        collectionView = nil
        super.tearDown()
    }

    // MARK: - applySnapshot — section structure

    func test_applySnapshot_withTranslationsDisabled_onlyHasToggleSection() {
        let state = makeState(isEnabled: false, languages: [])

        subject.applySnapshot(state: state, animated: false)

        let snapshot = subject.snapshot()
        XCTAssertEqual(snapshot.sectionIdentifiers, [.enableToggle])
        XCTAssertEqual(snapshot.itemIdentifiers(inSection: .enableToggle), [.enableToggle])
    }

    func test_applySnapshot_withTranslationsEnabled_hasBothSections() {
        let state = makeState(isEnabled: true, languages: ["en", "fr"])

        subject.applySnapshot(state: state, animated: false)

        let snapshot = subject.snapshot()
        XCTAssertEqual(snapshot.sectionIdentifiers, [.enableToggle, .preferredLanguages])
    }

    func test_applySnapshot_withTranslationsEnabled_noLanguages_hasEmptyLanguageSection() {
        let state = makeState(isEnabled: true, languages: [])

        subject.applySnapshot(state: state, animated: false)

        let snapshot = subject.snapshot()
        XCTAssertEqual(snapshot.sectionIdentifiers, [.enableToggle, .preferredLanguages])
        XCTAssertEqual(snapshot.numberOfItems(inSection: .preferredLanguages), 0)
    }

    func test_applySnapshot_withTranslationsEnabled_languageItemCountMatchesState() {
        let state = makeState(isEnabled: true, languages: ["en", "fr", "de"])

        subject.applySnapshot(state: state, animated: false)

        XCTAssertEqual(subject.snapshot().numberOfItems(inSection: .preferredLanguages), 3)
    }

    // MARK: - applySnapshot — device language marking

    func test_applySnapshot_firstLanguageMatchesLocale_markedAsDeviceLanguage() {
        subject = makeDataSource(localeCode: "en")
        let state = makeState(isEnabled: true, languages: ["en", "fr"])

        subject.applySnapshot(state: state, animated: false)

        let items = subject.snapshot().itemIdentifiers(inSection: .preferredLanguages)
        XCTAssertEqual(items[0], .language(code: "en", isDeviceLanguage: true))
        XCTAssertEqual(items[1], .language(code: "fr", isDeviceLanguage: false))
    }

    func test_applySnapshot_localeMatchesButNotFirst_notMarkedAsDeviceLanguage() {
        subject = makeDataSource(localeCode: "en")
        let state = makeState(isEnabled: true, languages: ["fr", "en"])

        subject.applySnapshot(state: state, animated: false)

        let items = subject.snapshot().itemIdentifiers(inSection: .preferredLanguages)
        XCTAssertEqual(items[0], .language(code: "fr", isDeviceLanguage: false))
        XCTAssertEqual(items[1], .language(code: "en", isDeviceLanguage: false))
    }

    func test_applySnapshot_localeDoesNotMatchAnyLanguage_noneMarkedAsDeviceLanguage() {
        subject = makeDataSource(localeCode: "de")
        let state = makeState(isEnabled: true, languages: ["en", "fr"])

        subject.applySnapshot(state: state, animated: false)

        let items = subject.snapshot().itemIdentifiers(inSection: .preferredLanguages)
        XCTAssertEqual(items[0], .language(code: "en", isDeviceLanguage: false))
        XCTAssertEqual(items[1], .language(code: "fr", isDeviceLanguage: false))
    }

    // MARK: - reconfigureVisibleCells

    func test_reconfigureVisibleCells_withEmptySnapshot_doesNotCrash() {
        subject.reconfigureVisibleCells()
    }

    func test_reconfigureVisibleCells_withPopulatedSnapshot_doesNotCrash() {
        subject.applySnapshot(state: makeState(isEnabled: true, languages: ["en"]), animated: false)
        subject.reconfigureVisibleCells()
    }

    // MARK: - Helpers

    private func makeDataSource(localeCode: String) -> TranslationSettingsDiffableDataSource {
        let localeProvider = MockLocaleProvider(current: Locale(identifier: localeCode))
        return TranslationSettingsDiffableDataSource(
            collectionView: collectionView,
            localeProvider: localeProvider
        ) { _, _, _ in nil }
    }

    private func makeState(isEnabled: Bool, languages: [String]) -> TranslationSettingsState {
        return TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: isEnabled,
            preferredLanguages: languages,
            supportedLanguages: languages
        )
    }
}
