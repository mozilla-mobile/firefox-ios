// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import TestKit
import XCTest

@testable import Client

@MainActor
final class BrowserDataImportHandlerTests: XCTestCase {
    private var logger: MockLogger!

    override func setUp() async throws {
        try await super.setUp()
        logger = MockLogger()
    }

    override func tearDown() async throws {
        logger = nil
        try await super.tearDown()
    }

    func testReceiveImport_activityWithoutToken_logsWarning() throws {
        guard #available(iOS 26.4, *) else { throw XCTSkip("Requires iOS 26.4") }
        let subject = BrowserDataImportHandler(windowScene: try windowScene(), logger: logger)

        subject.receiveImport(from: NSUserActivity(activityType: "BEBrowserDataExchangeImportActivity"))

        XCTAssertEqual(logger.savedMessage, "Browser data import activity has no valid token")
        XCTAssertEqual(logger.savedLevel, .warning)
    }

    func testActivityHandler_availableActivitiesInWindowScene_areConsumedWithoutBeingIgnored() throws {
        guard #available(iOS 26.4, *) else { throw XCTSkip("Requires iOS 26.4") }
        let scene = try windowScene()
        let subject = BrowserDataTransferActivityHandler(availability: availability(), logger: logger)

        XCTAssertTrue(subject.handle(NSUserActivity(activityType: "BEBrowserDataExchangeImportActivity"), in: scene))
        XCTAssertTrue(subject.handle(NSUserActivity(activityType: "BEBrowserDataExchangeImportActivity"), in: scene))
        XCTAssertTrue(subject.handle(NSUserActivity(activityType: "BEBrowserDataExchangeExportActivity"), in: scene))
        XCTAssertNil(logger.savedMessage)
    }

    private func windowScene() throws -> UIWindowScene {
        return try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
    }

    private func availability() -> BrowserDataTransferAvailability {
        let featureFlags = MockNimbusFeatureFlags()
        featureFlags.enabledFlags = [.browserDataImport, .browserDataExport]
        return BrowserDataTransferAvailability(
            featureFlags: featureFlags,
            isOperatingSystemSupported: true,
            isEligibleBuild: true,
            registeredActivityTypes: [
                "BEBrowserDataExchangeImportActivity",
                "BEBrowserDataExchangeExportActivity"
            ],
            implementedDirections: [.import, .export]
        )
    }
}
