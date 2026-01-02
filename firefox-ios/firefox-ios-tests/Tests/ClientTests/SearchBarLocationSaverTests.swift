// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Shared
import XCTest

class SearchBarLocationSaverTests: XCTestCase {
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        profile = MockProfile()
        await DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() async throws {
        profile.shutdown()
        profile = nil

        DependencyHelperMock().reset()
        resetNimbusToolbarLayoutTesting()
        try await super.tearDown()
    }

    // MARK: - Toolbar Refactor - Version layout
    @MainActor
    func test_saveSearchBarLocation_oniPhone_withFirstRun_forVersion1_setsNoPosition() async throws {
        setupNimbusToolbarLayoutTesting(isEnabled: true, layout: .version1)
        let subject = createSubject()

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(searchBarPosition, nil)
    }

    @MainActor
    func test_saveSearchBarLocation_oniPhone_withSecondRun_forVersion1_setsPositionTop() async throws {
        setupNimbusToolbarLayoutTesting(isEnabled: true, layout: .version1)
        let subject = createSubject()
        profile.prefs.setString(AppInfo.appVersion, forKey: PrefsKeys.AppVersion.Latest) // second run

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(searchBarPosition, SearchBarPosition.bottom.rawValue)
    }

    @MainActor
    func test_saveSearchBarLocation_oniPhone_withSecondRunAfterFullOnboarding_forVersion1_keepsPosition() async throws {
        setupNimbusToolbarLayoutTesting(isEnabled: true, layout: .version1)
        let subject = createSubject()
        profile.prefs.setString(AppInfo.appVersion, forKey: PrefsKeys.AppVersion.Latest) // second run
        profile.prefs.setString(SearchBarPosition.bottom.rawValue, forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .phone)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(searchBarPosition, SearchBarPosition.bottom.rawValue)
    }

    @MainActor
    func test_saveSearchBarLocation_oniPad_withFirstRun_forVersion1_setsNoPosition() async throws {
        setupNimbusToolbarLayoutTesting(isEnabled: true, layout: .version1)
        let subject = createSubject()

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .pad)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(searchBarPosition, nil)
    }

    @MainActor
    func test_saveSearchBarLocation_oniPad_withSecondRun_forVersion1_setsPositionTop() async throws {
        setupNimbusToolbarLayoutTesting(isEnabled: true, layout: .version1)
        let subject = createSubject()
        profile.prefs.setString(AppInfo.appVersion, forKey: PrefsKeys.AppVersion.Latest) // second run

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .pad)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(searchBarPosition, SearchBarPosition.top.rawValue)
    }

    @MainActor
    func test_saveSearchBarLocation_oniPad_withSecondRunAfterFullOnboarding_forVersion1_keepsPosition() async throws {
        setupNimbusToolbarLayoutTesting(isEnabled: true, layout: .version1)
        let subject = createSubject()
        profile.prefs.setString(AppInfo.appVersion, forKey: PrefsKeys.AppVersion.Latest) // second run
        profile.prefs.setString(SearchBarPosition.top.rawValue, forKey: PrefsKeys.FeatureFlags.SearchBarPosition)

        subject.saveUserSearchBarLocation(profile: profile, userInterfaceIdiom: .pad)
        let searchBarPosition = profile.prefs.stringForKey(PrefsKeys.FeatureFlags.SearchBarPosition)
        XCTAssertEqual(searchBarPosition, SearchBarPosition.top.rawValue)
    }

    // MARK: - Helper
    private func createSubject() -> SearchBarLocationSaver {
        return SearchBarLocationSaver()
    }

    private func setupNimbusToolbarLayoutTesting(isEnabled: Bool, layout: ToolbarLayoutType?) {
        FxNimbus.shared.features.toolbarRefactorFeature.with { _, _ in
            return ToolbarRefactorFeature(
                enabled: isEnabled,
                layout: layout,
                navigationHint: true,
                oneTapNewTab: true,
                swipingTabs: false,
                translucency: false,
                unifiedSearch: false)
        }
    }

    private func resetNimbusToolbarLayoutTesting() {
        FxNimbus.shared.features.toolbarRefactorFeature.with { _, _ in
            return ToolbarRefactorFeature(
                enabled: true,
                layout: .version1,
                navigationHint: true,
                oneTapNewTab: false,
                swipingTabs: true,
                translucency: true,
                unifiedSearch: false)
        }
    }
}
