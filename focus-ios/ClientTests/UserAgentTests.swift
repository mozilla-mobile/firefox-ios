/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

#if FOCUS
@testable import Firefox_Focus
#else
@testable import Firefox_Klar
#endif

class UserAgentTests: XCTestCase {
    private let fakeUserAgent = "a-fake-browser"
    
    override func setUp() {
        super.setUp()
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
            let range = ua.range(of: "^Mozilla/5\\.0 \\(.+\\) AppleWebKit/[0-9\\.]+ \\(KHTML, like Gecko\\) Version/[0-9\\.]+ Safari/[0-9\\.]", options: .regularExpression)
            return range != nil
        }
        // Sample valid user agent string
        // Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_4) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1 Safari/605.1.15
        XCTAssertTrue(compare(UserAgent.desktopUserAgent()), "Desktop user agent computes correctly.")
    }
}
