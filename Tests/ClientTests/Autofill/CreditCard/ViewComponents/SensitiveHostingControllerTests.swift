// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import UIKit
import XCTest
@testable import Client

class SensitiveHostingControllerTests: XCTestCaseRootViewController {
    var mockNotificationCenter: MockNotificationCenter!
    var mockAppAuthenticator: MockAppAuthenticator!

    override func setUp() {
        super.setUp()

        mockNotificationCenter = MockNotificationCenter()
        mockAppAuthenticator = MockAppAuthenticator()
    }

    override func tearDown() {
        super.tearDown()

        mockNotificationCenter = nil
        mockAppAuthenticator = nil
    }

    func createSubject() -> SensitiveHostingController<EmptyView> {
        let sensitiveHostingController = SensitiveHostingController(rootView: EmptyView(),
                                                                    notificationCenter: mockNotificationCenter,
                                                                    localAuthenticator: mockAppAuthenticator)
        trackForMemoryLeaks(sensitiveHostingController)
        return sensitiveHostingController
    }

    func testAddObservers() {
        _ = createSubject()

        XCTAssertEqual(mockNotificationCenter.addObserverCallCount, 2)
    }

    func testRemoveObservers() {
        _ = createSubject()

        addTeardownBlock {
            XCTAssertEqual(self.mockNotificationCenter.removeObserverCallCount, 1)
        }
    }

    func testViewExistsAndNotificationCalled() {
        let sensitiveHostingVC = createSubject()
        sensitiveHostingVC.loadViewIfNeeded()
        mockNotificationCenter.post(name: UIApplication.willEnterForegroundNotification)
        mockNotificationCenter.post(name: UIApplication.didEnterBackgroundNotification)

        XCTAssertEqual(mockNotificationCenter.postCallCount, 2)
        XCTAssertNotNil(sensitiveHostingVC)
    }
}
