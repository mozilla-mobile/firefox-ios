// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class TranslationSettingsDiffableDataSourceTests: XCTestCase {
    private var collectionView: UICollectionView!
    private var subject: TranslationSettingsDiffableDataSource!

    override func setUp() async throws {
        try await super.setUp()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        subject = makeDataSource()
    }

    override func tearDown() async throws {
        subject = nil
        collectionView = nil
        try await super.tearDown()
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

    func test_applySnapshot_languageItemsMatchStateOrder() {
        let details = [
            PreferredLanguageDetails(code: "en", mainText: "English", subtitleText: "Device Language"),
            PreferredLanguageDetails(code: "fr", mainText: "français", subtitleText: "French")
        ]
        let state = TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: true,
            preferredLanguages: details,
            supportedLanguages: ["en", "fr"]
        )

        subject.applySnapshot(state: state, animated: false)

        let items = subject.snapshot().itemIdentifiers(inSection: .preferredLanguages)
        XCTAssertEqual(items[0], .language(details[0]))
        XCTAssertEqual(items[1], .language(details[1]))
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

    private func makeDataSource() -> TranslationSettingsDiffableDataSource {
        return TranslationSettingsDiffableDataSource(
            collectionView: collectionView
        ) { _, _, _ in nil }
    }

    private func makeState(isEnabled: Bool, languages: [String]) -> TranslationSettingsState {
        let details = languages.map { PreferredLanguageDetails(code: $0, mainText: $0, subtitleText: nil) }
        return TranslationSettingsState(
            windowUUID: .XCTestDefaultUUID,
            isTranslationsEnabled: isEnabled,
            preferredLanguages: details,
            supportedLanguages: languages
        )
    }
}
