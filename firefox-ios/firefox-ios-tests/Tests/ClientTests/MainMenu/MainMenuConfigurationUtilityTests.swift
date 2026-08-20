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
        setIsSummarizerLanguageExpansionEnabled(false)
        setIsVPNFeatureEnabled(false)
        configUtility = MainMenuConfigurationUtility()
    }

    override func tearDown() async throws {
        // `FxNimbus.shared` is global, so leaving the flag on would leak into other suites
        setIsVPNFeatureEnabled(false)
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

    // MARK: - VPN section

    func testGenerateMenuElements_hasNoVPNSection_whenVPNFeatureDisabled() {
        let sections = configUtility.generateMenuElements(with: getTabInfo(isHomepage: true), and: windowUUID)

        let titles = sections.flatMap { $0.options }.map { $0.title }
        XCTAssertFalse(titles.contains(String.MainMenu.VPNSection.VPN))
    }

    func testGenerateMenuElements_hasVPNSectionFirst_whenVPNFeatureEnabled() throws {
        try skipUnlessVPNIsAvailable()
        setIsVPNFeatureEnabled(true)

        let homepageSections = configUtility.generateMenuElements(with: getTabInfo(isHomepage: true), and: windowUUID)
        let siteSections = configUtility.generateMenuElements(with: getTabInfo(), and: windowUUID)

        XCTAssertEqual(homepageSections.count, 3)
        XCTAssertEqual(homepageSections[0].options.first?.title, String.MainMenu.VPNSection.VPN)
        XCTAssertEqual(siteSections.count, 4)
        XCTAssertEqual(siteSections[0].options.first?.title, String.MainMenu.VPNSection.VPN)
    }

    func testGenerateMenuElements_vpnItemIsOff_whenIsVPNOnFalse() throws {
        try skipUnlessVPNIsAvailable()
        setIsVPNFeatureEnabled(true)

        let sections = configUtility.generateMenuElements(with: getTabInfo(), and: windowUUID, isVPNOn: false)
        let vpnItem = try XCTUnwrap(sections.first?.options.first)

        XCTAssertEqual(vpnItem.a11yHint, String.MainMenu.VPNSection.VPNOff)
    }

    func testGenerateMenuElements_vpnItemIsOn_whenIsVPNOnTrue() throws {
        try skipUnlessVPNIsAvailable()
        setIsVPNFeatureEnabled(true)

        let sections = configUtility.generateMenuElements(with: getTabInfo(), and: windowUUID, isVPNOn: true)
        let vpnItem = try XCTUnwrap(sections.first?.options.first)

        XCTAssertEqual(vpnItem.a11yHint, String.MainMenu.VPNSection.VPNOn)
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

    func test_translateItem_inactive_a11yHintIsOff() {
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

        XCTAssertEqual(translateItem?.a11yHint, .MainMenu.ToolsSection.Translation.Off)
    }

    func test_translateItem_active_a11yHintIsLanguageName() {
        setLanguagePickerEnabled(true)
        let mockProfile = MockProfile()
        let config = TranslationConfiguration(prefs: mockProfile.prefs, state: .active, translatedToLanguage: "fr")
        let tabInfo = getTabInfo(translationConfiguration: config)

        let locale = Locale(identifier: "en")
        let sections = configUtility.generateMenuElements(
            with: tabInfo,
            and: windowUUID,
            isExpanded: true,
            localeProvider: MockLocaleProvider(current: locale)
        )
        let allItems = sections.flatMap { $0.options }
        let title = String.MainMenu.ToolsSection.Translation.TranslatedPageTitle
        let translateItem = allItems.first { $0.title == title }
        let expectedHint = locale.localizedString(forIdentifier: "fr")

        XCTAssertEqual(translateItem?.a11yHint, expectedHint)
    }

    private func setIsVPNFeatureEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.vpnFeature.with { _, _ in
            return VpnFeature(enabled: enabled)
        }
    }

    /// The VPN row is only built where `ProxyConfiguration` exists, so the flag alone isn't enough.
    private func skipUnlessVPNIsAvailable() throws {
        guard #available(iOS 17.0, *) else {
            throw XCTSkip("The VPN menu row requires iOS 17 or newer")
        }
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
