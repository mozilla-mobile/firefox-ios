// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest

class ChangeUserAgentTests: XCTestCase {
    struct ChangeUserAgentsMockData {
        let urlString: String
        let isChangedUA: Bool
        let isPrivate: Bool
        let expectContainsURL: Bool
    }

    private var testFile: URL!

    override func setUp() {
        super.setUp()
        testFile = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test-changed-ua-set-of-hosts.xcarchive")
    }

    override func tearDown() {
        super.tearDown()
        testFile = nil
    }

    func testUpdateAndContainsDidChangeUANotPrivate() {
        let testMockData = ChangeUserAgentsMockData(urlString: "https://www.google.com", isChangedUA: true, isPrivate: false, expectContainsURL: true)
        let url = URL(string: testMockData.urlString)!

        Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: testMockData.isChangedUA, isPrivate: testMockData.isPrivate)
        XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url), testMockData.expectContainsURL)
    }

    func testUpdateAndContainsDidChangeUAAndPrivate() {
        let testMockData = ChangeUserAgentsMockData(urlString: "https://www.mozilla.org", isChangedUA: true, isPrivate: true, expectContainsURL: true)
        let url = URL(string: testMockData.urlString)!

        Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: testMockData.isChangedUA, isPrivate: testMockData.isPrivate)
        XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url), testMockData.expectContainsURL)
    }

    func testUpdateAndContainsNoChangeUANotPrivate() {
        let testMockData = ChangeUserAgentsMockData(urlString: "https://www.apple.com", isChangedUA: false, isPrivate: false, expectContainsURL: false)

        let url = URL(string: testMockData.urlString)!

        Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: testMockData.isChangedUA, isPrivate: testMockData.isPrivate)
        XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url), testMockData.expectContainsURL)
    }

    func testUpdateAndContainsNoChangeUAAndPrivate() {
        let testMockData = ChangeUserAgentsMockData(urlString: "https://www.yahoo.com", isChangedUA: false, isPrivate: true, expectContainsURL: false)
        let url = URL(string: testMockData.urlString)!

        Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: testMockData.isChangedUA, isPrivate: testMockData.isPrivate)
        XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url), testMockData.expectContainsURL)
    }

    func tryAllCasesForUpdateAndContains() {
        let testMockData1 = ChangeUserAgentsMockData(urlString: "https://www.google.com", isChangedUA: true, isPrivate: false, expectContainsURL: true)
        let testMockData2 = ChangeUserAgentsMockData(urlString: "https://www.mozilla.org", isChangedUA: true, isPrivate: true, expectContainsURL: true)
        let testMockData3 = ChangeUserAgentsMockData(urlString: "https://www.apple.com", isChangedUA: false, isPrivate: false, expectContainsURL: false)
        let testMockData4 = ChangeUserAgentsMockData(urlString: "https://www.yahoo.com", isChangedUA: false, isPrivate: true, expectContainsURL: false)
        let testCases = [testMockData1, testMockData2, testMockData3, testMockData4]
        for testCase in testCases {
            let url = URL(string: testCase.urlString)!
            Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: testCase.isChangedUA, isPrivate: testCase.isPrivate)
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
