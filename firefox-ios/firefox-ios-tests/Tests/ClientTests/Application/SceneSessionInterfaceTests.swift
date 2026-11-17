// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import XCTest

@testable import Client

@MainActor
final class SceneSessionInterfaceTests: XCTestCase {
    func testConnectedWindowUUIDs_excludesScenesWithoutBrowserDelegate() throws {
        let application = UIApplication.shared
        let scene = try XCTUnwrap(application.connectedScenes.first)
        XCTAssertTrue(scene.delegate is UnitTestSceneDelegate)

        XCTAssertTrue(application.connectedWindowUUIDs.isEmpty)
    }

    func testRequestSceneSessionDestruction_forUnknownWindow_doesNotReportError() async {
        let application = UIApplication.shared
        let unknownWindow = WindowUUID()
        XCTAssertFalse(application.connectedWindowUUIDs.contains(unknownWindow))
        let errorReported = expectation(description: "Unknown window must not report a destruction error")
        errorReported.isInverted = true

        application.requestSceneSessionDestruction(for: unknownWindow) { _ in
            errorReported.fulfill()
        }

        await fulfillment(of: [errorReported], timeout: 0.1)
    }
}
