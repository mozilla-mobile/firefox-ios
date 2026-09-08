// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common
@testable import Client

@MainActor
final class LeadingPageActionsBuilderTests: XCTestCase {
    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: MockTabManager())
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Editing / homepage guards

    func testGetActions_whenEditing_returnsNoActions() {
        let actions = subject(isEditing: true, isHomepage: false)

        XCTAssertTrue(actions.isEmpty)
    }

    func testGetActions_whenHomepage_returnsNoActions() {
        let actions = subject(isEditing: false, isHomepage: true)

        XCTAssertTrue(actions.isEmpty)
    }

    func testGetActions_whenRealWebsite_returnsShareAction() {
        let actions = subject(isEditing: false, isHomepage: false)

        XCTAssertTrue(actions.contains { $0.actionType == .share })
    }

    func testGetActions_withNoTranslationConfiguration_doesNotReturnTranslateAction() {
        let actions = subject(translationConfiguration: nil)

        XCTAssertFalse(actions.contains { $0.actionType == .translate })
    }

    // MARK: - Alternative location color

    func testGetActions_whenHasAlternativeLocationColorTrue_disablesCustomColorOnShareAction() {
        let actions = subject(hasAlternativeLocationColor: true)

        XCTAssertEqual(actions.first { $0.actionType == .share }?.hasCustomColor, false)
    }

    func testGetActions_whenHasAlternativeLocationColorFalse_enablesCustomColorOnShareAction() {
        let actions = subject(hasAlternativeLocationColor: false)

        XCTAssertEqual(actions.first { $0.actionType == .share }?.hasCustomColor, true)
    }

    // MARK: - Helpers

    private func subject(
        translationConfiguration: TranslationConfiguration? = nil,
        isEditing: Bool = false,
        isHomepage: Bool = false,
        isLoading: Bool? = nil,
        hasAlternativeLocationColor: Bool = false,
        isNovaDesignEnabled: Bool = false
    ) -> [ToolbarActionConfiguration] {
        LeadingPageActionsBuilder.getActions(
            translationConfiguration: translationConfiguration,
            isEditing: isEditing,
            isHomepage: isHomepage,
            isLoading: isLoading,
            hasAlternativeLocationColor: hasAlternativeLocationColor,
            isNovaDesignEnabled: isNovaDesignEnabled
        )
    }
}
