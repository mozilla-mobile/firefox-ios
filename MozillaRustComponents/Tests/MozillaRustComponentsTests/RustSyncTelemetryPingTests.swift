/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices
import XCTest

class RustSyncTelemetryPingTests: XCTestCase {
    func testValidJSON() {
        let json = """
        {"version":1,"uid":"b01a6f3d11cbb0f2ae2c940ab458b30a","syncs":[ {"when":1676416271.0,"took":837,"engines":[{"name":"passwords","when":167641627.0,"took":116,"incoming":{"applied":1},"outgoing":[{}]}]}]}
        """
        let syncs = [
            SyncInfo(at: Int64(1_676_416_271.0),
                     took: Int64(837),
                     engines: [EngineInfo(name: "passwords",
                                          at: Int64(1_676_416_271),
                                          took: Int64(116),
                                          incoming: IncomingInfo(applied: 1,
                                                                 failed: 0,
                                                                 newFailed: 0,
                                                                 reconciled: 0),
                                          outgoing: [OutgoingInfo(sent: 0, failed: 0)],
                                          failureReason: nil,
                                          validation: ValidationInfo(version: 0,
                                                                     problems: [ProblemInfo](),
                                                                     failureReason: nil))],
                     failureReason: nil),
        ]

        let expected = RustSyncTelemetryPing(version: 1,
                                             uid: "b01a6f3d11cbb0f2ae2c940ab458b30a",
                                             events: [EventInfo](),
                                             syncs: syncs)

        let actual = try! RustSyncTelemetryPing.fromJSONString(jsonObjectText: json)

        XCTAssertEqual(actual.uid, expected.uid)
        XCTAssertNotNil(actual.syncs[0].engines[0].incoming)
        XCTAssertNotNil(expected.syncs[0].engines[0].incoming)
        XCTAssertEqual(actual.syncs[0].engines[0].incoming!.applied,
                       expected.syncs[0].engines[0].incoming!.applied)
        XCTAssertEqual(actual.syncs[0].engines[0].outgoing[0].sent,
                       expected.syncs[0].engines[0].outgoing[0].sent)
        XCTAssertEqual(actual.syncs[0].engines[0].outgoing[0].failed,
                       expected.syncs[0].engines[0].outgoing[0].failed)
        XCTAssertTrue(actual.events.isEmpty)
    }

    func testHttpError() {
        let json = """
        {"version":1,"uid":"b01a6f3d11cbb0f2ae2c940ab458b30a","syncs":[{"when":1676416271.0,"took":134,"engines":[],"failureReason":{ "name":"httperror","code":500}}]}
        """
        let expected = RustSyncTelemetryPing(version: 1,
                                             uid: "b01a6f3d11cbb0f2ae2c940ab458b30a",
                                             events: [EventInfo](),
                                             syncs: [SyncInfo(at: Int64(1_676_416_271.0),
                                                              took: Int64(134),
                                                              engines: [EngineInfo](),
                                                              failureReason: FailureReason(name: FailureName.http,
                                                                                           message: nil,
                                                                                           code: 500))])
        let actual = try! RustSyncTelemetryPing.fromJSONString(jsonObjectText: json)

        XCTAssertEqual(actual.uid, expected.uid)
        XCTAssertEqual(actual.version, expected.version)
        XCTAssertEqual(actual.syncs[0].at, expected.syncs[0].at)
        XCTAssertEqual(actual.syncs[0].took, expected.syncs[0].took)
        XCTAssertTrue(actual.syncs[0].engines.isEmpty)
        XCTAssertEqual(actual.syncs[0].failureReason?.name, expected.syncs[0].failureReason?.name)
        XCTAssertNil(actual.syncs[0].failureReason?.message)
        XCTAssertEqual(actual.syncs[0].failureReason?.code, expected.syncs[0].failureReason?.code)
    }

    func testOtherError() {
        let json = """
        {"version":1,"uid":"b01a6f3d11cbb0f2ae2c940ab458b30a","syncs":[{"when":1676416271.0,"took":68,"engines":[],"failureReason":{ "name":"othererror","error":"other error"}}]}
        """
        let expected = RustSyncTelemetryPing(version: 1,
                                             uid: "b01a6f3d11cbb0f2ae2c940ab458b30a",
                                             events: [EventInfo](),
                                             syncs: [SyncInfo(at: Int64(1_676_416_271.0),
                                                              took: Int64(68),
                                                              engines: [EngineInfo](),
                                                              failureReason: FailureReason(name: FailureName.other,
                                                                                           message: "other error",
                                                                                           code: -1))])
        let actual = try! RustSyncTelemetryPing.fromJSONString(jsonObjectText: json)

        XCTAssertEqual(actual.uid, expected.uid)
        XCTAssertEqual(actual.version, expected.version)
        XCTAssertEqual(actual.syncs[0].at, expected.syncs[0].at)
        XCTAssertEqual(actual.syncs[0].took, expected.syncs[0].took)
        XCTAssertTrue(actual.syncs[0].engines.isEmpty)
        XCTAssertEqual(actual.syncs[0].failureReason?.name, expected.syncs[0].failureReason?.name)
        XCTAssertEqual(actual.syncs[0].failureReason?.code, expected.syncs[0].failureReason?.code)
        XCTAssertEqual(actual.syncs[0].failureReason?.message!, expected.syncs[0].failureReason?.message!)
    }

    func testInvalidJSON() {
        let json = """
        {"version";1}
        """

        XCTAssertThrowsError(try RustSyncTelemetryPing.fromJSONString(jsonObjectText: json))
    }
}
