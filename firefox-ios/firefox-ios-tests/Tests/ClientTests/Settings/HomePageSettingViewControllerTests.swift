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
    private var mockNimbusLayer: MockNimbusFeatureFlagLayer!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        mockNimbusLayer = MockNimbusFeatureFlagLayer()
        let featureFlagProvider = FeatureFlagsProvider(prefs: profile.prefs, backendLayer: mockNimbusLayer)
        let userFeaturePreferences = UserFeaturePreferenceManager(prefs: profile.prefs, backendLayer: mockNimbusLayer)

        DependencyHelperMock().bootstrapDependencies(
            injectedProfile: profile,
            injectedFeatureFlagProvider: featureFlagProvider,
            injectedUserFeaturePreferences: userFeaturePreferences
        )

        delegate = MockSettingsDelegate()
        wallpaperManager = WallpaperManagerMock()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        profile = nil
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
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.BookmarksSection
            }) as? BoolSetting

        let bookmarksSectionSettingValue = try XCTUnwrap(bookmarksSectionSetting?.getDefaultValue())

        XCTAssertFalse(bookmarksSectionSettingValue)
    }

    func testHomepageSettings_generateSettings_trackerBlockerModule_whenFeatureDisabled_isHidden() throws {
        let subject = createSubject()
        subject.profile = profile

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
        subject.profile = profile

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

    func testHomepageSettings_generateSettings_worldCupSectionDefaultValue_whenFFEnabled_isTrue() throws {
        setFeatureFlag(.worldCupWidget, isEnabled: true)
        let subject = createSubject()
        subject.profile = profile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let worldCupSectionSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.WorldCupSection
            }) as? BoolSetting

        let worldCupSectionSettingValue = try XCTUnwrap(worldCupSectionSetting?.getDefaultValue())

        XCTAssertTrue(worldCupSectionSettingValue)
    }

    // MARK: - Helper
    private func setFeatureFlag(_ flag: FeatureFlagID, isEnabled: Bool) {
        if isEnabled {
            mockNimbusLayer.enabledFlags.insert(flag)
        } else {
            mockNimbusLayer.enabledFlags.remove(flag)
        }
    }

    private func createSubject() -> HomePageSettingViewController {
        let subject = HomePageSettingViewController(prefs: profile.prefs,
                                                    wallpaperManager: wallpaperManager,
                                                    settingsDelegate: delegate,
                                                    tabManager: MockTabManager())
        trackForMemoryLeaks(subject)
        return subject
    }
}
