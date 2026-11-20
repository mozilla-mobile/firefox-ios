// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class FoxDashTapBridgeTests: XCTestCase {
    private var receivedStates: [Bool]!

    override func setUp() {
        super.setUp()
        receivedStates = []
    }

    override func tearDown() {
        receivedStates = nil
        super.tearDown()
    }

    // MARK: - receive

    func test_receive_playingStarted_reportsPlaying() {
        let subject = createSubject()

        subject.receive(true)

        XCTAssertEqual(receivedStates, [true])
    }

    func test_receive_playingStopped_reportsNotPlaying() {
        let subject = createSubject()

        subject.receive(false)

        XCTAssertEqual(receivedStates, [false])
    }

    func test_receive_nonBooleanBody_ignoresBody() {
        let subject = createSubject()

        subject.receive("true")
        subject.receive(["playing": true])

        XCTAssertEqual(receivedStates, [])
    }

    // MARK: - tapScript

    func test_tapScript_point_forwardsCoordinatesToGame() {
        let subject = createSubject()

        let script = subject.tapScript(at: CGPoint(x: 120.5, y: 300))

        XCTAssertEqual(script, "window.foxDashTap?.(120.5, 300.0)")
    }

    // MARK: - Helpers

    private func createSubject(file: StaticString = #filePath, line: UInt = #line) -> FoxDashTapBridge {
        let subject = FoxDashTapBridge()
        trackForMemoryLeaks(subject, file: file, line: line)
        subject.onPlayingChange = { [weak self] isPlaying in
            self?.receivedStates.append(isPlaying)
        }
        return subject
    }
}
