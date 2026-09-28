// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest
import Common
@testable import Client

@MainActor
final class LeadingPageActionsBuilderTests: XCTestCase {
    private var mockProfile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: MockTabManager())
    }

    override func tearDown() async throws {
        mockProfile = nil
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

        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].actionType, .share)
    }

    func testGetActions_withNoTranslationConfiguration_doesNotReturnTranslateAction() {
        let actions = subject(translationConfiguration: nil)

        XCTAssertEqual(actions.count, 1)
        XCTAssertEqual(actions[0].actionType, .share)
    }

    // MARK: - Alternative location color

    func testGetActions_whenHasAlternativeLocationColorTrue_disablesCustomColorOnShareAction() {
        let actions = subject(hasAlternativeLocationColor: true)

        XCTAssertEqual(actions[0].actionType, .share)
        XCTAssertEqual(actions[0].hasCustomColor, false)
    }

    func testGetActions_whenHasAlternativeLocationColorFalse_enablesCustomColorOnShareAction() {
        let actions = subject(hasAlternativeLocationColor: false)

        XCTAssertEqual(actions[0].actionType, .share)
        XCTAssertEqual(actions[0].hasCustomColor, true)
    }

    // MARK: - Translation feature flag / user setting

    func testGetActions_whenTranslationFeatureEnabled_butUserSettingDisabled_doesNotReturnTranslateAction() {
        setTranslationsFeatureEnabled(enabled: true)
        let config = TranslationConfiguration(prefs: mockProfile.prefs, isUserSettingEnabled: false, state: .inactive)

        let actions = subject(translationConfiguration: config)

        XCTAssertEqual(actions.count, 1)
        XCTAssertFalse(actions.contains { $0.actionType == .translate })
    }

    func testGetActions_whenTranslationFeatureFlagDisabled_doesNotReturnTranslateAction() {
        setTranslationsFeatureEnabled(enabled: false)
        let config = TranslationConfiguration(prefs: mockProfile.prefs, isUserSettingEnabled: true, state: .inactive)

        let actions = subject(translationConfiguration: config)

        XCTAssertEqual(actions.count, 1)
        XCTAssertFalse(actions.contains { $0.actionType == .translate })
    }

    func testGetActions_whenTranslationFeatureAndUserSettingEnabled_returnsTranslateAction() {
        setTranslationsFeatureEnabled(enabled: true)
        let config = TranslationConfiguration(prefs: mockProfile.prefs, isUserSettingEnabled: true, state: .inactive)

        let actions = subject(translationConfiguration: config)

        XCTAssertEqual(actions.count, 2)
        XCTAssertEqual(actions[0].actionType, .share)
        XCTAssertEqual(actions[1].actionType, .translate)
    }

    // MARK: - Translation icon state

    func testGetActions_withInactiveState_returnsInactiveIcon() {
        setTranslationsFeatureEnabled(enabled: true)
        let config = TranslationConfiguration(prefs: mockProfile.prefs, state: .inactive)

        let actions = subject(translationConfiguration: config)
        let translateAction = actions[1]

        XCTAssertEqual(translateAction.actionType, .translate)
        XCTAssertEqual(translateAction.iconName, StandardImageIdentifiers.Medium.translate)
        XCTAssertFalse(translateAction.isSelected)
        XCTAssertFalse(translateAction.loadingConfig!.isLoading)
    }

    func testGetActions_withLoadingState_returnsLoadingIcon() {
        setTranslationsFeatureEnabled(enabled: true)
        let config = TranslationConfiguration(prefs: mockProfile.prefs, state: .loading)

        let actions = subject(translationConfiguration: config)
        let translateAction = actions[1]

        XCTAssertEqual(translateAction.actionType, .translate)
        XCTAssertNil(translateAction.iconName)
        XCTAssertTrue(translateAction.loadingConfig!.isLoading)
    }

    func testGetActions_withActiveState_returnsActiveIcon() {
        setTranslationsFeatureEnabled(enabled: true)
        let config = TranslationConfiguration(prefs: mockProfile.prefs, state: .active)

        let actions = subject(translationConfiguration: config)
        let translateAction = actions[1]

        XCTAssertEqual(translateAction.actionType, .translate)
        XCTAssertEqual(translateAction.iconName, ImageIdentifiers.Translations.translationActive)
        XCTAssertTrue(translateAction.isSelected)
        XCTAssertFalse(translateAction.loadingConfig!.isLoading)
    }

    // MARK: - Helpers

    private func setTranslationsFeatureEnabled(enabled: Bool) {
        FxNimbus.shared.features.translationsFeature.with { _, _ in
            return TranslationsFeature(enabled: enabled)
        }
    }

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
