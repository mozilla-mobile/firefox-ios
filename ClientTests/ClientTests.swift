/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import XCTest

import Shared
import Storage
import WebKit
@testable import Client

class ClientTests: XCTestCase {

    func testSyncUA() {
        let ua = UserAgent.syncUserAgent
        let device = DeviceInfo.deviceModel()
        let systemVersion = UIDevice.current.systemVersion
        let expectedRegex = "^Firefox-iOS-Sync/[0-9\\.]+b[0-9]* \\(\(device); iPhone OS \(systemVersion)\\) \\([-_A-Za-z0-9= \\(\\)]+\\)$"
        let loc = ua.range(of: expectedRegex, options: .regularExpression)
        XCTAssertTrue(loc != nil, "Sync UA is as expected. Was \(ua)")
    }

    func testMobileUserAgent() {
        let compare: (String) -> Bool = { ua in
            let range = ua.range(of: "^Mozilla/5\\.0 \\(.+\\) AppleWebKit/[0-9\\.]+ \\(KHTML, like Gecko\\)", options: .regularExpression)
            return range != nil
        }
        XCTAssertTrue(compare(UserAgent.mobileUserAgent()), "User agent computes correctly.")
    }
    
    func testDesktopUserAgent() {
        let compare: (String) -> Bool = { ua in
            let range = ua.range(of: "^Mozilla/5\\.0 \\(Macintosh; Intel Mac OS X [0-9\\.]+\\)", options: .regularExpression)
            return range != nil
        }
        XCTAssertTrue(compare(UserAgent.desktopUserAgent()), "Desktop user agent computes correctly.")
    }
}
