// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import XCTest

@testable import Client

@MainActor
final class SceneDestroyerTests: XCTestCase {
    func testDestroyScenes_withNoWindowUUIDs_requestsNoDestruction() {
        let application = MockSceneSessionInterface()
        application.connectedWindowUUIDs = [WindowUUID()]

        createSubject(application: application).destroyScenes(for: []) { _, _ in
            XCTFail("The error handler should not run when no window was asked to close.")
        }

        XCTAssertTrue(application.destructionRequestedUUIDs.isEmpty)
    }

    func testDestroyScenes_withConnectedWindow_requestsItsDestruction() {
        let window = WindowUUID()
        let application = MockSceneSessionInterface()
        application.connectedWindowUUIDs = [window]

        createSubject(application: application).destroyScenes(for: [window]) { _, _ in
            XCTFail("The error handler should not run when the window closes successfully.")
        }

        XCTAssertEqual(application.destructionRequestedUUIDs, [window])
    }

    func testDestroyScenes_withWindowThatIsNotConnected_skipsIt() {
        let connected = WindowUUID()
        let disconnected = WindowUUID()
        let application = MockSceneSessionInterface()
        application.connectedWindowUUIDs = [connected]

        createSubject(application: application).destroyScenes(for: [connected, disconnected]) { _, _ in
            XCTFail("The error handler should not run when the window closes successfully.")
        }

        XCTAssertEqual(application.destructionRequestedUUIDs, [connected])
    }

    func testDestroyScenes_whenDestructionFails_callsErrorHandlerWithThatWindow() {
        let window = WindowUUID()
        let application = MockSceneSessionInterface()
        application.connectedWindowUUIDs = [window]
        application.errorToReport = TestError.destructionRefused
        var reportedUUIDs: [WindowUUID] = []
        var reportedErrors: [TestError] = []

        createSubject(application: application).destroyScenes(for: [window]) { windowUUID, error in
            reportedUUIDs.append(windowUUID)
            if let error = error as? TestError { reportedErrors.append(error) }
        }

        XCTAssertEqual(reportedUUIDs, [window])
        XCTAssertEqual(reportedErrors, [.destructionRefused])
    }

    // MARK: - Helpers

    private func createSubject(application: SceneSessionInterface) -> DefaultSceneDestroyer {
        return DefaultSceneDestroyer(application: application)
    }

    private enum TestError: Error, Equatable {
        case destructionRefused
    }
}

// MARK: - Test doubles

final class MockSceneSessionInterface: SceneSessionInterface {
    var connectedWindowUUIDs: [WindowUUID] = []
    var destructionRequestedUUIDs: [WindowUUID] = []
    /// When set, every window is reported as having been refused by iOS instead of closing.
    var errorToReport: (any Error)?

    func requestSceneSessionDestruction(for windowUUID: WindowUUID,
                                        errorHandler: @escaping @MainActor (any Error) -> Void) {
        destructionRequestedUUIDs.append(windowUUID)
        guard let errorToReport else { return }
        errorHandler(errorToReport)
    }
}
