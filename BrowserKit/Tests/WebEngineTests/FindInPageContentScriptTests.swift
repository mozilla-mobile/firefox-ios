// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine

final class FindInPageContentScriptTests: XCTestCase {
    private var findInPageDelegate: MockFindInPageHelperDelegate!

    override func setUp() {
        super.setUp()
        findInPageDelegate = MockFindInPageHelperDelegate()
    }

    override func tearDown() {
        super.tearDown()
        findInPageDelegate = nil
    }

    func testDidReceiveMessageGivenEmptyMessageThenNoDelegateCalled() {
        let subject = FindInPageContentScript()
        subject.delegate = findInPageDelegate

        subject.userContentController(didReceiveMessage: [])

        XCTAssertEqual(findInPageDelegate.didUpdateCurrentResultCalled, 0)
        XCTAssertEqual(findInPageDelegate.didUpdateTotalResultsCalled, 0)
    }

    func testDidReceiveMessageGivenStringMessageThenNoDelegateCalled() {
        let subject = FindInPageContentScript()
        subject.delegate = findInPageDelegate

        subject.userContentController(didReceiveMessage: ["": ""])

        XCTAssertEqual(findInPageDelegate.didUpdateCurrentResultCalled, 0)
        XCTAssertEqual(findInPageDelegate.didUpdateTotalResultsCalled, 0)
    }

    func testDidReceiveMessageGivenCurrentResultMessageThenDelegateCalled() {
        let subject = FindInPageContentScript()
        subject.delegate = findInPageDelegate
        let currentResult = 1

        subject.userContentController(didReceiveMessage: ["currentResult": currentResult])

        XCTAssertEqual(findInPageDelegate.didUpdateCurrentResultCalled, 1)
        XCTAssertEqual(findInPageDelegate.savedCurrentResult, currentResult)
        XCTAssertEqual(findInPageDelegate.didUpdateTotalResultsCalled, 0)
    }

    func testDidReceiveMessageGivenTotalResultMessageThenDelegateCalled() {
        let subject = FindInPageContentScript()
        subject.delegate = findInPageDelegate
        let totalResult = 10

        subject.userContentController(didReceiveMessage: ["totalResults": totalResult])

        XCTAssertEqual(findInPageDelegate.didUpdateCurrentResultCalled, 0)
        XCTAssertEqual(findInPageDelegate.didUpdateTotalResultsCalled, 1)
        XCTAssertEqual(findInPageDelegate.savedTotalResults, totalResult)
    }

    func testDidReceiveMessageGivenTotalAndCurrentResultsMessageThenDelegateCalled() {
        let subject = FindInPageContentScript()
        subject.delegate = findInPageDelegate
        let totalResult = 15
        let currentResult = 20

        subject.userContentController(didReceiveMessage: ["totalResults": totalResult, "currentResult": currentResult])

        XCTAssertEqual(findInPageDelegate.didUpdateCurrentResultCalled, 1)
        XCTAssertEqual(findInPageDelegate.savedCurrentResult, currentResult)
        XCTAssertEqual(findInPageDelegate.didUpdateTotalResultsCalled, 1)
        XCTAssertEqual(findInPageDelegate.savedTotalResults, totalResult)
    }
}
