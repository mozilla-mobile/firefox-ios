// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

private class MockNavigationListItem: NavigationListItem {}

final class TranslationNavigationCacheTests: XCTestCase {
    private var subject: TranslationNavigationCache!
    private var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        mockProfile = MockProfile()
        subject = TranslationNavigationCache()
    }

    override func tearDown() {
        subject = nil
        mockProfile = nil
        super.tearDown()
    }

    // MARK: - savedTranslation

    func test_savedTranslation_returnsNilWhenEmpty() {
        let item = MockNavigationListItem()

        XCTAssertNil(subject.savedTranslation(for: item, tabUUID: "tab1"))
    }

    func test_savedTranslation_returnsNilForUnknownItem() {
        let savedItem = MockNavigationListItem()
        let unknownItem = MockNavigationListItem()
        let configuration = TranslationConfiguration(prefs: mockProfile.prefs, state: .active)

        subject.saveTranslation(configuration, for: savedItem, tabUUID: "tab1")

        XCTAssertNil(subject.savedTranslation(for: unknownItem, tabUUID: "tab1"))
    }

    func test_savedTranslation_returnsNilForDifferentTab() {
        let item = MockNavigationListItem()
        let configuration = TranslationConfiguration(prefs: mockProfile.prefs, state: .active)

        subject.saveTranslation(configuration, for: item, tabUUID: "tab1")

        XCTAssertNil(subject.savedTranslation(for: item, tabUUID: "tab2"))
    }

    // MARK: - saveTranslation

    func test_saveTranslation_retrievesSavedConfiguration() {
        let item = MockNavigationListItem()
        let configuration = TranslationConfiguration(
            prefs: mockProfile.prefs,
            state: .active,
            translatedToLanguage: "fr"
        )

        subject.saveTranslation(configuration, for: item, tabUUID: "tab1")

        let result = subject.savedTranslation(for: item, tabUUID: "tab1")
        XCTAssertEqual(result, configuration)
    }

    func test_saveTranslation_overwritesExistingEntry() {
        let item = MockNavigationListItem()
        let firstConfiguration = TranslationConfiguration(
            prefs: mockProfile.prefs,
            state: .active,
            translatedToLanguage: "fr"
        )
        let secondConfiguration = TranslationConfiguration(
            prefs: mockProfile.prefs,
            state: .active,
            translatedToLanguage: "de"
        )

        subject.saveTranslation(firstConfiguration, for: item, tabUUID: "tab1")
        subject.saveTranslation(secondConfiguration, for: item, tabUUID: "tab1")

        let result = subject.savedTranslation(for: item, tabUUID: "tab1")
        XCTAssertEqual(result, secondConfiguration)
    }

    func test_saveTranslation_isolatesEntriesByTab() {
        let item1 = MockNavigationListItem()
        let item2 = MockNavigationListItem()
        let configuration1 = TranslationConfiguration(
            prefs: mockProfile.prefs,
            state: .active,
            translatedToLanguage: "fr"
        )
        let configuration2 = TranslationConfiguration(
            prefs: mockProfile.prefs,
            state: .active,
            translatedToLanguage: "de"
        )

        subject.saveTranslation(configuration1, for: item1, tabUUID: "tab1")
        subject.saveTranslation(configuration2, for: item2, tabUUID: "tab2")

        XCTAssertEqual(subject.savedTranslation(for: item1, tabUUID: "tab1"), configuration1)
        XCTAssertEqual(subject.savedTranslation(for: item2, tabUUID: "tab2"), configuration2)
    }

    func test_saveTranslation_storesMultipleItemsPerTab() {
        let item1 = MockNavigationListItem()
        let item2 = MockNavigationListItem()
        let configuration1 = TranslationConfiguration(
            prefs: mockProfile.prefs,
            state: .active,
            translatedToLanguage: "fr"
        )
        let configuration2 = TranslationConfiguration(
            prefs: mockProfile.prefs,
            state: .active,
            translatedToLanguage: "de"
        )

        subject.saveTranslation(configuration1, for: item1, tabUUID: "tab1")
        subject.saveTranslation(configuration2, for: item2, tabUUID: "tab1")

        XCTAssertEqual(subject.savedTranslation(for: item1, tabUUID: "tab1"), configuration1)
        XCTAssertEqual(subject.savedTranslation(for: item2, tabUUID: "tab1"), configuration2)
    }

    // MARK: - clearTranslation

    func test_clearTranslation_removesEntry() {
        let item = MockNavigationListItem()
        let configuration = TranslationConfiguration(prefs: mockProfile.prefs, state: .active)

        subject.saveTranslation(configuration, for: item, tabUUID: "tab1")
        subject.clearTranslation(for: item, tabUUID: "tab1")

        XCTAssertNil(subject.savedTranslation(for: item, tabUUID: "tab1"))
    }

    func test_clearTranslation_doesNotAffectOtherItems() {
        let item1 = MockNavigationListItem()
        let item2 = MockNavigationListItem()
        let configuration1 = TranslationConfiguration(
            prefs: mockProfile.prefs,
            state: .active,
            translatedToLanguage: "fr"
        )
        let configuration2 = TranslationConfiguration(
            prefs: mockProfile.prefs,
            state: .active,
            translatedToLanguage: "de"
        )

        subject.saveTranslation(configuration1, for: item1, tabUUID: "tab1")
        subject.saveTranslation(configuration2, for: item2, tabUUID: "tab1")
        subject.clearTranslation(for: item1, tabUUID: "tab1")

        XCTAssertNil(subject.savedTranslation(for: item1, tabUUID: "tab1"))
        XCTAssertEqual(subject.savedTranslation(for: item2, tabUUID: "tab1"), configuration2)
    }

    func test_clearTranslation_doesNothingForUnknownItem() {
        let savedItem = MockNavigationListItem()
        let unknownItem = MockNavigationListItem()
        let configuration = TranslationConfiguration(prefs: mockProfile.prefs, state: .active)

        subject.saveTranslation(configuration, for: savedItem, tabUUID: "tab1")
        subject.clearTranslation(for: unknownItem, tabUUID: "tab1")

        XCTAssertEqual(subject.savedTranslation(for: savedItem, tabUUID: "tab1"), configuration)
    }
}
