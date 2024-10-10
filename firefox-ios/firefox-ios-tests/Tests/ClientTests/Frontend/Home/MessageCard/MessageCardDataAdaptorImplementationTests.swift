// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

class MessageCardDataAdaptorImplementationTests: XCTestCase {
    private var messageManager: MockGleanPlumbMessageManagerProtocol!
    private var didLoadNewDataCalled = 0

    override func setUp() {
        super.setUp()
        messageManager = MockGleanPlumbMessageManagerProtocol()
    }

    override func tearDown() {
        messageManager = nil
        didLoadNewDataCalled = 0
        super.tearDown()
    }

    func testEmptyData() {
        let subject = createSubject()
        XCTAssertNil(subject.getMessageCardData())
    }

    func testSettingDelegateUpdateData_noMessage() {
        let subject = createSubject()
        subject.delegate = self
        XCTAssertEqual(didLoadNewDataCalled, 0)
        XCTAssertNil(subject.getMessageCardData())
    }

    func testSettingDelegateUpdateData_validMessage() {
        let message = createMessage(isExpired: false)
        messageManager.message = message
        let subject = createSubject()
        subject.delegate = self
        XCTAssertEqual(didLoadNewDataCalled, 1)
        XCTAssertNotNil(subject.getMessageCardData())
        XCTAssertEqual(subject.getMessageCardData()?.id, message.id)
    }
}

extension MessageCardDataAdaptorImplementationTests: MessageCardDelegate {
    func didLoadNewData() {
        didLoadNewDataCalled += 1
    }
}

// MARK: - Helpers
extension MessageCardDataAdaptorImplementationTests {
    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> MessageCardDataAdaptorImplementation {
        let subject = MessageCardDataAdaptorImplementation(messagingManager: messageManager)
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
