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
        let mockSummarizeNimbusUtils = MockSummarizerNimbusUtils()
        mockSummarizeNimbusUtils.shakeGestureFeatureFlagEnabled = true

        let subject = createSubject(with: mockSummarizeNimbusUtils)
        let sections = subject.generateSettings()

        XCTAssertEqual(mockSummarizeNimbusUtils.isShakeGestureFeatureFlagEnabledCallCount, 1)
        XCTAssertEqual(sections.count, 2)
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections.first?.children.count, 1)
        XCTAssertEqual(sections.last?.title?.string, "Gestures")
        XCTAssertEqual(sections.last?.children.count, 1)
    }

    func test_generateSettings_withoutShakeFeature_hasExpectedSections() {
        let mockSummarizeNimbusUtils = MockSummarizerNimbusUtils()
        mockSummarizeNimbusUtils.shakeGestureFeatureFlagEnabled = false

        let subject = createSubject(with: mockSummarizeNimbusUtils)
        let sections = subject.generateSettings()

        XCTAssertEqual(mockSummarizeNimbusUtils.isShakeGestureFeatureFlagEnabledCallCount, 1)
        XCTAssertEqual(sections.count, 1)
        XCTAssertNil(sections.first?.title)
        XCTAssertEqual(sections.first?.children.count, 1)
        XCTAssertNil(sections.last?.title?.string)
        XCTAssertEqual(sections.last?.children.count, 1)
    }

    // MARK: - Helper
    private func createSubject(with summarizeNimbusUtils: MockSummarizerNimbusUtils) -> SummarizeSettingsViewController {
        let subject = SummarizeSettingsViewController(
            prefs: profile.prefs,
            summarizeNimbusUtils: summarizeNimbusUtils,
            windowUUID: .XCTestDefaultUUID
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}

final class MockSummarizerNimbusUtils: SummarizerNimbusUtils {
    var isSummarizeFeatureToggledOn = false
    var isSummarizeFeatureEnabled = false
    var isShakeGestureEnabled = false
    var isToolbarButtonEnabled = false

    var appleSummarizerEnabled = false
    var hostedSummarizerEnabled = false
    var shakeGestureFeatureFlagEnabled = false
    var appAttestAuthEnabled = false

    private(set) var isAppleSummarizerEnabledCallCount = 0
    private(set) var isHostedSummarizerEnabledCallCount = 0
    private(set) var isShakeGestureFeatureFlagEnabledCallCount = 0
    private(set) var isAppAttestAuthEnabledCallCount = 0

    func isAppleSummarizerEnabled() -> Bool {
        isAppleSummarizerEnabledCallCount += 1
        return appleSummarizerEnabled
    }

    func isHostedSummarizerEnabled() -> Bool {
        isHostedSummarizerEnabledCallCount += 1
        return hostedSummarizerEnabled
    }

    func isShakeGestureFeatureFlagEnabled() -> Bool {
        isShakeGestureFeatureFlagEnabledCallCount += 1
        return shakeGestureFeatureFlagEnabled
    }

    func isAppAttestAuthEnabled() -> Bool {
        isAppAttestAuthEnabledCallCount += 1
        return appAttestAuthEnabled
    }
}
