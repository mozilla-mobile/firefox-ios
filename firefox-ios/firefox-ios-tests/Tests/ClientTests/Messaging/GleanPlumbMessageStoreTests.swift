// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class GleanPlumbMessageStoreTests: XCTestCase {
    var subject: GleanPlumbMessageStore!
    let messageId = "testId"

    override func setUp() {
        super.setUp()
        subject = GleanPlumbMessageStore()
        resetUserDefaults()
    }

    override func tearDown() {
        super.tearDown()
        resetUserDefaults()
        subject = nil
    }

    func testImpression_OnMessageDisplayed() {
        let message = createMessage(messageId: messageId)
        subject.onMessageDisplayed(message)

        XCTAssertEqual(message.metadata.impressions, 1)
        XCTAssertFalse(message.metadata.isExpired)
    }

    func testOnMessageExpired_WhenPressed() {
        let message = createMessage(messageId: messageId)
        subject.onMessageDisplayed(message)
        subject.onMessagePressed(message, shouldExpire: true)

        XCTAssertEqual(message.metadata.impressions, 1)
        XCTAssertTrue(message.metadata.isExpired)
    }

    func testOnMessageExpired_WhenPressedAndShouldNotExpire() {
        let message = createMessage(messageId: messageId)
        subject.onMessageDisplayed(message)
        subject.onMessagePressed(message, shouldExpire: false)

        XCTAssertEqual(message.metadata.impressions, 1)
        XCTAssertFalse(message.metadata.isExpired)
    }

    func testOnMessageExpired_WhenDismiss() {
        let message = createMessage(messageId: messageId)
        subject.onMessageDisplayed(message)
        subject.onMessageDismissed(message)

        XCTAssertEqual(message.metadata.impressions, 1)
        XCTAssertTrue(message.metadata.isExpired)
    }

    // MARK: - Helper function
    private func createMessage(messageId: String) -> GleanPlumbMessage {
        let styleData = MockStyleData(priority: 50, maxDisplayCount: 3)

        return GleanPlumbMessage(id: messageId,
                                 data: MockMessageData(),
                                 action: "MAKE_DEFAULT",
                                 triggerIfAll: ["ALWAYS"],
                                 exceptIfAny: [],
                                 style: styleData,
                                 metadata: subject.getMessageMetadata(messageId: messageId))
    }

    private func resetUserDefaults() {
        let key = "\(GleanPlumbMessageStore.rootKey)\(messageId)"
        UserDefaults.standard.removeObject(forKey: key)
    }
}

// MARK: - MockStyleData
class MockMessageData: MessageDataProtocol {
    var surface: MessageSurfaceId
    var isControl: Bool
    var title: String?
    var text: String
    var buttonLabel: String?
    var experiment: String?
    var actionParams: [String: String]
    var microsurveyConfig: MicrosurveyConfig?

    init(
        surface: MessageSurfaceId = .newTabCard,
        isControl: Bool = false,
        title: String? = "Title",
        text: String = "text",
        buttonLabel: String? = "Tap",
        actionParams: [String: String] = [:],
        microsurveyConfig: MicrosurveyConfig? = nil
    ) {
        self.surface = surface
        self.isControl = isControl
        self.title = title
        self.text = text
        self.buttonLabel = buttonLabel
        self.actionParams = actionParams
        self.microsurveyConfig = microsurveyConfig
    }
}

// MARK: - MockStyleData
class MockStyleData: StyleDataProtocol {
    var priority: Int
    var maxDisplayCount: Int

    init(priority: Int, maxDisplayCount: Int) {
        self.priority = priority
        self.maxDisplayCount = maxDisplayCount
    }
}
