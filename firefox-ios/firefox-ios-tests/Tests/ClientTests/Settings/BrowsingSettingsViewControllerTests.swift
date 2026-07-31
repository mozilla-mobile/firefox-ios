// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

import XCTest

@testable import Client

@MainActor
final class BrowsingSettingsViewControllerTests: XCTestCase {
    private var profile: Profile!
    private var delegate: MockSettingsDelegate!
    private var featureFlags: MockNimbusFeatureFlags!

    override func setUp() async throws {
        try await super.setUp()
        self.featureFlags = MockNimbusFeatureFlags()
        DependencyHelperMock().bootstrapDependencies(injectedFeatureFlagProvider: featureFlags)
        self.profile = MockProfile()
        self.delegate = MockSettingsDelegate()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        self.profile = nil
        self.delegate = nil
        self.featureFlags = nil
        try await super.tearDown()
    }

    func testHomePageSettingsLeaks_InitCall() throws {
        let subject = createSubject()
        trackForMemoryLeaks(subject)
    }

    func testGenerateSettings_whenAdBlockerFlagOff_omitsAdBlockerAndUsesMediaSection() {
        featureFlags.enabledFlags = []
        let subject = createSubject()

        let sections = subject.generateSettings()
        let contentSection = sections.last
        let hasAdBlocker = contentSection?.children.contains(where: { $0 is AdBlockerSetting }) ?? false

        XCTAssertEqual(contentSection?.title?.string, String.Settings.Browsing.Media)
        XCTAssertFalse(hasAdBlocker)
    }

    func testGenerateSettings_whenAdBlockerFlagOn_includesAdBlockerAndUsesContentSection() {
        featureFlags.enabledFlags = [.adBlocker]
        let subject = createSubject()

        let sections = subject.generateSettings()
        let contentSection = sections.last
        let hasAdBlocker = contentSection?.children.contains(where: { $0 is AdBlockerSetting }) ?? false

        XCTAssertEqual(contentSection?.title?.string, String.Settings.Browsing.Content)
        XCTAssertTrue(hasAdBlocker)
    }

    // MARK: - Helper
    private func createSubject() -> BrowsingSettingsViewController {
        let subject = BrowsingSettingsViewController(profile: profile,
                                                     windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }
}
