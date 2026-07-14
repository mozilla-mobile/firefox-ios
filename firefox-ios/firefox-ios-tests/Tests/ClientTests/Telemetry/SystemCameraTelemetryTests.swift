// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Glean
import XCTest

@testable import Client

final class SystemCameraTelemetryTests: XCTestCase {
    private var gleanWrapper: MockGleanWrapper!

    override func setUp() {
        super.setUp()
        gleanWrapper = MockGleanWrapper()
    }

    override func tearDown() {
        gleanWrapper = nil
        super.tearDown()
    }

    func testPermissionResponded_whenGranted_recordsEventAndExtras() throws {
        let subject = SystemCameraTelemetry(gleanWrapper: gleanWrapper)

        subject.permissionResponded(reason: .googleLens, granted: true)

        try assertPermissionRespondedEvent(granted: true)
    }

    func testPermissionResponded_whenDenied_recordsEventAndExtras() throws {
        let subject = SystemCameraTelemetry(gleanWrapper: gleanWrapper)

        subject.permissionResponded(reason: .googleLens, granted: false)

        try assertPermissionRespondedEvent(granted: false)
    }

    private func assertPermissionRespondedEvent(granted: Bool,
                                                file: StaticString = #filePath,
                                                line: UInt = #line) throws {
        typealias EventExtrasType = GleanMetrics.SystemCamera.PermissionRespondedExtra
        let event = GleanMetrics.SystemCamera.permissionResponded
        let savedExtras = try XCTUnwrap(gleanWrapper.savedExtras.first as? EventExtrasType,
                                        file: file,
                                        line: line)
        let savedMetric = try XCTUnwrap(gleanWrapper.savedEvents.first as? EventMetricType<EventExtrasType>,
                                        file: file,
                                        line: line)

        XCTAssertEqual(gleanWrapper.recordEventCalled, 1, file: file, line: line)
        XCTAssertEqual(savedExtras.granted, granted, file: file, line: line)
        XCTAssertEqual(savedExtras.reason, CameraReason.googleLens.rawValue, file: file, line: line)
        XCTAssert(savedMetric === event,
                  "Received \(savedMetric) instead of \(event)",
                  file: file,
                  line: line)
    }
}
