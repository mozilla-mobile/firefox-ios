// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client

@MainActor
final class BridgeTests: XCTestCase {
    func test_bridge_receiveFromA_forwardsToB() {
        let subject = createSubject(aName: "a", bName: "b")
        subject.bridge.receive(handlerName: "a", body: ["foo": "bar"])

        XCTAssertEqual(subject.portB.receivedJSON, [#"{"foo":"bar"}"#])
        XCTAssertTrue(subject.portA.receivedJSON.isEmpty)
    }

    func test_bridge_receiveFromB_forwardsToA() {
        let subject = createSubject(aName: "a", bName: "b")
        subject.bridge.receive(handlerName: "b", body: ["x": 1])

        XCTAssertEqual(subject.portA.receivedJSON, [#"{"x":1}"#])
        XCTAssertTrue(subject.portB.receivedJSON.isEmpty)
    }

    func test_bridge_receive_invalidJSON_doesNotForward() {
        let subject = createSubject(aName: "a", bName: "b")
        // Message with invalid JSON object
        subject.bridge.receive(handlerName: "a", body: "not a dict")

        XCTAssertTrue(subject.portA.receivedJSON.isEmpty)
        XCTAssertTrue(subject.portB.receivedJSON.isEmpty)
    }

    func test_bridge_send_sendsToGivenEndpoint() {
        let subject = createSubject(aName: "a", bName: "b")
        subject.bridge.send(#"{"hello":true}"#, to: subject.portB)

        XCTAssertEqual(subject.portB.receivedJSON, [#"{"hello":true}"#])
        XCTAssertTrue(subject.portA.receivedJSON.isEmpty)
    }

    func test_bridge_init_registersScriptHandlers() {
        let subject = createSubject(aName: "a", bName: "b")
        XCTAssertEqual(subject.portA.registerCount, 1)
        XCTAssertEqual(subject.portB.registerCount, 1)
    }

    func test_bridge_teardown_unregistersScriptHandlers() {
        let subject = createSubject(aName: "a", bName: "b")
        XCTAssertEqual(subject.portA.unregisterCount, 0)
        XCTAssertEqual(subject.portB.unregisterCount, 0)

        subject.bridge.teardown()

        XCTAssertEqual(subject.portA.unregisterCount, 1)
        XCTAssertEqual(subject.portB.unregisterCount, 1)
    }

    private struct Subject {
        let portA: FakeEndpoint
        let portB: FakeEndpoint
        let bridge: Bridge
    }

    private func createSubject(aName: String, bName: String) -> Subject {
        let portA = FakeEndpoint(name: aName)
        let portB = FakeEndpoint(name: bName)
        let subject = Bridge(portA: portA, portB: portB)
        return Subject(
            portA: portA,
            portB: portB,
            bridge: subject,
        )
    }
}
