// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

class GleanPlumbMessageManagerTests: XCTestCase {

    var sut: GleanPlumbMessageManager!

    override func setUp() {
        super.setUp()
        sut = GleanPlumbMessageManager()
        Glean.shared.resetGlean(clearStores: true)
        Glean.shared.enableTestingMode()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testOnMessageDisplayed() {
        if let message = sut.getNextMessage(for: .newTabCard) {
            sut.onMessageDisplayed(message)
            testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.shown)
        }
    }

    func testOnMessageonMessagePressed() {
        if let message = sut.getNextMessage(for: .newTabCard) {
            sut.onMessagePressed(message)
            testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.clicked)
        }
    }

    func testOnMessageonMessageDismissed() {
        if let message = sut.getNextMessage(for: .newTabCard) {
            sut.onMessageDismissed(message)
            testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.dismissed)
        }
    }
}
