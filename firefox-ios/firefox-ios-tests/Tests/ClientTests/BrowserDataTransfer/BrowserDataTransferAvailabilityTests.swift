// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import XCTest

@testable import Client

@MainActor
final class BrowserDataTransferAvailabilityTests: XCTestCase {
    private let allActivityTypes: Set<String> = [
        "BEBrowserDataExchangeImportActivity",
        "BEBrowserDataExchangeExportActivity"
    ]
    private var featureFlags: MockNimbusFeatureFlags!

    override func setUp() async throws {
        try await super.setUp()
        featureFlags = MockNimbusFeatureFlags()
        featureFlags.enabledFlags = [.browserDataImport, .browserDataExport]
    }

    override func tearDown() async throws {
        featureFlags = nil
        try await super.tearDown()
    }

    func testIsAvailable_allGatesPass_returnsTrueForBothDirections() {
        let subject = createSubject()

        XCTAssertTrue(subject.isAvailable(.import))
        XCTAssertTrue(subject.isAvailable(.export))
    }

    func testIsAvailable_followsEachFlagIndependently() {
        let combinations: [Set<FeatureFlagID>] = [
            [],
            [.browserDataImport],
            [.browserDataExport],
            [.browserDataImport, .browserDataExport]
        ]

        for enabledFlags in combinations {
            featureFlags.enabledFlags = enabledFlags
            let subject = createSubject()

            XCTAssertEqual(subject.isAvailable(.import), enabledFlags.contains(.browserDataImport))
            XCTAssertEqual(subject.isAvailable(.export), enabledFlags.contains(.browserDataExport))
        }
    }

    func testIsAvailable_unsupportedOperatingSystem_returnsFalse() {
        let subject = createSubject(isOperatingSystemSupported: false)

        XCTAssertFalse(subject.isAvailable(.import))
        XCTAssertFalse(subject.isAvailable(.export))
    }

    func testIsSupportedOS_matchesiOS26_4Availability() {
        let expected: Bool
        if #available(iOS 26.4, *) {
            expected = !ProcessInfo.processInfo.isiOSAppOnMac
        } else {
            expected = false
        }

        XCTAssertEqual(BrowserDataTransferAvailability.isSupportedOS, expected)
    }

    func testIsAvailable_ineligibleBuild_returnsFalseDespiteFlags() {
        let subject = createSubject(isEligibleBuild: false)

        XCTAssertFalse(subject.isAvailable(.import))
        XCTAssertFalse(subject.isAvailable(.export))
    }

    func testEligibleSchemes_excludeEnterpriseAndProduction() {
        let schemes = BrowserDataTransferAvailability.eligibleSchemes

        XCTAssertEqual(schemes, ["Fennec", "FirefoxBeta"])
        XCTAssertFalse(schemes.contains("FennecEnterprise"))
        XCTAssertFalse(schemes.contains("Firefox"))
    }

    func testIsAvailable_unregisteredActivity_returnsFalseForThatDirectionOnly() {
        let subject = createSubject(registeredActivityTypes: ["BEBrowserDataExchangeImportActivity"])

        XCTAssertTrue(subject.isAvailable(.import))
        XCTAssertFalse(subject.isAvailable(.export))
    }

    func testIsAvailable_unimplementedDirection_returnsFalseDespiteTrueFlag() {
        let subject = createSubject(implementedDirections: [.export])

        XCTAssertFalse(subject.isAvailable(.import))
        XCTAssertTrue(subject.isAvailable(.export))
    }

    func testIsAvailable_defaultImplementedDirections_keepUnfinishedDirectionsUnavailable() {
        let subject = BrowserDataTransferAvailability(
            featureFlags: featureFlags,
            isOperatingSystemSupported: true,
            isEligibleBuild: true,
            registeredActivityTypes: allActivityTypes
        )

        XCTAssertFalse(subject.isAvailable(.import))
        XCTAssertFalse(subject.isAvailable(.export))
    }

    func testDirection_mapsOnlyTransferActivityTypes() {
        XCTAssertEqual(BrowserDataTransferDirection(activityType: "BEBrowserDataExchangeImportActivity"), .import)
        XCTAssertEqual(BrowserDataTransferDirection(activityType: "BEBrowserDataExchangeExportActivity"), .export)
        XCTAssertNil(BrowserDataTransferDirection(activityType: "org.mozilla.ios.firefox.browsing"))
        XCTAssertNil(BrowserDataTransferDirection(activityType: "QuickActionIntent"))
    }

    // MARK: - Activity handling

    func testHandle_unrelatedActivity_isNotConsumed() {
        let subject = BrowserDataTransferActivityHandler(availability: createSubject())

        XCTAssertFalse(subject.handle(NSUserActivity(activityType: "org.mozilla.ios.firefox.browsing")))
    }

    func testHandle_disabledTransferActivities_areConsumed() {
        featureFlags.enabledFlags = []
        let subject = BrowserDataTransferActivityHandler(availability: createSubject())

        XCTAssertTrue(subject.handle(NSUserActivity(activityType: "BEBrowserDataExchangeImportActivity")))
        XCTAssertTrue(subject.handle(NSUserActivity(activityType: "BEBrowserDataExchangeExportActivity")))
    }

    func testRoutableActivities_removesEveryTransferActivityFromColdLaunchSet() {
        let browsing = NSUserActivity(activityType: "org.mozilla.ios.firefox.browsing")
        let activities: Set<NSUserActivity> = [
            NSUserActivity(activityType: "BEBrowserDataExchangeImportActivity"),
            NSUserActivity(activityType: "BEBrowserDataExchangeImportActivity"),
            NSUserActivity(activityType: "BEBrowserDataExchangeExportActivity"),
            browsing
        ]
        let subject = BrowserDataTransferActivityHandler(availability: createSubject(implementedDirections: []))

        XCTAssertEqual(subject.routableActivities(from: activities), [browsing])
    }

    private func createSubject(
        isOperatingSystemSupported: Bool = true,
        isEligibleBuild: Bool = true,
        registeredActivityTypes: Set<String>? = nil,
        implementedDirections: Set<BrowserDataTransferDirection> = [.import, .export]
    ) -> BrowserDataTransferAvailability {
        return BrowserDataTransferAvailability(
            featureFlags: featureFlags,
            isOperatingSystemSupported: isOperatingSystemSupported,
            isEligibleBuild: isEligibleBuild,
            registeredActivityTypes: registeredActivityTypes ?? allActivityTypes,
            implementedDirections: implementedDirections
        )
    }
}
