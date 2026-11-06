// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

@MainActor
final class FirefoxTabContentBlockerTests: XCTestCase {
    private var featureFlags: MockNimbusFeatureFlags!
    private var profile: MockProfile!

    override func setUp() async throws {
        try await super.setUp()
        featureFlags = MockNimbusFeatureFlags()
        profile = makeProfile()
        // With no list enabled, rule setup completes synchronously without using WKContentRuleListStore.
        profile.prefs.setBool(false, forKey: ContentBlockingConfig.Prefs.EnabledKey)
        DependencyHelperMock().bootstrapDependencies(injectedFeatureFlagProvider: featureFlags)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        featureFlags = nil
        profile = nil
        try await super.tearDown()
    }

    func testNotifiedTabSetupRequired_whenTabHasNoUncommittedNavigation_reloadsTab() {
        let tab = MockContentBlockerTab()
        let subject = createSubject(tab: tab)

        subject.notifiedTabSetupRequired()

        XCTAssertEqual(tab.reloadCalled, 1)
    }

    func testNotifiedTabSetupRequired_whenTabHasUncommittedNavigation_doesNotReloadTab() {
        let tab = MockContentBlockerTab()
        tab.hasUncommittedNavigation = true
        let subject = createSubject(tab: tab)

        subject.notifiedTabSetupRequired()

        XCTAssertEqual(tab.reloadCalled, 0)
    }

    // MARK: - Helpers

    private func createSubject(tab: MockContentBlockerTab) -> FirefoxTabContentBlocker {
        let subject = FirefoxTabContentBlocker(tab: tab, prefs: profile.prefs)
        trackForMemoryLeaks(subject)
        return subject
    }
}
