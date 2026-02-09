// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Shared
import XCTest

@MainActor
final class StatusBarOverlayTests: XCTestCase {
    private var profile: MockProfile!
    private var wallpaperManager: WallpaperManagerMock!
    private var notificationCenter: MockNotificationCenter!
    private var toolbarHelper: ToolbarHelperInterface!

    private var expectedAlpha: CGFloat = if #available(iOS 26, *) { .zero } else { 0.85 }

    override func setUp() async throws {
        try await super.setUp()
        self.profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        self.wallpaperManager = WallpaperManagerMock()
        self.notificationCenter = MockNotificationCenter()
    }

    override func tearDown() async throws {
        self.profile = nil
        self.wallpaperManager = nil
        self.notificationCenter = nil
        try await super.tearDown()
    }

    // MARK: Translucency enabled

    func testInitialState_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)

        XCTAssertFalse(subject.hasTopTabs)
        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testOnHomepage_withoutWallpaperWithBottomURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.withAlphaComponent(0).cgColor)
    }

    func testOnHomepage_withoutWallpaperWithTopURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testOnHomepage_withWallpaperWithBottomURLBar_translucencyOn_notOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.withAlphaComponent(0).cgColor)
    }

    func testOnHomepage_withWallpaperWithTopURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testOnWebpage_withoutWallpaperWithBottomURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testOnWebpage_withoutWallpaperWithTopURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testOnWebpage_withWallpaperWithBottomURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testOnWebpage_withWallpaperWithTopURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testHasTopTabs_onHomepageWithoutWallpaperWithTopURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testHasTopTabs_onHomepageWithWallpaperWithTopURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testHasTopTabs_onWebpageWithoutWallpaperWithTopURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    func testHasTopTabs_onWebpageWithWallpaperWithTopURLBar_translucencyOn_isTranslucent() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: true)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor,
                       LightTheme().colors.layerSurfaceLow.withAlphaComponent(expectedAlpha).cgColor)
    }

    // MARK: Translucency enabled

    func testInitialState_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(toolbarHelper: toolbarHelper)

        XCTAssertFalse(subject.hasTopTabs)
        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnHomepage_withoutWallpaperWithBottomURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.withAlphaComponent(1).cgColor)
    }

    func testOnHomepage_withoutWallpaperWithTopURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnHomepage_withWallpaperWithBottomURLBar_translucencyOff_notOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.withAlphaComponent(0).cgColor)
    }

    func testOnHomepage_withWallpaperWithTopURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnWebpage_withoutWallpaperWithBottomURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnWebpage_withoutWallpaperWithTopURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnWebpage_withWallpaperWithBottomURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnWebpage_withWallpaperWithTopURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testHasTopTabs_onHomepageWithoutWallpaperWithTopURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testHasTopTabs_onHomepageWithWallpaperWithTopURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testHasTopTabs_onWebpageWithoutWallpaperWithTopURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testHasTopTabs_onWebpageWithWallpaperWithTopURLBar_translucencyOff_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isTranslucencyEnabled: false)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    // MARK: Reduce Transparency

    func testInitialState_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)

        XCTAssertFalse(subject.hasTopTabs)
        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnHomepage_withoutWallpaperWithBottomURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.withAlphaComponent(1).cgColor)
    }

    func testOnHomepage_withoutWallpaperWithTopURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnHomepage_withWallpaperWithBottomURLBar_reduceTransparency_notOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.withAlphaComponent(0).cgColor)
    }

    func testOnHomepage_withWallpaperWithTopURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnWebpage_withoutWallpaperWithBottomURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnWebpage_withoutWallpaperWithTopURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnWebpage_withWallpaperWithBottomURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("bottom", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testOnWebpage_withWallpaperWithTopURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testHasTopTabs_onHomepageWithoutWallpaperWithTopURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testHasTopTabs_onHomepageWithWallpaperWithTopURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: true)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testHasTopTabs_onWebpageWithoutWallpaperWithTopURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    func testHasTopTabs_onWebpageWithWallpaperWithTopURLBar_reduceTransparency_isOpaque() throws {
        let toolbarHelper = createToolbarMock(isReduceTransparencyEnabled: true)
        let subject = createSubject(hasTopTabs: true, toolbarHelper: toolbarHelper)
        profile.prefs.setString("top", forKey: PrefsKeys.FeatureFlags.SearchBarPosition)
        wallpaperManager.currentWallpaper = Wallpaper(id: "A Custom Wallpaper",
                                                      textColor: nil,
                                                      cardColor: nil,
                                                      logoTextColor: nil)

        subject.resetState(isHomepage: false)

        let backgroundColor = try XCTUnwrap(subject.backgroundColor)
        XCTAssertEqual(backgroundColor.cgColor, LightTheme().colors.layerSurfaceLow.cgColor)
    }

    // MARK: Helper

    private func createSubject(hasTopTabs: Bool = false,
                               toolbarHelper: ToolbarHelperInterface = ToolbarHelper()) -> StatusBarOverlay {
        let subject = StatusBarOverlay(frame: .zero,
                                       notificationCenter: notificationCenter,
                                       wallpaperManager: wallpaperManager,
                                       toolbarHelper: toolbarHelper)
        subject.hasTopTabs = hasTopTabs
        subject.applyTheme(theme: LightTheme())
        trackForMemoryLeaks(subject)
        return subject
    }

    private func createToolbarMock(
        isTranslucencyEnabled: Bool = true,
        isReduceTransparencyEnabled: Bool = false) -> ToolbarHelperInterface {
        let toolbarHelper = MockToolbarHelper()
        toolbarHelper.isToolbarTranslucencyEnabled = isTranslucencyEnabled
        toolbarHelper.isReduceTransparencyEnabled = isReduceTransparencyEnabled
        return toolbarHelper
    }
}
