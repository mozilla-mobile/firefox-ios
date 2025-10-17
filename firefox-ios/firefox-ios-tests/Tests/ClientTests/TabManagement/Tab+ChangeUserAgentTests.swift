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

    private var testFilename: String!

    private var file: URL!

    override func setUp() {
        super.setUp()
        testFilename = "test-changed-ua-set-of-hosts.xcarchive"
        Tab.ChangeUserAgent.pathComponent = testFilename
        file = {
            let root = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            return root.appendingPathComponent(testFilename)
        }()
    }

    override func tearDown() {
        super.tearDown()
        testFilename = nil
        file = nil
    }

    func testUpdateAndContainsDidChangeUANotPrivate() {
        let testMockData = ChangeUserAgentsMockData(
            urlString: "https://www.google.com",
            isChangedUA: true,
            isPrivate: false,
            expectContainsURL: true
        )
        let url = URL(string: testMockData.urlString)!

        Tab.ChangeUserAgent.updateDomainList(
            forUrl: url,
            isChangedUA: testMockData.isChangedUA,
            isPrivate: testMockData.isPrivate
        )
        XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url, isPrivate: testMockData.isPrivate),
                       testMockData.expectContainsURL)
    }

    func testUpdateAndContainsDidChangeUAAndPrivate() {
        let testMockData = ChangeUserAgentsMockData(
            urlString: "https://www.mozilla.org",
            isChangedUA: true,
            isPrivate: true,
            expectContainsURL: true
        )
        let url = URL(string: testMockData.urlString)!

        Tab.ChangeUserAgent.updateDomainList(
            forUrl: url,
            isChangedUA: testMockData.isChangedUA,
            isPrivate: testMockData.isPrivate
        )
        XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url, isPrivate: testMockData.isPrivate),
                       testMockData.expectContainsURL)
    }

    func testUpdateAndContainsNoChangeUANotPrivate() {
        let testMockData = ChangeUserAgentsMockData(
            urlString: "https://www.apple.com",
            isChangedUA: false,
            isPrivate: false,
            expectContainsURL: false
        )

        let url = URL(string: testMockData.urlString)!

        Tab.ChangeUserAgent.updateDomainList(
            forUrl: url,
            isChangedUA: testMockData.isChangedUA,
            isPrivate: testMockData.isPrivate
        )
        XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url, isPrivate: testMockData.isPrivate),
                       testMockData.expectContainsURL)
    }

    func testUpdateAndContainsNoChangeUAAndPrivate() {
        let testMockData = ChangeUserAgentsMockData(
            urlString: "https://www.yahoo.com",
            isChangedUA: false,
            isPrivate: true,
            expectContainsURL: false
        )
        let url = URL(string: testMockData.urlString)!

        Tab.ChangeUserAgent.updateDomainList(
            forUrl: url,
            isChangedUA: testMockData.isChangedUA,
            isPrivate: testMockData.isPrivate
        )
        XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url, isPrivate: testMockData.isPrivate),
                       testMockData.expectContainsURL)
    }

    func tryAllCasesForUpdateAndContains() {
        let testMockData1 = ChangeUserAgentsMockData(
            urlString: "https://www.google.com",
            isChangedUA: true,
            isPrivate: false,
            expectContainsURL: true
        )
        let testMockData2 = ChangeUserAgentsMockData(
            urlString: "https://www.mozilla.org",
            isChangedUA: true,
            isPrivate: true,
            expectContainsURL: true
        )
        let testMockData3 = ChangeUserAgentsMockData(
            urlString: "https://www.apple.com",
            isChangedUA: false,
            isPrivate: false,
            expectContainsURL: false
        )
        let testMockData4 = ChangeUserAgentsMockData(
            urlString: "https://www.yahoo.com",
            isChangedUA: false,
            isPrivate: true,
            expectContainsURL: false
        )
        let testCases = [testMockData1, testMockData2, testMockData3, testMockData4]
        for testCase in testCases {
            let url = URL(string: testCase.urlString)!
            Tab.ChangeUserAgent.updateDomainList(
                forUrl: url,
                isChangedUA: testCase.isChangedUA,
                isPrivate: testCase.isPrivate
            )
            XCTAssertEqual(Tab.ChangeUserAgent.contains(url: url, isPrivate: testCase.isPrivate), testCase.expectContainsURL)
        }
    }

    func testClear() {
        let url = URL(string: "https://www.google.com")!
        Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: true, isPrivate: false)
      XCTAssert(Tab.ChangeUserAgent.contains(url: url, isPrivate: false))

        Tab.ChangeUserAgent.clear()
        XCTAssertFalse(Tab.ChangeUserAgent.contains(url: url, isPrivate: false))
    }

    func testMigrationMovesFile() {
        migrationHelper()
        XCTAssert(FileManager.default.fileExists(atPath: file.path))
    }

    func testMigrationKeepsData() {
        migrationHelper()
        let data = try? Data(contentsOf: file)
        XCTAssert(data == Data("test".utf8))
    }

    private func migrationHelper() {
        // Write dummy data to a file at the old location
        let oldFile = {
            let root = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            return root.appendingPathComponent(testFilename)
        }()
        try? Data("test".utf8).write(to: oldFile)

        // Make sure the test file is not present at the new location to avoid errors
        try? FileManager.default.removeItem(at: file)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))

        Tab.ChangeUserAgent.performMigration()
    }

    // MARK: removeMobilePrefixFrom tests

    func testWithoutMobilePrefixRemovesMobilePrefixes() {
        let subject = Tab.ChangeUserAgent()
        let url = URL(string: "https://m.wikipedia.org/wiki/Firefox")!

        let newUrl = subject.removeMobilePrefixFrom(url: url)

        XCTAssertEqual(newUrl.host, "wikipedia.org")
    }

    func testWithoutMobilePrefixRemovesMobile() {
        let subject = Tab.ChangeUserAgent()
        let url = URL(string: "https://en.mobile.wikipedia.org/wiki/Firefox")!

        let newUrl = subject.removeMobilePrefixFrom(url: url)

        XCTAssertEqual(newUrl.host, "en.wikipedia.org")
    }

    func testWithoutMobilePrefixOnlyRemovesMobileSubdomains() {
        let subject = Tab.ChangeUserAgent()
        let url = URL(string: "https://plum.com")!

        let newUrl = subject.removeMobilePrefixFrom(url: url)

        XCTAssertEqual(newUrl.host, "plum.com")
    }

    func testWithMobilePrefixOnlyRemovesMobileSubdomainsIfNotStartingWithit() {
        let subject = Tab.ChangeUserAgent()
        let url = URL(string: "https://mobile.co.uk")!

        let newUrl = subject.removeMobilePrefixFrom(url: url)

        XCTAssertEqual(newUrl.host, "mobile.co.uk")
    }
}
