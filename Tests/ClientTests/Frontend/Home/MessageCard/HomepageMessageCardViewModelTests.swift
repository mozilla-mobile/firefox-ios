// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class HomepageMessageCardViewModelTests: XCTestCase {

    private var adaptor: MockMessageCardDataAdaptor!
    private var messageManager: MockGleanPlumbMessageManagerProtocol!

    override func setUp() {
        super.setUp()
        adaptor = MockMessageCardDataAdaptor()
        messageManager = MockGleanPlumbMessageManagerProtocol()
    }

    override func tearDown() {
        super.tearDown()
        adaptor = nil
        messageManager = nil
    }

    func testNilMessage() {
        let subject = createSubject()

        XCTAssertFalse(subject.hasData)
        XCTAssertTrue(subject.isEnabled)
        XCTAssertEqual(subject.headerViewModel, .emptyHeader)
        XCTAssertEqual(subject.numberOfItemsInSection(), 1)
        XCTAssertEqual(subject.sectionType, .messageCard)
        XCTAssertFalse(subject.shouldDisplayMessageCard)
    }

    func testExpiredMessage() {
        adaptor.message = createMessage(isExpired: true)
        let subject = createSubject()
        subject.didLoadNewData()

        XCTAssertFalse(subject.hasData)
        XCTAssertTrue(subject.isEnabled)
        XCTAssertEqual(subject.headerViewModel, .emptyHeader)
        XCTAssertEqual(subject.numberOfItemsInSection(), 1)
        XCTAssertEqual(subject.sectionType, .messageCard)
        XCTAssertFalse(subject.shouldDisplayMessageCard)
    }

    func testNotExpiredMessage() {
        adaptor.message = createMessage(isExpired: false)
        let subject = createSubject()
        subject.didLoadNewData()

        XCTAssertTrue(subject.hasData)
        XCTAssertTrue(subject.isEnabled)
        XCTAssertEqual(subject.headerViewModel, .emptyHeader)
        XCTAssertEqual(subject.numberOfItemsInSection(), 1)
        XCTAssertEqual(subject.sectionType, .messageCard)
        XCTAssertTrue(subject.shouldDisplayMessageCard)
    }

    func testMessageDisplayed() {
        adaptor.message = createMessage(isExpired: false)
        let subject = createSubject()
        subject.didLoadNewData() // This calls subject.handleMessageDisplayed()
        subject.dismissClosure = {
            XCTFail("Should not be called")
        }

        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 1)
        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 0)
    }

    func testMessagePressed() {
        adaptor.message = createMessage(isExpired: false)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.dismissClosure = {
            XCTAssert(true, "Dismiss closure is called")
        }

        subject.handleMessagePressed()
        XCTAssertEqual(messageManager.onMessagePressedCalled, 1)
        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 1, "Displayed through didLoadNewData, needs to be 1")
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 0)
    }

    func testMessageDismiss() {
        adaptor.message = createMessage(isExpired: false)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.dismissClosure = {
            XCTAssert(true, "Dismiss closure is called")
        }

        subject.handleMessageDismiss()
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 1)
        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 1, "Displayed through didLoadNewData, needs to be 1")
        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
    }

    // TODO:
    // Laurie - func getMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
    // Laurie - test configure

    // other file
    // Laurie - test adaptor
}

// MARK: - Helpers
extension HomepageMessageCardViewModelTests {

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> HomepageMessageCardViewModel {
        let subject = HomepageMessageCardViewModel(dataAdaptor: adaptor,
                                                   messagingManager: messageManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    func createMessage(isExpired: Bool) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: isExpired)

        return GleanPlumbMessage(id: "12345",
                                 data: MockMessageDataProtocol(),
                                 action: "",
                                 triggers: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }
}

// MARK: - MockMessageCardDataAdaptor
class MockMessageCardDataAdaptor: MessageCardDataAdaptor {

    var message: GleanPlumbMessage?

    func getMessageCardData() -> GleanPlumbMessage? {
        return message
    }
}

// MARK: - MockMessageDataProtocol
class MockMessageDataProtocol: MessageDataProtocol {
    var surface: MessageSurfaceId = .newTabCard
    var isControl: Bool = true
    var title: String? = "Test"
    var text: String = "This is a test"
    var buttonLabel: String?
}

// MARK: - MockStyleDataProtocol
class MockStyleDataProtocol: StyleDataProtocol {
    var priority: Int = 0
    var maxDisplayCount: Int = 3
}

// MARK: - MockGleanPlumbMessageManagerProtocol
class MockGleanPlumbMessageManagerProtocol: GleanPlumbMessageManagerProtocol {
    func onStartup() {}

    var recordedSurface: MessageSurfaceId?
    func getNextMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
        recordedSurface = surface
        return nil
    }

    var onMessageDisplayedCalled = 0
    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        onMessageDisplayedCalled += 1
    }

    var onMessagePressedCalled = 0
    func onMessagePressed(_ message: GleanPlumbMessage) {
        onMessagePressedCalled += 1
    }

    var onMessageDismissedCalled = 0
    func onMessageDismissed(_ message: GleanPlumbMessage) {
        onMessageDismissedCalled += 1
    }

    func onMalformedMessage(messageKey: String) {}
}
