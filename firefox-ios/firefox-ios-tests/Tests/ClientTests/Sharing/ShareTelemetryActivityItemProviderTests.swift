// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import UniformTypeIdentifiers

@testable import Client

final class ShareTelemetryActivityItemProviderTests: XCTestCase {
    let testMessage = "Test message"
    let testSubtitle = "Test subtitle"
    private let testFileURL = URL(string: "file://some/file/url")!
    private let testWebURL = URL(string: "https://mozilla.org")!

    override func setUp() {
        super.setUp()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)
        super.tearDown()
    }

    func testWithShareType_noShareMessage_callTelemetryOnly() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareType: ShareType = .site(url: testWebURL)
        let testShareMessage: ShareMessage? = nil
        let mockShareTelemetry = MockShareTelemetry()

        let shareTelemetryActivityItemProvider = ShareTelemetryActivityItemProvider(
            shareType: testShareType,
            shareMessage: testShareMessage,
            telemetry: mockShareTelemetry
        )
        let itemForActivity = shareTelemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "Should never share content")
        XCTAssertEqual(mockShareTelemetry.sharedToCalled, 1)
    }

    func testWithShareType_hasShareMessage_callTelemetryOnly() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareType: ShareType = .site(url: testWebURL)
        let testShareMessage = ShareMessage(message: testMessage, subtitle: testSubtitle)
        let mockShareTelemetry = MockShareTelemetry()

        let shareTelemetryActivityItemProvider = ShareTelemetryActivityItemProvider(
            shareType: testShareType,
            shareMessage: testShareMessage,
            telemetry: mockShareTelemetry
        )
        let itemForActivity = shareTelemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "Should never share content")
        XCTAssertEqual(mockShareTelemetry.sharedToCalled, 1)
    }

    // MARK: - Sent from Firefox experiment

    func testShare_forSentFromFirefox_passesNimbusEnrolment_passesUserOptOutPreference() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareType: ShareType = .site(url: testWebURL)
        let testShareMessage = ShareMessage(message: testMessage, subtitle: testSubtitle)
        let mockShareTelemetry = MockShareTelemetry()
        let testNimbusEnrollment = true
        let testUserOptIn = false

        // Enroll the user via Nimbus
        setupNimbusSentFromFirefoxTesting(isEnabled: testNimbusEnrollment, isTreatmentA: true)

        // Opt in the user preference
        UserDefaults.standard.set(testUserOptIn, forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)

        let shareTelemetryActivityItemProvider = ShareTelemetryActivityItemProvider(
            shareType: testShareType,
            shareMessage: testShareMessage,
            telemetry: mockShareTelemetry
        )
        let itemForActivity = shareTelemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "Should never share content")
        XCTAssertEqual(mockShareTelemetry.sharedToCalled, 1)
        XCTAssertEqual(mockShareTelemetry.isEnrolledInSentFromFirefox, testNimbusEnrollment)
        XCTAssertEqual(mockShareTelemetry.isOptedInSentFromFirefox, testUserOptIn)
    }

    func testShare_forSentFromFirefox_passesNimbusEnrolment_passesUserOptInPreference() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareType: ShareType = .site(url: testWebURL)
        let testShareMessage = ShareMessage(message: testMessage, subtitle: testSubtitle)
        let mockShareTelemetry = MockShareTelemetry()
        let testNimbusEnrollment = true
        let testUserOptIn = true

        // Enroll the user via Nimbus
        setupNimbusSentFromFirefoxTesting(isEnabled: testNimbusEnrollment, isTreatmentA: true)

        // Opt in the user preference
        UserDefaults.standard.set(testUserOptIn, forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)

        let shareTelemetryActivityItemProvider = ShareTelemetryActivityItemProvider(
            shareType: testShareType,
            shareMessage: testShareMessage,
            telemetry: mockShareTelemetry
        )
        let itemForActivity = shareTelemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "Should never share content")
        XCTAssertEqual(mockShareTelemetry.sharedToCalled, 1)
        XCTAssertEqual(mockShareTelemetry.isEnrolledInSentFromFirefox, testNimbusEnrollment)
        XCTAssertEqual(mockShareTelemetry.isOptedInSentFromFirefox, testUserOptIn)
    }

    func testShare_forSentFromFirefox_passesNimbusNotEnrolled_passesUserOptOutPreference() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareType: ShareType = .site(url: testWebURL)
        let testShareMessage = ShareMessage(message: testMessage, subtitle: testSubtitle)
        let mockShareTelemetry = MockShareTelemetry()
        let testNimbusEnrollment = false
        let testUserOptIn = false

        // Enroll the user via Nimbus
        setupNimbusSentFromFirefoxTesting(isEnabled: testNimbusEnrollment, isTreatmentA: true)

        // Opt in the user preference
        UserDefaults.standard.set(testUserOptIn, forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)

        let shareTelemetryActivityItemProvider = ShareTelemetryActivityItemProvider(
            shareType: testShareType,
            shareMessage: testShareMessage,
            telemetry: mockShareTelemetry
        )
        let itemForActivity = shareTelemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "Should never share content")
        XCTAssertEqual(mockShareTelemetry.sharedToCalled, 1)
        XCTAssertEqual(mockShareTelemetry.isEnrolledInSentFromFirefox, testNimbusEnrollment)
        XCTAssertEqual(mockShareTelemetry.isOptedInSentFromFirefox, testUserOptIn)
    }

    func testShare_forSentFromFirefox_passesNimbusNotEnrolled_passesUserOptInPreference() throws {
        let testActivityType = UIActivity.ActivityType.mail
        let testShareType: ShareType = .site(url: testWebURL)
        let testShareMessage = ShareMessage(message: testMessage, subtitle: testSubtitle)
        let mockShareTelemetry = MockShareTelemetry()
        let testNimbusEnrollment = false
        let testUserOptIn = true

        // Enroll the user via Nimbus
        setupNimbusSentFromFirefoxTesting(isEnabled: testNimbusEnrollment, isTreatmentA: true)

        // Opt in the user preference
        UserDefaults.standard.set(testUserOptIn, forKey: PrefsKeys.NimbusUserEnabledFeatureTestsOverride)

        let shareTelemetryActivityItemProvider = ShareTelemetryActivityItemProvider(
            shareType: testShareType,
            shareMessage: testShareMessage,
            telemetry: mockShareTelemetry
        )
        let itemForActivity = shareTelemetryActivityItemProvider.activityViewController(
            createStubActivityViewController(),
            itemForActivityType: testActivityType
        )

        XCTAssertTrue(itemForActivity is NSNull, "Should never share content")
        XCTAssertEqual(mockShareTelemetry.sharedToCalled, 1)
        XCTAssertEqual(mockShareTelemetry.isEnrolledInSentFromFirefox, testNimbusEnrollment)
        XCTAssertEqual(mockShareTelemetry.isOptedInSentFromFirefox, testUserOptIn)
    }

    // MARK: - Helpers

    private func createStubActivityViewController() -> UIActivityViewController {
        return UIActivityViewController(activityItems: [], applicationActivities: [])
    }

    private func setupNimbusSentFromFirefoxTesting(isEnabled: Bool, isTreatmentA: Bool) {
        FxNimbus.shared.features.sentFromFirefoxFeature.with { _, _ in
            return SentFromFirefoxFeature(
                enabled: isEnabled,
                isTreatmentA: isTreatmentA
            )
        }
    }
}
