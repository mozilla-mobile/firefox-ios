// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Shared
import XCTest

@testable import Client

@MainActor
final class SummarizeSettingsViewControllerTests: XCTestCase {
    private var profile: Profile!

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        self.profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        self.profile = nil
        try await super.tearDown()
    }

    func test_generateSettings_withShakeFeature_hasExpectedSections() {
        setupNimbusHostedSummarizerTesting(isEnabled: true)
        let subject = createSubject()
        let sections = subject.generateSettings()
        XCTAssertEqual(sections.count, 2)
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections.first?.children.count, 1)
        XCTAssertEqual(sections.last?.title?.string, "Gestures")
        XCTAssertEqual(sections.last?.children.count, 1)
    }

    func test_generateSettings_withoutShakeFeature_hasExpectedSections() {
        setupNimbusHostedSummarizerTesting(isEnabled: false)
        let subject = createSubject()
        let sections = subject.generateSettings()
        XCTAssertEqual(sections.count, 1)
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections.first?.children.count, 1)
        XCTAssertNil(sections.last?.title?.string)
        XCTAssertEqual(sections.last?.children.count, 1)
    }

    // MARK: - Helper
    private func createSubject() -> SummarizeSettingsViewController {
        let subject = SummarizeSettingsViewController(prefs: profile.prefs, windowUUID: .XCTestDefaultUUID)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func setupNimbusHostedSummarizerTesting(isEnabled: Bool) {
        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isEnabled, shakeGesture: isEnabled)
        }
    }
}
