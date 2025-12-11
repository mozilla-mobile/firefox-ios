// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class NotificationSurfaceManagerTests: XCTestCase {
    private var messageManager: MockGleanPlumbMessageManagerProtocol!
    private var notificationManager: MockNotificationManager!

    override func setUp() async throws {
        try await super.setUp()
        await DependencyHelperMock().bootstrapDependencies()
        notificationManager = MockNotificationManager()
        messageManager = MockGleanPlumbMessageManagerProtocol()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        messageManager = nil
        notificationManager = nil
    }

    func testShouldShowSurface_noMessage() {
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShowSurface)
    }

    func testShouldShowSurface_validMessage() {
        let subject = createSubject()
        let message = createMessage()
        messageManager.message = message

        XCTAssertTrue(subject.shouldShowSurface)
    }

    func testShowSurface_noMessage() async {
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShowSurface)

        await subject.showNotificationSurface()

        XCTAssertFalse(notificationManager.scheduleWithIntervalWasCalled)
        XCTAssertEqual(notificationManager.scheduledNotifications, 0)
    }

    func testShowSurface_validMessage() async {
        let subject = createSubject()
        let message = createMessage()
        messageManager.message = message

        XCTAssertTrue(subject.shouldShowSurface)

        await subject.showNotificationSurface()

        XCTAssertTrue(notificationManager.scheduleWithIntervalWasCalled)
        XCTAssertEqual(notificationManager.scheduledNotifications, 1)
    }

    @MainActor
    func testDidTapNotification_noMessageId() {
        let subject = createSubject()
        subject.didTapNotification("")

        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
    }

    @MainActor
    func testDidTapNotification_noMessageFound() {
        let subject = createSubject()
        subject.didTapNotification("test")

        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
    }

    @MainActor
    func testDidTapNotification_openNewTabAction() {
        let subject = createSubject()
        let message = createMessage()
        messageManager.message = message

        XCTAssertTrue(subject.shouldShowSurface)

        subject.didTapNotification("test-notification")

        XCTAssertEqual(messageManager.onMessagePressedCalled, 1)
    }

    @MainActor
    func testDidTapNotification_defaultAction() {
        let subject = createSubject()
        let message = createMessage(action: "test-action")
        messageManager.message = message

        XCTAssertTrue(subject.shouldShowSurface)

        subject.didTapNotification("test-notification")

        XCTAssertEqual(messageManager.onMessagePressedCalled, 1)
    }

    // MARK: Helpers
    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line
    ) -> NotificationSurfaceManager {
        let subject = NotificationSurfaceManager(messagingManager: messageManager,
                                                 notificationManager: notificationManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func createMessage(
        for surface: MessageSurfaceId = .notification,
        action: String = "://deep-link?url=homepanel/new-tab"
    ) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: false)

        return GleanPlumbMessage(id: "test-notification",
                                 data: MockNotificationMessageDataProtocol(surface: surface),
                                 action: action,
                                 triggerIfAll: [],
                                 exceptIfAny: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }

    private func createEngagementMessage(for surface: MessageSurfaceId = .notification) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: false)

        return GleanPlumbMessage(id: "test-notification",
                                 data: MockNotificationMessageDataProtocol(surface: surface),
                                 action: "://deep-link?url=homepanel/new-tab",
                                 triggerIfAll: ["INACTIVE_NEW_USER", "ALLOWED_TIPS_NOTIFICATIONS"],
                                 exceptIfAny: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }
}

// MARK: - MockNotificationMessageDataProtocol
class MockNotificationMessageDataProtocol: MessageDataProtocol {
    var surface: MessageSurfaceId
    var isControl = true
    var title: String? = "title label test"
    var text = "text label test"
    var buttonLabel: String? = "button label test"
    var experiment: String?
    var actionParams: [String: String] = [:]
    var microsurveyConfig: MicrosurveyConfig?

    init(surface: MessageSurfaceId = .notification) {
        self.surface = surface
    }
}
