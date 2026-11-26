// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import BrowserKit
import Common
import TestKit
import WebDataTransfer
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

    func testReceiveImport_activityWithToken_importsWithThatTokenAndLogsOutcome() async throws {
        guard #available(iOS 26.4, *) else { throw XCTSkip("Requires iOS 26.4") }
        let token = UUID()
        let importer = MockBrowserDataImporter(
            result: BrowserTransferResult(apiCompleted: true, outcome: .success, recordCount: 0)
        )
        let subject = BrowserDataImportHandler(importer: importer, logger: logger)

        await subject.receiveImport(from: importActivity(token: token))?.value

        XCTAssertEqual(importer.receivedTokens, [token])
        XCTAssertEqual(logger.savedMessage, "Browser data import finished: success")
        XCTAssertEqual(logger.savedLevel, .info)
    }

    func testReceiveImport_cancelledImport_logsNothing() async throws {
        guard #available(iOS 26.4, *) else { throw XCTSkip("Requires iOS 26.4") }
        let importer = MockBrowserDataImporter(result: nil)
        let subject = BrowserDataImportHandler(importer: importer, logger: logger)

        await subject.receiveImport(from: importActivity(token: UUID()))?.value

        XCTAssertEqual(importer.receivedTokens.count, 1)
        XCTAssertNil(logger.savedMessage)
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

    @available(iOS 26.4, *)
    private func importActivity(token: UUID) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "BEBrowserDataExchangeImportActivity")
        activity.userInfo = [BEBrowserDataImportManager.importTokenUserInfoKey: token]
        return activity
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

@available(iOS 26.4, *)
@MainActor
private final class MockBrowserDataImporter: BrowserDataImporting {
    private let result: BrowserTransferResult?
    private(set) var receivedTokens: [UUID] = []

    init(result: BrowserTransferResult?) {
        self.result = result
    }

    func importData(token: UUID, onAPICompletion: @escaping @Sendable () -> Void) async -> BrowserTransferResult? {
        receivedTokens.append(token)
        return result
    }
}
