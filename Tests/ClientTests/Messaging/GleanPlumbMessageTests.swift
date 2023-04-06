// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class GleanPlumbMessageTests: XCTestCase {
    // MARK: - Properties
    var subject: GleanPlumbMessage!

    let experimentKey = "not-a-silly-experiment-"
    let messageID = "not-a-silly-experiment-en"

    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Test isUnderExperimentWith
    func testMessageIsUnderExperiment_BadExperimentKey_fails() {
        subject = createMessage(messageId: messageID)

        XCTAssertFalse(subject.isUnderExperimentWith(key: nil))
    }

    func testMessageIsUnderExperiment_isControlIsTrue_passes() {
        subject = createMessage(messageId: messageID,
                                mockData: MockMessageData(isControl: true))

        XCTAssertTrue(subject.isUnderExperimentWith(key: experimentKey))
    }

    func testMessageIsUnderExperiment_idContainsExperimentID_isTrue() {
        subject = createMessage(messageId: messageID)

        XCTAssertTrue(subject.isUnderExperimentWith(key: experimentKey))
    }

    func testMessageIsUnderExperiment_idContainsExperimentID_isFalse() {
        subject = createMessage(messageId: messageID)

        XCTAssertFalse(subject.isUnderExperimentWith(key: "a-bad-experiment-id"))
    }

    func testMessageIsUnderExperiment_idDoesNotContainExperimentID_ButMatches() {
        subject = createMessage(messageId: messageID)

        XCTAssertTrue(subject.isUnderExperimentWith(key: messageID))
    }

    // MARK: - Helpers
    private func createMessage(
        messageId: String,
        mockData: MockMessageData = MockMessageData()
    ) -> GleanPlumbMessage {
        let styleData = MockStyleData(priority: 50, maxDisplayCount: 3)

        let messageMetadata = GleanPlumbMessageMetaData(id: messageId,
                                                        impressions: 0,
                                                        dismissals: 0,
                                                        isExpired: false)

        return GleanPlumbMessage(id: messageId,
                                 data: mockData,
                                 action: "MAKE_DEFAULT_BROWSER",
                                 triggers: ["ALWAYS"],
                                 style: styleData,
                                 metadata: messageMetadata)
    }
}
