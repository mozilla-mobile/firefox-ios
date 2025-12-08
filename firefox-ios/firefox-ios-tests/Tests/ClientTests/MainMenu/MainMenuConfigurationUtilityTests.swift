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

    private func getTabInfo(isHomepage: Bool = false) -> MainMenuTabInfo {
        return MainMenuTabInfo(
            tabID: "uuid",
            url: nil,
            canonicalURL: nil,
            isHomepage: isHomepage,
            isDefaultUserAgentDesktop: false,
            hasChangedUserAgent: false,
            zoomLevel: 0,
            readerModeIsAvailable: false,
            summaryIsAvailable: false,
            summarizerConfig: SummarizerConfig(instructions: "Test instructions", options: [:]),
            isBookmarked: false,
            isInReadingList: false,
            isPinned: false,
            accountData: AccountData(title: "Test Title", subtitle: "Test Subtitle")
        )
    }
}
