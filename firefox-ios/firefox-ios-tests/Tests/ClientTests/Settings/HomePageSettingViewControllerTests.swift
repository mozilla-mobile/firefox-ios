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
        try await super.tearDown()
        DependencyHelperMock().reset()
        self.profile = nil
        self.delegate = nil
    }

    func testHomePageSettingsLeaks_InitCall() throws {
        let subject = createSubject()
        trackForMemoryLeaks(subject)
    }

    func testHomepageSettings_containsBookmark_whenStoriesRedesignIsDisabled() throws {
        disableStoriesRedesignFlags()
        let subject = createSubject()
        subject.profile = profile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let bookmarkSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.BookmarksSection
            }) as? BoolSetting

        let bookmarkSettingValue = try XCTUnwrap(bookmarkSetting?.getDefaultValue())

        XCTAssertNotNil(bookmarkSetting)
        XCTAssertTrue(bookmarkSettingValue)
    }

    func testHomepageSettings_containsJumpBackIn_whenStoriesRedesignIsDisabled() throws {
        disableStoriesRedesignFlags()
        let subject = createSubject()
        subject.profile = profile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let jumpBackInSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.JumpBackInSection
            }) as? BoolSetting

        let jumpBackInSettingValue = try XCTUnwrap(jumpBackInSetting?.getDefaultValue())

        XCTAssertNotNil(jumpBackInSetting)
        XCTAssertTrue(jumpBackInSettingValue)
    }

    func testHomepageSettings_doesNotContainsBookmark_whenStoriesRedesignIsEnabled() {
        enableStoriesRedesign()
        let subject = createSubject()
        subject.profile = profile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let hasBookmarkSetting = customizeFirefoxHomeSettingsList?.children.contains {
            ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.BookmarksSection
        } ?? false

        XCTAssertFalse(hasBookmarkSetting)
    }

    func testHomepageSettings_doesNotContainsJumpBackIn_whenStoriesRedesignIsEnabled() {
        enableStoriesRedesign()
        let subject = createSubject()
        subject.profile = profile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let hasJumpBackInSetting = customizeFirefoxHomeSettingsList?.children.contains {
            ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.JumpBackInSection
        } ?? false

        XCTAssertFalse(hasJumpBackInSetting)
    }

    func testHomepageSettings_containsBookmark_whenStoriesRedesignV2IsEnabled() throws {
        enableStoriesRedesignV2()
        let subject = createSubject()
        subject.profile = profile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let bookmarkSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.BookmarksSection
            }) as? BoolSetting

        let bookmarkSettingValue = try XCTUnwrap(bookmarkSetting?.getDefaultValue())

        XCTAssertNotNil(bookmarkSetting)
        XCTAssertFalse(bookmarkSettingValue)
    }

    func testHomepageSettings_containsJumpBackIn_whenStoriesRedesignV2IsEnabled() throws {
        enableStoriesRedesignV2()
        let subject = createSubject()
        subject.profile = profile

        let settingsList = subject.generateSettings()

        let customizeFirefoxHomeSettingsList = settingsList.first(
            where: {
                $0.title?.string == .Settings.Homepage.CustomizeFirefoxHome.Title
            })

        let jumpBackInSetting = customizeFirefoxHomeSettingsList?.children.first(
            where: {
                ($0 as? BoolSetting)?.prefKey == PrefsKeys.HomepageSettings.JumpBackInSection
            }) as? BoolSetting

        let jumpBackInSettingValue = try XCTUnwrap(jumpBackInSetting?.getDefaultValue())

        XCTAssertNotNil(jumpBackInSetting)
        XCTAssertFalse(jumpBackInSettingValue)
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

    private func disableStoriesRedesignFlags() {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            return HomepageRedesignFeature(storiesRedesign: false, storiesRedesignV2: false)
        }
    }

    private func enableStoriesRedesign() {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            return HomepageRedesignFeature(storiesRedesign: true, storiesRedesignV2: false)
        }
    }

    private func enableStoriesRedesignV2() {
        FxNimbus.shared.features.homepageRedesignFeature.with { _, _ in
            return HomepageRedesignFeature(storiesRedesign: false, storiesRedesignV2: true)
        }
    }
}
