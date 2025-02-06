// swiftlint:disable force_try
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

final class ReferralsTests: XCTestCase {

    var httpClientMock: HTTPClientMock!
    var referrals: Referrals!
    let mockURL = URL(string: "https://www.example.com")!
    let okResponse = HTTPURLResponse(url: URL(string: "https://example.com")!, statusCode: 200, httpVersion: nil, headerFields: nil)
    let createdResponse = HTTPURLResponse(url: URL(string: "https://www.example.com")!, statusCode: 201, httpVersion: nil, headerFields: nil)
    let failureResponse = HTTPURLResponse(url: URL(string: "https://www.example.com")!, statusCode: 500, httpVersion: nil, headerFields: nil)
    let notFoundResponse = HTTPURLResponse(url: URL(string: "https://www.example.com")!, statusCode: 404, httpVersion: nil, headerFields: nil)

    override func setUp() {
        try? FileManager.default.removeItem(at: FileManager.user)

        httpClientMock = HTTPClientMock()
        httpClientMock.data = try! Data(contentsOf: Bundle.ecosiaTests.url(forResource: "referrals", withExtension: "json")!)
        httpClientMock.response = failureResponse

        // Force clean state
        var user = User()
        user.referrals = .init()
        User.shared = user

        referrals = Referrals(client: httpClientMock)
    }

    func testFetchCodeNotCreated() async throws {
        XCTAssertNil(User.shared.referrals.code)
        httpClientMock.response = okResponse

        try await referrals.refresh(createCode: false)

        XCTAssertNil(User.shared.referrals.code)
    }

    func testFetchCodeCreate() async throws {
        XCTAssertNil(User.shared.referrals.code)
        httpClientMock.response = okResponse

        let expect = expectation(description: "")
        referrals.subscribe(self) { model in
            self.referrals.unsubscribe(self)
            XCTAssertEqual(model.code, "MANGO-2UGicG")
            XCTAssertEqual(User.shared.referrals.code, "MANGO-2UGicG")
            XCTAssertEqual(model.claims, 1)
            expect.fulfill()
        }
        try await referrals.refresh(createCode: true)
        await fulfillment(of: [expect], timeout: 1)
    }

    func testFetchCodeWithCodeInPlace() async throws {
        User.shared.referrals.code = "Avocado"

        let codeInfo = try await referrals.fetchCode()

        XCTAssertEqual(codeInfo.code, "Avocado")
    }

    func testRefreshHandlesNotFound() async throws {
        User.shared.referrals.code = "MANGO-2UGicG"
        XCTAssertEqual(User.shared.referrals.claims, 0)
        httpClientMock.response = notFoundResponse
        httpClientMock.executeBeforeResponse = {
            XCTAssertEqual(self.httpClientMock.response, self.notFoundResponse)
        }
        try await referrals.refresh()
    }

    func testRefreshHandlesNotFound_CreatesNewCode() async throws {
        User.shared.referrals.code = "MANGO-2UGicG"
        XCTAssertEqual(User.shared.referrals.claims, 0)
        httpClientMock.response = notFoundResponse
        httpClientMock.data = """
        {
            "code": "NEW-CODE",
            "claims": 0
        }
        """.data(using: .utf8)!
        try await referrals.refresh()
        XCTAssertEqual(User.shared.referrals.code, "NEW-CODE")
        XCTAssertEqual(User.shared.referrals.claims, 0)
    }

    func testRefresh() async throws {
        User.shared.referrals.code = "MANGO-2UGicG"
        XCTAssertEqual(User.shared.referrals.claims, 0)
        httpClientMock.response = okResponse

        let expect = expectation(description: "")
        referrals.subscribe(self) { model in
            self.referrals.unsubscribe(self)
            XCTAssertEqual(model.code, User.shared.referrals.code)
            XCTAssertEqual(User.shared.referrals.claims, 1)
            expect.fulfill()
        }
        try await referrals.refresh()
        await fulfillment(of: [expect], timeout: 1)
    }

    func testClaim() async throws {
        User.shared.referrals.code = "MANGO-2UGicG"
        XCTAssertFalse(User.shared.referrals.isClaimed)
        XCTAssertFalse(User.shared.referrals.isNewClaim)
        httpClientMock.response = createdResponse

        try await referrals.claim(referrer: "MANGO-1XrUBl")

        XCTAssertTrue(User.shared.referrals.isClaimed)
        XCTAssertTrue(User.shared.referrals.isNewClaim)
    }

    func testFetchCodeBeforeClaim() async throws {
        XCTAssertNil(User.shared.referrals.code)
        httpClientMock.response = createdResponse

        try await referrals.claim(referrer: "MANGO-1XrUBl")

        XCTAssertEqual(User.shared.referrals.code, "MANGO-2UGicG")
        XCTAssertTrue(User.shared.referrals.isClaimed)
        XCTAssertTrue(User.shared.referrals.isNewClaim)
    }

    func testCooldown() async throws {
        let lastUpdate = User.shared.referrals.updated
        httpClientMock.response = okResponse

        try await referrals.refresh(createCode: true)
        let recentUpdate = User.shared.referrals.updated
        XCTAssert(recentUpdate > lastUpdate)

        // run into cooldown
        try await self.referrals.refresh(force: false)
        XCTAssert(User.shared.referrals.updated == recentUpdate)

        // update with force
        try await self.referrals.refresh(force: true)
        XCTAssert(User.shared.referrals.updated > recentUpdate)
    }

    func testRefreshCooldownOnError() async throws {
        User.shared.referrals.code = "MANGO-2UGicG"
        httpClientMock.response = failureResponse
        let lastUpdate = User.shared.referrals.updated

        try? await referrals.refresh(force: false)

        XCTAssert(User.shared.referrals.updated > lastUpdate)
    }

    func testIsRefreshingTrueWhileRefreshing() async throws {
        User.shared.referrals.code = "MANGO-2UGicG"
        XCTAssertEqual(User.shared.referrals.claims, 0)
        httpClientMock.response = okResponse
        referrals.isRefreshing = false

        httpClientMock.executeBeforeResponse = {
            XCTAssertTrue(self.referrals.isRefreshing)
        }
        try await referrals.refresh()

        XCTAssertFalse(referrals.isRefreshing)
    }

    func testRefreshCodeIsNotCalledWhenRefreshing() async throws {
        User.shared.referrals.code = "MANGO-2UGicG"
        XCTAssertEqual(User.shared.referrals.claims, 0)
        // Set failure so that it throws if unwanted request is made
        httpClientMock.response = failureResponse

        referrals.isRefreshing = true
        try await referrals.refresh()
    }
}
// swiftlint:enable force_try
