// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Shared
import XCTest

class StatusBarOverlayTests: XCTestCase {
    private var profile: MockProfile!
    private var wallpaperManager: WallpaperManagerMock!
    private var notificationCenter: MockNotificationCenter!

    override func setUp() {
        super.setUp()
        self.profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        self.wallpaperManager = WallpaperManagerMock()
        self.notificationCenter = MockNotificationCenter()
    }

    override func tearDown() {
        self.profile = nil
        self.wallpaperManager = nil
        self.notificationCenter = nil
        super.tearDown()
    }

    func testInitialState_isOpaque() throws {
        let subject = createSubject()

        XCTAssertFalse(subject.hasTopTabs)
        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer1.withAlphaComponent(1).cgColor)
    }

    func testOnHomepage_withoutWallpaperWithBottomURLBar_isOpaque() throws {
        let subject = createSubject()
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer1.withAlphaComponent(1).cgColor)
    }

    func testOnHomepage_withoutWallpaperWithTopURLBar_isOpaque() throws {
        let subject = createSubject()
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer1.withAlphaComponent(1).cgColor)
    }

    func testOnHomepage_withWallpaperWithBottomURLBar_notOpaque() throws {
        let subject = createSubject()
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer1.withAlphaComponent(0).cgColor)
    }

    func testOnHomepage_withWallpaperWithTopURLBar_isOpaque() throws {
        let subject = createSubject()
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer1.withAlphaComponent(1).cgColor)
    }

    func testOnWebpage_withoutWallpaperWithBottomURLBar_isOpaque() throws {
        let subject = createSubject()
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer1.withAlphaComponent(1).cgColor)
    }

    func testOnWebpage_withoutWallpaperWithTopURLBar_isOpaque() throws {
        let subject = createSubject()
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer1.withAlphaComponent(1).cgColor)
    }

    func testOnWebpage_withWallpaperWithBottomURLBar_isOpaque() throws {
        let subject = createSubject()
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer1.withAlphaComponent(1).cgColor)
    }

    func testOnWebpage_withWallpaperWithTopURLBar_isOpaque() throws {
        let subject = createSubject()
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer1.withAlphaComponent(1).cgColor)
    }

    func testHasTopTabs_onHomepageWithoutWallpaperWithTopURLBar_isOpaque() throws {
        let subject = createSubject(hasTopTabs: true)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer3.withAlphaComponent(1).cgColor)
    }

    func testHasTopTabs_onHomepageWithWallpaperWithTopURLBar_isOpaque() throws {
        let subject = createSubject(hasTopTabs: true)
        subject.hasTopTabs = true
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer3.withAlphaComponent(1).cgColor)
    }

    func testHasTopTabs_onWebpageWithoutWallpaperWithTopURLBar_isOpaque() throws {
        let subject = createSubject(hasTopTabs: true)
        subject.hasTopTabs = true
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer3.withAlphaComponent(1).cgColor)
    }

    func testHasTopTabs_onWebpageWithWallpaperWithTopURLBar_isOpaque() throws {
        let subject = createSubject(hasTopTabs: true)
        subject.hasTopTabs = true
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layer3.withAlphaComponent(1).cgColor)
    }

    private func createSubject(hasTopTabs: Bool = false) -> StatusBarOverlay {
        let subject = StatusBarOverlay(frame: .zero,
                                       notificationCenter: notificationCenter,
                                       wallpaperManager: wallpaperManager)
        subject.hasTopTabs = hasTopTabs
        subject.applyTheme(theme: LightTheme())
        trackForMemoryLeaks(subject)
        return subject
    }
}
