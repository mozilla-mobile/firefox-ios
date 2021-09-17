/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SupportUtilsTest: XCTestCase {
    
    // Try to create a URL for every support topic and make sure that none of them
    // fall back to the default URL we use in case of failure during URL building.
    func testSupportTopics() throws {
        for topic in SupportTopic.allCases {
            XCTAssertNotEqual(URL(forSupportTopic: topic), URL(string: SupportTopic.fallbackURL)!)
        }
    }
    
}
