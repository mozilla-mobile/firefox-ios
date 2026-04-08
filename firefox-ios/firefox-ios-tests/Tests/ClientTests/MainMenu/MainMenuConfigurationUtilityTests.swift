// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared
import SummarizeKit

@testable import Client

@MainActor
final class MainMenuConfigurationUtilityTests: XCTestCase {
    private var configUtility: MainMenuConfigurationUtility!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
        setIsSummarizerLanguageExpansionEnabled(false)
        configUtility = MainMenuConfigurationUtility()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        configUtility = nil
        try await super.tearDown()
    }

    func testGenerateMenuElements_returnsHomepageSections_whenIsHomepageTrue() {
        let sections = configUtility.generateMenuElements(with: getTabInfo(isHomepage: true), and: windowUUID)

        XCTAssertEqual(sections.count, 2)
        XCTAssertTrue(sections[0].isHorizontalTabsSection)
    }

    func testGenerateMenuElements_returnsAllSections_whenIsHomepageFalse() {
        let sections = configUtility.generateMenuElements(with: getTabInfo(), and: windowUUID)

        XCTAssertEqual(sections.count, 3)
        XCTAssertFalse(sections[0].isHorizontalTabsSection)
    }

    func testGenerateMenuElements_siteSectionHasMoreOptions_whenIsExpandedFalse() {
        let sections = configUtility.generateMenuElements(with: getTabInfo(), and: windowUUID, isExpanded: false)

        let siteSection = sections.first!
        let moreLessItem = siteSection.options.last!
        XCTAssertEqual(moreLessItem.title, String.MainMenu.ToolsSection.MoreOptions)
    }

    func testGenerateMenuElements_siteSectionHasZoomAndPrint_whenIsExpandedTrue() {
        let sections = configUtility.generateMenuElements(with: getTabInfo(), and: windowUUID, isExpanded: true)

        let siteSection = sections.first!
        let titles = siteSection.options.map { $0.title }

        XCTAssertTrue(titles.contains(String.MainMenu.Submenus.Tools.PageZoom))
        XCTAssertTrue(titles.contains(String.MainMenu.Submenus.Tools.Print))
    }

    func testGenerateMenuElements_readerViewItem_whenSummarizerLanguageExpansionEnabled() {
        setIsSummarizerLanguageExpansionEnabled(true)
        let sections = configUtility.generateMenuElements(with: getTabInfo(), and: windowUUID, isExpanded: true)

        let allItems = sections.flatMap { $0.options }
        let titles = allItems.map { $0.title }

        XCTAssertTrue(titles.contains(.MainMenu.ToolsSection.ReaderViewTitle))
    }

    func testGenerateMenuElements_readerViewItem_whenSummarizerLanguageExpansionDisabled() {
        let sections = configUtility.generateMenuElements(with: getTabInfo(), and: windowUUID, isExpanded: true)

        let allItems = sections.flatMap { $0.options }
        let titles = allItems.map { $0.title }

        XCTAssertFalse(titles.contains(.MainMenu.ToolsSection.ReaderViewTitle))
    }

    // MARK: - Translation item

    func test_translateItem_notPresent_whenFlagDisabled() {
        setLanguagePickerEnabled(false)
        let mockProfile = MockProfile()
        let config = TranslationConfiguration(prefs: mockProfile.prefs, state: .inactive)
        let tabInfo = getTabInfo(translationConfiguration: config)

        let sections = configUtility.generateMenuElements(
            with: tabInfo,
            and: windowUUID,
            isExpanded: true,
            localeProvider: MockLocaleProvider(current: Locale(identifier: "en"))
        )
        let allTitles = sections.flatMap { $0.options }.map { $0.title }

        XCTAssertFalse(allTitles.contains(.MainMenu.ToolsSection.Translation.TranslatePageTitleMultiLanguage))
    }

    func test_translateItem_inactive_whenStateIsInactive() {
        setLanguagePickerEnabled(true)
        let mockProfile = MockProfile()
        let config = TranslationConfiguration(prefs: mockProfile.prefs, state: .inactive)
        let tabInfo = getTabInfo(translationConfiguration: config)

        let sections = configUtility.generateMenuElements(
            with: tabInfo,
            and: windowUUID,
            isExpanded: true,
            localeProvider: MockLocaleProvider(current: Locale(identifier: "en"))
        )
        let allItems = sections.flatMap { $0.options }
        let translateItem = allItems.first { $0.title == .MainMenu.ToolsSection.Translation.TranslatePageTitle }

        XCTAssertNotNil(translateItem)
    }

    func test_translateItem_active_whenStateIsActive() {
        setLanguagePickerEnabled(true)
        let mockProfile = MockProfile()
        let config = TranslationConfiguration(prefs: mockProfile.prefs, state: .active, translatedToLanguage: "fr")
        let tabInfo = getTabInfo(translationConfiguration: config)

        let sections = configUtility.generateMenuElements(
            with: tabInfo,
            and: windowUUID,
            isExpanded: true,
            localeProvider: MockLocaleProvider(current: Locale(identifier: "en"))
        )
        let allItems = sections.flatMap { $0.options }
        let title = String.MainMenu.ToolsSection.Translation.TranslatedPageTitle
        let translateItem = allItems.first { $0.title == title }

        XCTAssertNotNil(translateItem)
    }

    func test_translateItem_singleLanguage_inactive_showsNoEllipsis() {
        setLanguagePickerEnabled(true)
        let mockProfile = MockProfile()
        mockProfile.prefs.setString("en", forKey: PrefsKeys.Settings.translationPreferredLanguages)
        let config = TranslationConfiguration(prefs: mockProfile.prefs, state: .inactive)
        let tabInfo = getTabInfo(translationConfiguration: config)

        let sections = configUtility.generateMenuElements(
            with: tabInfo,
            and: windowUUID,
            isExpanded: true,
            localeProvider: MockLocaleProvider(current: Locale(identifier: "en"))
        )
        let allItems = sections.flatMap { $0.options }
        let translateItem = allItems.first { $0.title == .MainMenu.ToolsSection.Translation.TranslatePageTitle }

        XCTAssertNotNil(translateItem)
    }

    func test_translateItem_singleLanguage_active_showsNoEllipsis() {
        setLanguagePickerEnabled(true)
        let mockProfile = MockProfile()
        mockProfile.prefs.setString("en", forKey: PrefsKeys.Settings.translationPreferredLanguages)
        let config = TranslationConfiguration(prefs: mockProfile.prefs, state: .active, translatedToLanguage: "en")
        let tabInfo = getTabInfo(translationConfiguration: config)

        let sections = configUtility.generateMenuElements(
            with: tabInfo,
            and: windowUUID,
            isExpanded: true,
            localeProvider: MockLocaleProvider(current: Locale(identifier: "en"))
        )
        let allItems = sections.flatMap { $0.options }
        let translateItem = allItems.first { $0.title == .MainMenu.ToolsSection.Translation.TranslatedPageTitle }

        XCTAssertNotNil(translateItem)
    }

    private func setIsSummarizerLanguageExpansionEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.summarizerLanguageExpansionFeature.with { _, _ in
            return SummarizerLanguageExpansionFeature(enabled: enabled)
        }
    }

    private func getTabInfo(
        isHomepage: Bool = false,
        translationConfiguration: TranslationConfiguration? = nil
    ) -> MainMenuTabInfo {
        return MainMenuTabInfo(
            tabID: "uuid",
            url: nil,
            canonicalURL: nil,
            isHomepage: isHomepage,
            isDefaultUserAgentDesktop: false,
            hasChangedUserAgent: false,
            zoomLevel: 0,
            readerModeConfiguration: ReaderModeConfiguration(isAvailable: false, isActive: false),
            summaryIsAvailable: false,
            summarizerConfig: SummarizerConfig(instructions: "Test instructions", options: [:]),
            isBookmarked: false,
            isInReadingList: false,
            isPinned: false,
            accountData: AccountData(title: "Test Title", subtitle: "Test Subtitle"),
            translationConfiguration: translationConfiguration
        )
    }

    private func setLanguagePickerEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.translationsFeature.with { _, _ in
            TranslationsFeature(enabled: true, languagePickerEnabled: enabled)
        }
    }
}
