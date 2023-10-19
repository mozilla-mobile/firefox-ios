// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest
import MozillaAppServices
import Account

class AutopushTests: XCTestCase {
    private var mockPushManager: MockPushManager!
    private var autopushClient: Autopush!

    override func setUp() {
        super.setUp()
        mockPushManager = MockPushManager()
        autopushClient = Autopush(withPushManager: mockPushManager)
    }

    override func tearDown() {
        autopushClient = nil
        mockPushManager = nil
        super.tearDown()
    }

    func testSubscribeCallsPushManager() async throws {
        XCTAssertNil(mockPushManager.subscribeCalledWith)
        _ = try await autopushClient?.subscribe(scope: "scope")
        XCTAssertEqual("scope", mockPushManager.subscribeCalledWith)
    }

    func testUnsubscribeCallsPushManager() async throws {
        XCTAssertNil(mockPushManager.unsubscribeCalledWith)
        _ = try await autopushClient?.unsubscribe(scope: "scope")
        XCTAssertEqual("scope", mockPushManager.unsubscribeCalledWith)
    }

    func testUpdateCallsPushManager() async throws {
        XCTAssertNil(mockPushManager.updateCalledWith)
        // `updateToken` will get the hex values of the `Data` and pass
        // it to the native client
        let registrationToken = "123efa"
        _ = try await autopushClient?.updateToken(withDeviceToken: registrationToken.hexDecodedData)
        XCTAssertEqual(registrationToken, mockPushManager.updateCalledWith)
    }

    func testUnsubscribeAllCallsPushManager() async throws {
        XCTAssertFalse(mockPushManager.unsubscribeAllCalled)
        _ = try await autopushClient?.unsubscribeAll()
        XCTAssert(mockPushManager.unsubscribeAllCalled)
    }

    func testDecryptCallsPushManager() async throws {
        XCTAssertNil(mockPushManager.decryptCalledWith)
        _ = try await autopushClient?.decrypt(payload: ["key": "value"])
        XCTAssertEqual(["key": "value"], mockPushManager.decryptCalledWith)
    }
}

// MARK: - MockPushManager
class MockPushManager: PushManagerProtocol {
    public var subscribeCalledWith: String?
    public var getSubscriptionCalledWith: String?
    public var unsubscribeCalledWith: String?
    public var unsubscribeAllCalled = false
    public var updateCalledWith: String?
    public var verifyConnectionCalled = false
    public var decryptCalledWith: [String: String]?

    func subscribe(scope: String, appServerSey: String?) throws -> MozillaAppServices.SubscriptionResponse {
        subscribeCalledWith = scope
        return SubscriptionResponse(channelId: "fake-channel-id", subscriptionInfo: SubscriptionInfo(endpoint: "https://example.com", keys: KeyInfo(auth: "fake-auth-string", p256dh: "fake-key")))
    }

    func getSubscription(scope: String) throws -> MozillaAppServices.SubscriptionResponse? {
        getSubscriptionCalledWith = scope
        return nil
    }

    func unsubscribe(scope: String) throws -> Bool {
        unsubscribeCalledWith = scope
        return true
    }

    func unsubscribeAll() throws {
        unsubscribeAllCalled = true
    }

    func update(registrationToken: String) throws {
       updateCalledWith = registrationToken
    }

    func verifyConnection(forceVerify: Bool) throws -> [MozillaAppServices.PushSubscriptionChanged] {
        verifyConnectionCalled = true
        return []
    }

    func decrypt(payload: [String: String]) throws -> MozillaAppServices.DecryptResponse {
        decryptCalledWith = payload
        return DecryptResponse(result: [], scope: "fake-skope")
    }
}
