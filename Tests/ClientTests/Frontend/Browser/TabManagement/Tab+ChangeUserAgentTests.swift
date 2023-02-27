// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

import XCTest

class ChangeUserAgentTests: XCTestCase {
    struct ChangeUserAgentsMockData {
        let urlString: String
        let userAgentWasChanged: Bool
        let isPrivate: Bool
        let expectContainsURL: Bool
    }
    // Create a mock file to use for testing
    let testFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test-changed-ua-set-of-hosts.xcarchive")
    override func setUp() {
        // Ensure test file is empty before each test
        try? Data().write(to: testFile)
    }
    func testUpdateAndContains() {
        let testMockData1 = ChangeUserAgentsMockData(urlString: "https://www.google.com", userAgentWasChanged: true, isPrivate: false, expectContainsURL: true)
        let testMockData2 = ChangeUserAgentsMockData(urlString: "https://www.mozilla.org", userAgentWasChanged: true, isPrivate: true, expectContainsURL: true)
        let testMockData3 = ChangeUserAgentsMockData(urlString: "https://www.apple.com", userAgentWasChanged: false, isPrivate: false, expectContainsURL: false)
        let testMockData4 = ChangeUserAgentsMockData(urlString: "https://www.yahoo.com", userAgentWasChanged: false, isPrivate: true, expectContainsURL: false)
        let testCases = [testMockData1, testMockData2, testMockData3, testMockData4]
        for testCase in testCases {
            let url = URL(string: testCase.urlString)!
            Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: testCase.userAgentWasChanged, isPrivate: testCase.isPrivate)
            XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url), testCase.expectContainsURL)
        }
    }
    func testClear() {
        let url = URL(string: "https://www.google.com")!
        Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: true, isPrivate: false)
        XCTAssert(Tab.ChangeUserAgent.contains(url: url))

        Tab.ChangeUserAgent.clear()
        XCTAssertFalse(Tab.ChangeUserAgent.contains(url: url))
    }
}
