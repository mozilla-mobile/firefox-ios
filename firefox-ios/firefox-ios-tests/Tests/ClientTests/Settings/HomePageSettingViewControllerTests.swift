// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

@testable import Client

@MainActor
final class HomePageSettingViewControllerTests: XCTestCase, FeatureFlagTestUtility {
    internal var mockProfile: MockProfile!
    internal var mockNimbusLayer: MockNimbusFeatureFlagLayer!
    private var wallpaperManager: WallpaperManagerMock!
    private var delegate: MockSettingsDelegate!

    override func setUp() async throws {
        try await super.setUp()
        mockProfile = MockProfile()
        mockNimbusLayer = MockNimbusFeatureFlagLayer()

        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: mockProfile,
            injectedFeatureFlagProvider: featureFlagsProviderFactory(),
            injectedUserFeaturePreferences: userFeaturePreferenceManagerFactory()
        )

        delegate = MockSettingsDelegate()
        wallpaperManager = WallpaperManagerMock()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        mockProfile = nil
        delegate = nil
        wallpaperManager = nil
        mockNimbusLayer = nil

        try await super.tearDown()
    }

    func testHomePageSettingsLeaks_InitCall() throws {
        let subject = createSubject()
        trackForMemoryLeaks(subject)
    }

    func testHomepageSettings_generateSettings_jumpBackInSectionDefaultValue_isFalse() throws {
        let subject = createSubject()
        subject.profile = mockProfile

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
        subject.profile = mockProfile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let bookmarksSectionSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.BookmarksSection
            }) as? BoolSetting

        let bookmarksSectionSettingValue = try XCTUnwrap(bookmarksSectionSetting?.getDefaultValue())

        XCTAssertFalse(bookmarksSectionSettingValue)
    }

    func testHomepageSettings_generateSettings_trackerBlockerModule_whenFeatureDisabled_isHidden() throws {
        let subject = createSubject()
        subject.profile = mockProfile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let trackerBlockerModuleSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.TrackerBlockerSection
            }) as? BoolSetting

        XCTAssertNil(trackerBlockerModuleSetting)
    }

    func testHomepageSettings_generateSettings_trackerBlockerModule_whenFeatureEnabledDefaultValue_isTrue() throws {
        setFeatureFlag(.homepageTrackerBlockerModule, isEnabled: true)
        let subject = createSubject()
        subject.profile = mockProfile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let trackerBlockerModuleSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.TrackerBlockerSection
            }) as? BoolSetting

        let trackerBlockerModuleSettingValue = try XCTUnwrap(trackerBlockerModuleSetting?.getDefaultValue())

        XCTAssertTrue(trackerBlockerModuleSettingValue)
    }

    // MARK: - Helpers

    private func createSubject() -> HomePageSettingViewController {
        let subject = HomePageSettingViewController(prefs: mockProfile.prefs,
                                                    wallpaperManager: wallpaperManager,
                                                    settingsDelegate: delegate,
                                                    tabManager: MockTabManager())
        trackForMemoryLeaks(subject)
        return subject
    }
}
