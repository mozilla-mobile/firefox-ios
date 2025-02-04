// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Storage
import Common
import UIKit
@testable import Client

class SurveySurfaceManagerTests: XCTestCase {
    private var messageManager: MockGleanPlumbMessageManagerProtocol!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        messageManager = MockGleanPlumbMessageManagerProtocol()
    }

    override func tearDown() {
        messageManager = nil
        super.tearDown()
    }

    func testNilMessage_surveySurfaceShouldNotShow() {
        let subject = createSubject()

        XCTAssertFalse(subject.shouldShowSurveySurface)
    }

    func testGoodButNotSurveyMessage_surveySurfaceShouldNotShow() {
        let subject = createSubject()
        let goodMessage = createMessage(for: .newTabCard, isExpired: false)
        messageManager.message = goodMessage

        XCTAssertFalse(subject.shouldShowSurveySurface)
    }

    func testGoodMessage_surveySurfaceShouldShow() {
        let subject = setupStandardConditions()

        XCTAssertTrue(subject.shouldShowSurveySurface)
    }

    func testManager_surveySurfaceIsNotNil() {
        let manager = setupStandardConditions()
        XCTAssertTrue(manager.shouldShowSurveySurface)

        let subject = manager.getSurveySurface()
        XCTAssertNotNil(subject)
    }

    func testManager_surveySurfaceInfoIsExpected() {
        let manager = setupStandardConditions()
        XCTAssertTrue(manager.shouldShowSurveySurface)

        let expectedImage = UIImage(named: "splash")

        let subject = manager.getSurveySurface()
        XCTAssertEqual(subject?.viewModel.info.text, "text label test")
        XCTAssertEqual(subject?.viewModel.info.takeSurveyButtonLabel, "button label test")
        XCTAssertEqual(subject?.viewModel.info.dismissActionLabel, "No Thanks")
        XCTAssertEqual(subject?.viewModel.info.image, expectedImage)
    }

    func testManager_noDelegatesCalled() {
        let manager = setupStandardConditions()
        XCTAssertTrue(manager.shouldShowSurveySurface)

        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 0)
        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 0)
    }

    func testManager_didDisplayMessage() {
        let manager = setupStandardConditions()
        XCTAssertTrue(manager.shouldShowSurveySurface)

        manager.didDisplayMessage()
        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 1)
        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 0)
    }

    func testManager_didTapTakeSurvey_called() {
        let manager = setupStandardConditions()
        XCTAssertTrue(manager.shouldShowSurveySurface)

        manager.didTapTakeSurvey()
        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 0)
        XCTAssertEqual(messageManager.onMessagePressedCalled, 1)
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 0)
    }

    func testManager_didTapDismissMessage() {
        let manager = setupStandardConditions()
        XCTAssertTrue(manager.shouldShowSurveySurface)

        manager.didTapDismissSurvey()
        XCTAssertEqual(messageManager.onMessageDisplayedCalled, 0)
        XCTAssertEqual(messageManager.onMessagePressedCalled, 0)
        XCTAssertEqual(messageManager.onMessageDismissedCalled, 1)
    }
}

// MARK: - Helpers
extension SurveySurfaceManagerTests {
    func createSubject(file: StaticString = #file,
                       line: UInt = #line
    ) -> SurveySurfaceManager {
        let subject = SurveySurfaceManager(windowUUID: windowUUID, and: messageManager)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    func createMessage(
        for surface: MessageSurfaceId = .survey,
        isExpired: Bool
    ) -> GleanPlumbMessage {
        let metadata = GleanPlumbMessageMetaData(id: "",
                                                 impressions: 0,
                                                 dismissals: 0,
                                                 isExpired: isExpired)

        return GleanPlumbMessage(id: "12345",
                                 data: MockSurveyMessageDataProtocol(surface: surface),
                                 action: "https://mozilla.com",
                                 triggerIfAll: [],
                                 exceptIfAny: [],
                                 style: MockStyleDataProtocol(),
                                 metadata: metadata)
    }

    func setupStandardConditions() -> SurveySurfaceManager {
        let subject = createSubject()
        let goodMessage = createMessage(isExpired: false)
        messageManager.message = goodMessage

        return subject
    }
}

// MARK: - MockSurveyMessageDataProtocol
class MockSurveyMessageDataProtocol: MessageDataProtocol {
    var surface: MessageSurfaceId
    var isControl = true
    var title: String? = "title label test"
    var text: String = "text label test"
    var buttonLabel: String? = "button label test"
    var experiment: String?
    var actionParams: [String: String] = [:]
    var microsurveyConfig: MicrosurveyConfig?

    init(surface: MessageSurfaceId = .survey) {
        self.surface = surface
    }
}
