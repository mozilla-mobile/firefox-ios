// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import XCTest

@testable import Client

final class MessageCardMiddlewareTests: XCTestCase, StoreTestUtility {
    var mockStore: MockStoreForMiddleware<AppState>!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        setupStore()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        resetStore()
        super.tearDown()
    }

    func test_initializeAction_getMessageCardData() throws {
        let messagingManager = MockGleanPlumbMessageManagerProtocol()
        let message = createMessage()
        messagingManager.message = message
        let subject = createSubject(messagingManager: messagingManager)

        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        let expectation = XCTestExpectation(description: "Homepage action initialize dispatched")

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.messageCardProvider(AppState(), action)

        wait(for: [expectation])

        let actionCalled = try XCTUnwrap(mockStore.dispatchedActions.first as? MessageCardAction)
        let actionType = try XCTUnwrap(actionCalled.actionType as? MessageCardMiddlewareActionType)

        XCTAssertEqual(actionType, MessageCardMiddlewareActionType.initialize)
        XCTAssertEqual(mockStore.dispatchedActions.count, 1)
        XCTAssertEqual(actionCalled.messageCardConfiguration?.title, "Test")
        XCTAssertEqual(actionCalled.messageCardConfiguration?.description, "This is a test")
        XCTAssertEqual(actionCalled.messageCardConfiguration?.buttonLabel, "This is a test button label")
        XCTAssertEqual(messagingManager.onMessageDisplayedCalled, 1)
    }

    func test_initializeAction_withInvalidSurface_doesNotGetMessageCardData() throws {
        let messagingManager = MockGleanPlumbMessageManagerProtocol()
        let message = createMessage(with: MockMessageData(surface: .microsurvey))
        messagingManager.message = message
        let subject = createSubject(messagingManager: messagingManager)

        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)
        let expectation = XCTestExpectation(description: "Homepage action initialize dispatched")
        expectation.isInverted = true

        mockStore.dispatchCalled = {
            expectation.fulfill()
        }

        subject.messageCardProvider(AppState(), action)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(mockStore.dispatchedActions.count, 0)
        XCTAssertEqual(messagingManager.onMessageDisplayedCalled, 0)
    }

    func test_tappedOnActionButton_performsActionAndDismissesMessageCard() throws {
        let messagingManager = MockGleanPlumbMessageManagerProtocol()
        let message = createMessage(with: MockMessageData(surface: .newTabCard))
        messagingManager.message = message
        let subject = createSubject(messagingManager: messagingManager)

        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)

        subject.messageCardProvider(AppState(), action)

        let secondaryAction = MessageCardAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MessageCardActionType.tappedOnActionButton
        )

        subject.messageCardProvider(AppState(), secondaryAction)

        XCTAssertEqual(messagingManager.onMessagePressedCalled, 1)
    }

    func test_tappedOnCloseButton_dismissesMessageCard() throws {
        let messagingManager = MockGleanPlumbMessageManagerProtocol()
        let message = createMessage(with: MockMessageData(surface: .newTabCard))
        messagingManager.message = message
        let subject = createSubject(messagingManager: messagingManager)

        let action = HomepageAction(windowUUID: .XCTestDefaultUUID, actionType: HomepageActionType.initialize)

        subject.messageCardProvider(AppState(), action)

        let secondaryAction = MessageCardAction(
            windowUUID: .XCTestDefaultUUID,
            actionType: MessageCardActionType.tappedOnCloseButton
        )

        subject.messageCardProvider(AppState(), secondaryAction)

        XCTAssertEqual(messagingManager.onMessageDismissedCalled, 1)
    }

    // MARK: - Helpers
    private func createSubject(messagingManager: GleanPlumbMessageManagerProtocol) -> MessageCardMiddleware {
        return MessageCardMiddleware(messagingManager: messagingManager)
    }

    func createMessage(with data: MessageDataProtocol = MockMessageDataProtocol()) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: false)

        return GleanPlumbMessage(id: "12345",
                                 data: data,
                                 action: "",
                                 triggerIfAll: [],
                                 exceptIfAny: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }

    // MARK: StoreTestUtility
    func setupAppState() -> AppState {
        return AppState(
            activeScreens: ActiveScreensState(
                screens: [
                    .homepage(
                        HomepageState(
                            windowUUID: .XCTestDefaultUUID
                        )
                    ),
                ]
            )
        )
    }

    func setupStore() {
        mockStore = MockStoreForMiddleware(state: setupAppState())
        StoreTestUtilityHelper.setupStore(with: mockStore)
    }

    // In order to avoid flaky tests, we should reset the store
    // similar to production
    func resetStore() {
        StoreTestUtilityHelper.resetStore()
    }
}
