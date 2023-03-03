// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import UIKit
import XCTest
@testable import Client

class SensitiveHostingControllerTests: XCTestCaseRootViewController {
    var mockNotificationCenter: SpyNotificationCenter!
    var mockAppAuthenticator: AppAuthenticationProtocol!

    override func setUp() {
        super.setUp()

        mockNotificationCenter = SpyNotificationCenter()
        mockAppAuthenticator = MockAppAuthenticator()
    }

    override func tearDown() {
        super.tearDown()
    }

    func createSubject() -> SensitiveHostingController<EmptyView> {
        let sensitiveHostingController = SensitiveHostingController(rootView: EmptyView(),
                                                                    notificationCenter: mockNotificationCenter,
                                                                    localAuthenticator: mockAppAuthenticator)

        return sensitiveHostingController
    }

    func testAuthenticatedAndNoBlur() {
        let sensitiveHostingVC = createSubject()
        sensitiveHostingVC.loadViewIfNeeded()
        mockNotificationCenter.post(name: UIApplication.willEnterForegroundNotification, object: nil)

        XCTAssertNotNil(sensitiveHostingVC.blurredOverlay)
    }

    func test_fail() {
        XCTFail()
    }
}
