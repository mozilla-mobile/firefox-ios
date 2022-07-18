// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Glean

@testable import Client

class GleanPlumbMessageManagerTests: XCTestCase {

    var sut: GleanPlumbMessageManager!
    var messagingStore: MockGleanPlumbMessageStore!

    override func setUp() {
        super.setUp()
        messagingStore = MockGleanPlumbMessageStore()
        sut = GleanPlumbMessageManager(messagingStore: messagingStore)
        Glean.shared.resetGlean(clearStores: true)
        Glean.shared.enableTestingMode()
    }

    override func tearDown() {
        super.tearDown()
        sut = nil
    }

    func testManagerOnMessageDisplayed() {
        guard let message = sut.getNextMessage(for: .newTabCard) else {
            XCTFail("Message was expected")
            return
        }

        sut.onMessageDisplayed(message)
        let messageMetadata = messagingStore.getMessageMetadata(messageId: "testId")
        XCTAssertFalse(messageMetadata.isExpired)
        XCTAssertEqual(messageMetadata.impressions, 1)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.shown)
    }

    func testManagerOnMessagePressed() {
        guard let message = sut.getNextMessage(for: .newTabCard) else {
            XCTFail("Message was expected")
            return
        }

        sut.onMessagePressed(message)
        let messageMetadata = messagingStore.getMessageMetadata(messageId: "testId")
        XCTAssertTrue(messageMetadata.isExpired)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.clicked)
    }

    func testManagerOnMessageDismissed() {
        guard let message = sut.getNextMessage(for: .newTabCard) else {
            XCTFail("Message was expected")
            return
        }

        sut.onMessageDismissed(message)
        let messageMetadata = messagingStore.getMessageMetadata(messageId: "testId")
        XCTAssertEqual(messageMetadata.dismissals, 1)
        XCTAssertTrue(messageMetadata.isExpired)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.dismissed)
    }

    func testManagerOnMessageExpired_WhenDismiss() {
        guard let message = sut.getNextMessage(for: .newTabCard) else {
            XCTFail("Message was expected")
            return
        }

        sut.onMessageDismissed(message)
        let messageMetadata = messagingStore.getMessageMetadata(messageId: "testId")
        XCTAssertTrue(messageMetadata.isExpired)
        testEventMetricRecordingSuccess(metric: GleanMetrics.Messaging.expired)
    }
}

// MARK: - MockGleanPlumbMessageStore
class MockGleanPlumbMessageStore: GleanPlumbMessagingStoreProtocol {

    private var metadata: GleanPlumbMessageMetaData
//    var impression: Int
//    var dismissals: Int
//    var isExpired: Bool

    var maxImpression = 3

    init(impression: Int = 0, dismissals: Int = 0, isExpired: Bool = false) {
//        self.impression = impression
//        self.dismissals = dismissals
//        self.isExpired = isExpired
        metadata = GleanPlumbMessageMetaData(id: "testId",
                                             impressions: impression,
                                             dismissals: dismissals,
                                             isExpired: isExpired)
    }

    func getMessageMetadata(messageId: String) -> GleanPlumbMessageMetaData {
        return metadata
    }

    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        metadata.impressions += 1

        if metadata.impressions > maxImpression {
            _ = onMessageExpired(metadata, shouldReport: true)
        }
    }

    func onMessagePressed(_ message: GleanPlumbMessage) {
        _ = onMessageExpired(metadata, shouldReport: false)
    }

    func onMessageDismissed(_ message: GleanPlumbMessage) {
        metadata.dismissals += 1
        _ = onMessageExpired(metadata, shouldReport: false)
    }

    func onMessageExpired(_ message: GleanPlumbMessageMetaData, shouldReport: Bool) -> GleanPlumbMessageMetaData {
        metadata.isExpired = true

        return metadata
    }
}
