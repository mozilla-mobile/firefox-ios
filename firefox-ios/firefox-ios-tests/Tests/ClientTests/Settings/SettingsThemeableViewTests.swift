// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import Shared

@testable import Client

/// Settings screens are shown in the regular theme even while the user browses in private mode, so each of
/// them has to declare the private theme override and resolve its initial theme through it.
@MainActor
final class SettingsThemeableViewTests: XCTestCase {
    private var mockThemeManager: MockThemeManager!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockThemeManager = MockThemeManager()
    }

    override func tearDown() async throws {
        mockThemeManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testAppearanceSettingsView_overridesPrivateTheme() {
        let subject = AppearanceSettingsView(windowUUID: .XCTestDefaultUUID, themeManager: mockThemeManager)

        assertOverridesPrivateTheme(subject)
    }

    func testAddressBarSettingsView_overridesPrivateTheme() {
        let prefs = MockProfilePrefs()
        let subject = AddressBarSettingsView(windowUUID: .XCTestDefaultUUID,
                                             viewModel: SearchBarSettingsViewModel(prefs: prefs),
                                             prefs: prefs,
                                             themeManager: mockThemeManager)

        assertOverridesPrivateTheme(subject)
    }

    func testPageZoomSettingsView_overridesPrivateTheme() {
        let subject = PageZoomSettingsView(windowUUID: .XCTestDefaultUUID, themeManager: mockThemeManager)

        assertOverridesPrivateTheme(subject)
    }

    func testAIControlsSettingsView_overridesPrivateTheme() {
        let model = AIControlsModel(prefs: MockProfilePrefs(), windowUUID: .XCTestDefaultUUID)
        let subject = AIControlsSettingsView(aiControlsModel: model, themeManager: mockThemeManager)

        assertOverridesPrivateTheme(subject)
        XCTAssertEqual(subject.windowUUID, WindowUUID.XCTestDefaultUUID)
    }

    func testAppIconSelectionView_overridesPrivateTheme() {
        let subject = AppIconSelectionView(windowUUID: .XCTestDefaultUUID, themeManager: mockThemeManager)

        assertOverridesPrivateTheme(subject)
    }

    func testAppIconView_overridesPrivateTheme() {
        let subject = AppIconView(appIcon: .regular,
                                  isSelected: false,
                                  windowUUID: .XCTestDefaultUUID,
                                  themeManager: mockThemeManager,
                                  setAppIcon: { _ in })

        assertOverridesPrivateTheme(subject)
    }

    private func assertOverridesPrivateTheme(_ subject: some ThemeableView,
                                             file: StaticString = #filePath,
                                             line: UInt = #line) {
        XCTAssertTrue(subject.shouldUsePrivateOverride, file: file, line: line)
        XCTAssertFalse(subject.shouldBeInPrivateTheme, file: file, line: line)

        // The theme the view starts with comes from the override, not from the window's own private state.
        XCTAssertEqual(mockThemeManager.resolvedThemeCalledCount, 1, file: file, line: line)
        XCTAssertEqual(mockThemeManager.getCurrentThemeCallCount, 0, file: file, line: line)
    }
}
