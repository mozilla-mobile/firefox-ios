// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared
import XCTest

@testable import Account
@testable import Client

class AutopushTests: XCTestCase {
    private var mockPushManager: MockPushManager!
    private var mockPrefs: MockProfilePrefs!
    private var autopushClient: Autopush!

    override func setUp() {
        super.setUp()
        mockPushManager = MockPushManager()
        mockPrefs = MockProfilePrefs()
        autopushClient = Autopush(withPushManager: mockPushManager)
    }

    override func tearDown() {
        autopushClient = nil
        mockPrefs = nil
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

    func testVerifyActiveSubscriptions_callsPushManager() async throws {
        XCTAssertFalse(mockPushManager.verifyConnectionCalled)
        try await autopushClient.verifyActiveSubscriptions(prefs: mockPrefs)
        XCTAssert(mockPushManager.verifyConnectionCalled)
    }

    func testVerifyActiveSubscriptions_withNoChanges_storesTimestamp() async throws {
        try await autopushClient.verifyActiveSubscriptions(prefs: mockPrefs)
        XCTAssertNotNil(mockPrefs.timestampForKey(PrefsKeys.AutopushVerificationTimestamp))
    }

    func testVerifyActiveSubscriptions_passesForceVerifyToPushManager() async throws {
        try await autopushClient.verifyActiveSubscriptions(forceVerify: true, prefs: mockPrefs)
        XCTAssertEqual(mockPushManager.verifyConnectionForceVerify, true)
    }

    func testShouldVerifySubscriptions_withNoPreviousVerification_returnsTrue() {
        XCTAssertTrue(Autopush.shouldVerifySubscriptions(prefs: mockPrefs))
    }

    func testShouldVerifySubscriptions_withRecentVerification_returnsFalse() {
        let now = Date.now()
        mockPrefs.setTimestamp(now - 1, forKey: PrefsKeys.AutopushVerificationTimestamp)
        XCTAssertFalse(Autopush.shouldVerifySubscriptions(prefs: mockPrefs, now: now))
    }

    func testShouldVerifySubscriptions_withExpiredVerification_returnsTrue() {
        let now = Date.now()
        let expired = now - UInt64(AppConstants.autopushVerificationInterval)
        mockPrefs.setTimestamp(expired, forKey: PrefsKeys.AutopushVerificationTimestamp)
        XCTAssertTrue(Autopush.shouldVerifySubscriptions(prefs: mockPrefs, now: now))
    }

    func testShouldVerifySubscriptions_withVerificationInTheFuture_returnsTrue() {
        let now = Date.now()
        mockPrefs.setTimestamp(now + 1, forKey: PrefsKeys.AutopushVerificationTimestamp)
        XCTAssertTrue(Autopush.shouldVerifySubscriptions(prefs: mockPrefs, now: now))
    }

    func testVerifyActiveSubscriptions_withChanges_resubscribesAndReturnsNewSubscriptions() async throws {
        mockPushManager.verifyConnectionResult = [PushSubscriptionChanged(channelId: "channel-id", scope: "scope")]

        let newSubscriptions = try await autopushClient.verifyActiveSubscriptions(prefs: mockPrefs)

        XCTAssertEqual(mockPushManager.subscribeCalledWith, "scope")
        XCTAssertEqual(newSubscriptions.keys.sorted(), ["scope"])
        XCTAssertEqual(newSubscriptions["scope"]?.subscriptionInfo.endpoint, "https://example.com")
    }

    func testVerifyActiveSubscriptions_whenPushManagerThrows_throwsAndDoesNotStoreTimestamp() async {
        mockPushManager.verifyConnectionError = PushApiError.UaidNotRecognizedError(message: "")

        do {
            try await autopushClient.verifyActiveSubscriptions(prefs: mockPrefs)
            XCTFail("Expected verifyActiveSubscriptions to throw")
        } catch {
            XCTAssertNil(mockPrefs.timestampForKey(PrefsKeys.AutopushVerificationTimestamp))
        }
    }
}

// MARK: - MockPushManager
final class MockPushManager: PushManagerProtocol, @unchecked Sendable {
    public var subscribeCalledWith: String?
    public var getSubscriptionCalledWith: String?
    public var unsubscribeCalledWith: String?
    public var unsubscribeAllCalled = false
    public var updateCalledWith: String?
    public var verifyConnectionCalled = false
    public var verifyConnectionForceVerify: Bool?
    public var verifyConnectionResult: [PushSubscriptionChanged] = []
    public var verifyConnectionError: Error?
    public var decryptCalledWith: [String: String]?

    func subscribe(scope: String, appServerSey: String?) throws -> MozillaAppServices.SubscriptionResponse {
        subscribeCalledWith = scope
        return SubscriptionResponse(
            channelId: "fake-channel-id",
            subscriptionInfo: SubscriptionInfo(
                endpoint: "https://example.com",
                keys: KeyInfo(auth: "fake-auth-string", p256dh: "fake-key")
            )
        )
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
        verifyConnectionForceVerify = forceVerify
        if let verifyConnectionError { throw verifyConnectionError }
        return verifyConnectionResult
    }

    func decrypt(payload: [String: String]) throws -> MozillaAppServices.DecryptResponse {
        decryptCalledWith = payload
        return DecryptResponse(result: [], scope: "fake-skope")
    }
}
