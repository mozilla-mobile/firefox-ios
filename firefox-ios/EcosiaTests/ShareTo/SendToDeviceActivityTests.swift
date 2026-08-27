// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import XCTest

// Ecosia: Regression guard. Upstream Firefox offers "Send to Device" for any
// non-file URL (`!url.isFileURL`); Ecosia disables the activity outright since we don't
// offer synced-device sharing. If an upstream merge reintroduces the original check,
// a non-file URL below would start returning true again.
final class SendToDeviceActivityTests: XCTestCase {

    func testCanPerform_WithHttpURL_ReturnsFalse() {
        let subject = SendToDeviceActivity(activityType: .sendToDevice, url: URL(string: "https://example.com")!)
        let result = subject.canPerform(withActivityItems: [])
        XCTAssertFalse(result)
    }

    func testCanPerform_WithFileURL_ReturnsFalse() {
        let subject = SendToDeviceActivity(activityType: .sendToDevice, url: URL(fileURLWithPath: "/tmp/example.pdf"))
        let result = subject.canPerform(withActivityItems: [])
        XCTAssertFalse(result)
    }
}
