// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import Shared
@testable import Client

class HomepageMessageCardViewModelTests: XCTestCase {
    private var adaptor: MockMessageCardDataAdaptor!
    private var messageManager: MockGleanPlumbMessageManagerProtocol!
    private var dismissClosureCalled = 0

    override func setUp() {
        super.setUp()
        adaptor = MockMessageCardDataAdaptor()
        messageManager = MockGleanPlumbMessageManagerProtocol()
    }

    override func tearDown() {
        adaptor = nil
        messageManager = nil
        super.tearDown()
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
            self.dismissClosureCalled += 1
        }

        subject.handleMessagePressed()
        XCTAssertEqual(messageManager.onMessagePressedCalled, 1)
        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 1, "Displayed through didLoadNewData, needs to be 1")
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 0)
        XCTAssertEqual(dismissClosureCalled, 1)
    }

    func testMessageDismiss() {
        adaptor.message = createMessage(isExpired: false)
        let subject = createSubject()
        subject.didLoadNewData()
        subject.dismissClosure = {
            self.dismissClosureCalled += 1
        }

        subject.handleMessageDismiss()
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 1)
        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 1, "Displayed through didLoadNewData, needs to be 1")
        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
        XCTAssertEqual(dismissClosureCalled, 1)
    }

    func testConfigureCallsMethod() throws {
        let subject = createSubject()
        let cell = SpyHomepageMessageCardCell(frame: .zero)
        let configuredCell = try XCTUnwrap(
            subject.configure(cell, at: IndexPath(item: 0, section: 0))
        ) as? SpyHomepageMessageCardCell
        XCTAssertEqual(configuredCell?.configureCalled, 1)
    }

    func testGetMessageEmpty() {
        let subject = createSubject()
        XCTAssertNil(subject.getMessage(for: .newTabCard))
    }

    func testGetMessageNotEmpty() {
        adaptor.message = createMessage(isExpired: false)
        let subject = createSubject()
        subject.didLoadNewData()
        XCTAssertNotNil(subject.getMessage(for: .newTabCard))
    }
}

// MARK: - Helpers
extension HomepageMessageCardViewModelTests {
    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> HomepageMessageCardViewModel {
        let subject = HomepageMessageCardViewModel(dataAdaptor: adaptor,
                                                   theme: LightTheme(),
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
                                 triggerIfAll: [],
                                 exceptIfAny: [],
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
    var isControl = true
    var title: String? = "Test"
    var text: String = "This is a test"
    var buttonLabel: String?
    var experiment: String?
    var actionParams: [String: String] = [:]
    var microsurveyConfig: MicrosurveyConfig?
}

// MARK: - MockStyleDataProtocol
class MockStyleDataProtocol: StyleDataProtocol {
    var priority: Int = 0
    var maxDisplayCount: Int = 3
}

// MARK: - MockGleanPlumbMessageManagerProtocol
class MockGleanPlumbMessageManagerProtocol: GleanPlumbMessageManagerProtocol {
    func onStartup() {}

    var message: GleanPlumbMessage?
    var recordedSurface: MessageSurfaceId?
    func getNextMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
        recordedSurface = surface
        if message?.surface == recordedSurface { return message }

        return nil
    }

    var onMessageDisplayedCalled = 0
    func onMessageDisplayed(_ message: GleanPlumbMessage) {
        onMessageDisplayedCalled += 1
    }

    var onMessagePressedCalled = 0
    func onMessagePressed(_ message: GleanPlumbMessage, window: WindowUUID?, shouldExpire: Bool) {
        onMessagePressedCalled += 1
    }

    var onMessageDismissedCalled = 0
    func onMessageDismissed(_ message: GleanPlumbMessage) {
        onMessageDismissedCalled += 1
    }

    func onMalformedMessage(id: String, surface: MessageSurfaceId) {}

    func messageForId(_ id: String) -> Client.GleanPlumbMessage? {
        if message?.id == id { return message }

        return nil
    }
}

// MARK: SpyHomepageMessageCardCell
class SpyHomepageMessageCardCell: HomepageMessageCardCell {
    var configureCalled = 0
    override func configure(viewModel: HomepageMessageCardViewModel, theme: Theme) {
        configureCalled += 1
    }
}
