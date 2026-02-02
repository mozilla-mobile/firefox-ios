// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

@MainActor
final class HomePageSettingViewControllerTests: XCTestCase {
    private var profile: MockProfile!
    private var wallpaperManager: WallpaperManagerMock!
    private var delegate: MockSettingsDelegate!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        DependencyHelperMock().bootstrapDependencies()
        self.profile = MockProfile()
        self.delegate = MockSettingsDelegate()
        self.wallpaperManager = WallpaperManagerMock()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        self.profile = nil
        self.delegate = nil

        try await super.tearDown()
    }

    func testHomePageSettingsLeaks_InitCall() throws {
        let subject = createSubject()
        trackForMemoryLeaks(subject)
    }

    func testHomepageSettings_generateSettings_jumpBackInSectionDefaultValue_isFalse() throws {
        let subject = createSubject()
        subject.profile = profile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let jumpBackInSectionSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.JumpBackInSection
            }) as? BoolSetting

        let jumpBackInSectionSettingValue = try XCTUnwrap(jumpBackInSectionSetting?.getDefaultValue())

        XCTAssertFalse(jumpBackInSectionSettingValue)
    }

    func testHomepageSettings_generateSettings_bookmarksSectionDefaultValue_isFalse() throws {
        let subject = createSubject()
        subject.profile = profile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let bookmarksSectionSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.JumpBackInSection
            }) as? BoolSetting

        let bookmarksSectionSettingValue = try XCTUnwrap(bookmarksSectionSetting?.getDefaultValue())

        XCTAssertFalse(bookmarksSectionSettingValue)
    }

    // MARK: - Helper

    private func createSubject() -> HomePageSettingViewController {
        let subject = HomePageSettingViewController(prefs: profile.prefs,
                                                    wallpaperManager: wallpaperManager,
                                                    settingsDelegate: delegate,
                                                    tabManager: MockTabManager())
        trackForMemoryLeaks(subject)
        return subject
    }
}
