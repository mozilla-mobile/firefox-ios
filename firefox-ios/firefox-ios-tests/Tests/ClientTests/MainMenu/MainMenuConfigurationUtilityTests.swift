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
    var configUtility: MainMenuConfigurationUtility!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
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

    func testGenerateMenuElements_readerViewItem_isDisabled_whenReaderModeNotAvailable() {
        let tabInfo = getTabInfo(readerModeIsAvailable: false, readerModeIsEnabled: false)
        let sections = configUtility.generateMenuElements(with: tabInfo, and: windowUUID, isExpanded: true)

        let allItems = sections.flatMap { $0.options }
        let readerViewItems = allItems.filter { $0.title == String.MainMenu.ToolsSection.ReaderViewTitle }

        for item in readerViewItems {
            XCTAssertFalse(item.isEnabled, "Reader view item should be disabled when reader mode is not available")
        }
    }

    func testGenerateMenuElements_readerViewItem_isEnabled_whenReaderModeAvailable() {
        let tabInfo = getTabInfo(readerModeIsAvailable: true, readerModeIsEnabled: false)
        let sections = configUtility.generateMenuElements(with: tabInfo, and: windowUUID, isExpanded: true)

        let allItems = sections.flatMap { $0.options }
        let readerViewItems = allItems.filter { $0.title == String.MainMenu.ToolsSection.ReaderViewTitle }

        for item in readerViewItems {
            XCTAssertTrue(item.isEnabled, "Reader view item should be enabled when reader mode is available")
            XCTAssertFalse(item.isActive, "Reader view item should not be active when reader mode is not enabled")
        }
    }

    func testGenerateMenuElements_readerViewItem_isActive_whenReaderModeEnabled() {
        let tabInfo = getTabInfo(readerModeIsAvailable: true, readerModeIsEnabled: true)
        let sections = configUtility.generateMenuElements(with: tabInfo, and: windowUUID, isExpanded: true)

        let allItems = sections.flatMap { $0.options }
        let readerViewItems = allItems.filter { $0.title == String.MainMenu.ToolsSection.ReaderViewTitle }

        for item in readerViewItems {
            XCTAssertTrue(item.isActive, "Reader view item should be active when reader mode is enabled")
        }
    }

    private func getTabInfo(
        isHomepage: Bool = false,
        readerModeIsAvailable: Bool = false,
        readerModeIsEnabled: Bool = false
    ) -> MainMenuTabInfo {
        return MainMenuTabInfo(
            tabID: "uuid",
            url: nil,
            canonicalURL: nil,
            isHomepage: isHomepage,
            isDefaultUserAgentDesktop: false,
            hasChangedUserAgent: false,
            zoomLevel: 0,
            readerModeIsAvailable: readerModeIsAvailable,
            readerModeIsEnabled: readerModeIsEnabled,
            summaryIsAvailable: false,
            summarizerConfig: SummarizerConfig(instructions: "Test instructions", options: [:]),
            isBookmarked: false,
            isInReadingList: false,
            isPinned: false,
            accountData: AccountData(title: "Test Title", subtitle: "Test Subtitle")
        )
    }
}
