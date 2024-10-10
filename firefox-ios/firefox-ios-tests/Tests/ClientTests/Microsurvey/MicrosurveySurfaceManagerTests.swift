// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

final class MicrosurveySurfaceManagerTests: XCTestCase {
    private var messageManager: MockGleanPlumbMessageManagerProtocol!
    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        messageManager = MockGleanPlumbMessageManagerProtocol()
    }

    override func tearDown() {
        messageManager = nil
        AppContainer.shared.reset()
        super.tearDown()
    }

    func testNilMessage_microsurveyShouldNotShow() {
        let subject = createSubject()
        let model = subject.showMicrosurveyPrompt()
        XCTAssertNil(model)
    }

    func testValidMessage_microsurveyShouldShow() {
        let subject = createSubject()
        messageManager.message = createMessage()

        let model = subject.showMicrosurveyPrompt()
        XCTAssertNotNil(model)
        XCTAssertEqual(model?.promptTitle, "title label test")
        XCTAssertEqual(model?.promptButtonLabel, "button label test")
        XCTAssertEqual(model?.surveyQuestion, "text label test")
        XCTAssertEqual(model?.surveyOptions, ["yes", "no"])
    }

    func testInvalidMessageSurface_microsurveyShouldNotShow() {
        let subject = createSubject()
        messageManager.message = createMessage(for: .newTabCard)
        let model = subject.showMicrosurveyPrompt()
        XCTAssertNil(model)
    }

    func testManager_noDelegatesCalled() {
        let subject = createSubject()
        messageManager.message = createMessage()
        _ = subject.showMicrosurveyPrompt()

        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 0)
        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 0)
    }

    func testManager_messageDisplayedCalled() {
        let subject = createSubject()
        messageManager.message = createMessage()
        _ = subject.showMicrosurveyPrompt()

        subject.handleMessageDisplayed()

        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 1)
        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 0)
    }

    func testManager_messagePressedCalled() {
        let subject = createSubject()
        messageManager.message = createMessage()
        _ = subject.showMicrosurveyPrompt()

        subject.handleMessagePressed()

        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 0)
        XCTAssertEqual(messageManager.onMessagePressedCalled, 1)
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 0)
    }

    func testManager_messageDimissCalled() {
        let subject = createSubject()
        messageManager.message = createMessage()
        _ = subject.showMicrosurveyPrompt()

        subject.handleMessageDismiss()

        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 0)
        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 1)
    }

    private func createSubject(
        file: StaticString = #file,
        line: UInt = #line
    ) -> MicrosurveySurfaceManager {
        let subject = MicrosurveySurfaceManager(messagingManager: messageManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createMessage(
        for surface: MessageSurfaceId = .microsurvey,
        isExpired: Bool = false
    ) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: isExpired)

        return GleanPlumbMessage(id: "12345",
                                 data: MockMicrosurveyMessageDataProtocol(surface: surface),
                                 action: "https://mozilla.com",
                                 triggerIfAll: [],
                                 exceptIfAny: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }
}

class MockMicrosurveyMessageDataProtocol: MessageDataProtocol {
    var surface: MessageSurfaceId
    var isControl = true
    var title: String? = "title label test"
    var text: String = "text label test"
    var buttonLabel: String? = "button label test"
    var experiment: String?
    var actionParams: [String: String] = [:]
    var microsurveyConfig: MicrosurveyConfig? = MicrosurveyConfig(options: ["yes", "no"])

    init(surface: MessageSurfaceId) {
        self.surface = surface
    }
}
