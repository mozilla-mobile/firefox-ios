// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

#if os(iOS)

class SingularTests: XCTestCase {

    private var singularService: MockSingularService!
    private var skanHelper: MockSingularAdNetworkHelper!
    var singular: Singular!

    override func setUpWithError() throws {
        singularService = MockSingularService()
        skanHelper = MockSingularAdNetworkHelper()
        singular = Singular(singularService: singularService, skanHelper: skanHelper)
    }

    override func tearDownWithError() throws {
        singularService = nil
        skanHelper = nil
        singular = nil
    }

    // MARK: Public init
    func testPublicInitIncludingSKAN() {
        // when
        singular = Singular(includeSKAN: true)

        // then
        XCTAssertNotNil(singular.skanHelper)
    }

    func testPublicInitWithoutSKAN() {
        // when
        singular = Singular(includeSKAN: false)

        // then
        XCTAssertNil(singular.skanHelper)
    }

    // MARK: Send session info
    func testShouldSendSessionInfoWithSKAN() async throws {
        // given
        skanHelper.persistedValuesDictionary = MockSessionParameters.mockPersistedSkanValues

        // when
        try await singular.sendSessionInfo(appDeviceInfo: MockSessionParameters.mockAppDeviceInfo)

        // then
        XCTAssertFalse(skanHelper.registerAppForAdNetworkAttributionCalled)
        XCTAssertEqual(skanHelper.fetchFromSingularServerAndUpdateEvent, .session)
        XCTAssertNotNil(skanHelper.fetchFromSingularServerAndUpdateIdentifier)
        XCTAssertEqual(skanHelper.fetchFromSingularServerAndUpdateAppDeviceInfo, MockSessionParameters.mockAppDeviceInfo)
        XCTAssert(singularService.sendNotificationReceivedRequest is SingularSessionInfoSendRequest)
        MockSessionParameters.assertReceivedParametersEqualToExpected(singularService.sendNotificationReceivedParameters)
    }

    func testFirstSessionInfoWithSKAN() async throws {
        // given
        skanHelper.isRegistered = false
        skanHelper.persistedValuesDictionary = MockSessionParameters.mockPersistedSkanValues

        // when
        try await singular.sendSessionInfo(appDeviceInfo: MockSessionParameters.mockAppDeviceInfo)

        // then
        XCTAssertTrue(skanHelper.registerAppForAdNetworkAttributionCalled)
        XCTAssertNil(skanHelper.fetchFromSingularServerAndUpdateEvent)
        XCTAssertNil(skanHelper.fetchFromSingularServerAndUpdateIdentifier)
        XCTAssertNil(skanHelper.fetchFromSingularServerAndUpdateAppDeviceInfo)
        XCTAssert(singularService.sendNotificationReceivedRequest is SingularSessionInfoSendRequest)
        MockSessionParameters.assertReceivedParametersEqualToExpected(singularService.sendNotificationReceivedParameters)
    }

    func testShouldSendSessionInfoWithoutSKAN() async throws {
        // given
        singular = Singular(singularService: singularService, skanHelper: nil)

        // when
        try await singular.sendSessionInfo(appDeviceInfo: MockSessionParameters.mockAppDeviceInfo)

        // then
        XCTAssertFalse(skanHelper.registerAppForAdNetworkAttributionCalled)
        XCTAssertNil(skanHelper.fetchFromSingularServerAndUpdateEvent)
        XCTAssertNil(skanHelper.fetchFromSingularServerAndUpdateIdentifier)
        XCTAssertNil(skanHelper.fetchFromSingularServerAndUpdateAppDeviceInfo)
        XCTAssert(singularService.sendNotificationReceivedRequest is SingularSessionInfoSendRequest)
        MockSessionParameters.assertReceivedParametersEqualToExpected(singularService.sendNotificationReceivedParameters, includeSkan: false)
    }

    func testShouldThrowSendSessionInfoError() async throws {
        // given
        let expectedError = NSError(domain: "test", code: 0)
        singularService.sendNotificationError = expectedError

        // when
        do {
            try await singular.sendSessionInfo(appDeviceInfo: MockSessionParameters.mockAppDeviceInfo)
            XCTFail("Did not throw expected error")
        } catch {
            // then
            XCTAssertEqual(error as NSError, expectedError)
        }
    }

    // MARK: Handle SKAN errors
    func testShouldNotThrowSKANRegisterError() async throws {
        // given
        skanHelper.isRegistered = false
        skanHelper.persistedValuesDictionary = MockSessionParameters.mockPersistedSkanValues
        skanHelper.registerAppForAdNetworkAttributionError = NSError(domain: "test", code: 0)

        // when
        do {
            try await singular.sendSessionInfo(appDeviceInfo: MockSessionParameters.mockAppDeviceInfo)
        } catch {
            XCTFail("No error expected, but received \(error)")
        }

        // then
        MockSessionParameters.assertReceivedParametersEqualToExpected(singularService.sendNotificationReceivedParameters)
    }

    func testShouldNotThrowSKANServerError() async throws {
        // given
        skanHelper.persistedValuesDictionary = MockSessionParameters.mockPersistedSkanValues
        skanHelper.fetchFromSingularServerAndUpdateError = NSError(domain: "test", code: 0)

        // when
        do {
            try await singular.sendSessionInfo(appDeviceInfo: MockSessionParameters.mockAppDeviceInfo)
        } catch {
            XCTFail("No error expected, but received \(error)")
        }

        // then
        MockSessionParameters.assertReceivedParametersEqualToExpected(singularService.sendNotificationReceivedParameters)
    }

    // MARK: Send event
    func testShouldSendEvent() async throws {
        // given
        let expectedEvent = MMPEvent.firstSearch

        // when
        try await singular.sendEvent(expectedEvent, appDeviceInfo: MockSessionParameters.mockAppDeviceInfo)

        // then
        XCTAssert(singularService.sendNotificationReceivedRequest is SingularEventRequest)
        MockSessionParameters.assertReceivedParametersEqualToExpected(singularService.sendNotificationReceivedParameters, includeSkan: false, event: expectedEvent.rawValue)
    }

    func testShouldThrowSendEventError() async throws {
        // given
        let expectedError = NSError(domain: "test", code: 0)
        singularService.sendNotificationError = expectedError

        // when
        do {
            try await singular.sendEvent(MMPEvent.firstSearch, appDeviceInfo: MockSessionParameters.mockAppDeviceInfo)
            XCTFail("Did not throw expected error")
        } catch {
            // then
            XCTAssertEqual(error as NSError, expectedError)
        }
    }
}

// MARK: SingularService Mock
private class MockSingularService: SingularServiceProtocol {
    var responseStub: SingularConversionValueResponse?

    func getConversionValue(request: SingularConversionValueRequest) async throws -> SingularConversionValueResponse {
        throw NSError(domain: "SingularTests",
                      code: 0,
                      userInfo: [NSLocalizedDescriptionKey: "Should never call this method directly in this context"])
    }

    var sendNotificationError: Error?
    var sendNotificationReceivedRequest: SingularNotificationRequest?
    var sendNotificationReceivedParameters: [String: String]?
    func sendNotification(request: SingularNotificationRequest) async throws {
        if let error = sendNotificationError {
            throw error
        }
        sendNotificationReceivedRequest = request
        sendNotificationReceivedParameters = request.queryParameters
    }
}

// MARK: SingularAdNetworkHelper Mock
class MockSingularAdNetworkHelper: SingularAdNetworkHelperProtocol {
    var persistedValuesDictionary: [String: String] = [:]
    var isRegistered: Bool = true

    var registerAppForAdNetworkAttributionError: Error?
    var registerAppForAdNetworkAttributionCalled = false
    func registerAppForAdNetworkAttribution() async throws {
        if let error = registerAppForAdNetworkAttributionError {
            throw error
        }
        registerAppForAdNetworkAttributionCalled = true
    }

    var fetchFromSingularServerAndUpdateError: Error?
    var fetchFromSingularServerAndUpdateEvent: SingularEvent?
    var fetchFromSingularServerAndUpdateIdentifier: String?
    var fetchFromSingularServerAndUpdateAppDeviceInfo: AppDeviceInfo?
    func fetchFromSingularServerAndUpdate(forEvent event: SingularEvent, sessionIdentifier: String, appDeviceInfo: AppDeviceInfo) async throws {
        if let error = fetchFromSingularServerAndUpdateError {
            throw error
        }
        fetchFromSingularServerAndUpdateEvent = event
        fetchFromSingularServerAndUpdateIdentifier = sessionIdentifier
        fetchFromSingularServerAndUpdateAppDeviceInfo = appDeviceInfo
    }
}

// MARK: Parameters Mock
enum MockSessionParameters {
    static let mockAppDeviceInfo = AppDeviceInfo(platform: "a",
                                                 bundleId: "b",
                                                 osVersion: "c",
                                                 deviceManufacturer: "d",
                                                 deviceModel: "e",
                                                 locale: "f",
                                                 country: "g",
                                                 appVersion: "h",
                                                 installReceipt: "i",
                                                 adServicesAttributionToken: "j")
    private static let mockExpectedDeviceInfoParameters = [
        "p": "a",
        "i": "b",
        "ve": "c",
        "ma": "d",
        "mo": "e",
        "lc": "f",
        "country": "g",
        "app_v": "h",
        "install_receipt": "i",
        "attribution_token": "j"
    ]
    private static let mockExpectedReducedDeviceInfoParameters = [
        "p": "a",
        "i": "b",
        "ve": "c"
    ]
    static let mockPersistedSkanValues = [
        SingularAdNetworkHelper.PersistedObject.conversionValue.queryKey: "test",
        SingularAdNetworkHelper.PersistedObject.firstSkanCallTimestamp.queryKey: "abc",
        SingularAdNetworkHelper.PersistedObject.lastSkanCallTimestamp.queryKey: "def",
        SingularAdNetworkHelper.PersistedObject.coarseValue(window: .first).queryKey: "ghi",
        SingularAdNetworkHelper.PersistedObject.coarseValue(window: .second).queryKey: "jkl",
        SingularAdNetworkHelper.PersistedObject.coarseValue(window: .third).queryKey: "mno",
        SingularAdNetworkHelper.PersistedObject.previousFineValue.queryKey: "pqr",
        SingularAdNetworkHelper.PersistedObject.previousCoarseValue(window: .first).queryKey: "stu",
        SingularAdNetworkHelper.PersistedObject.previousCoarseValue(window: .second).queryKey: "vxw",
        SingularAdNetworkHelper.PersistedObject.previousCoarseValue(window: .third).queryKey: "yza",
        SingularAdNetworkHelper.PersistedObject.windowLockTimestamp(window: .first).queryKey: "bcd",
        SingularAdNetworkHelper.PersistedObject.windowLockTimestamp(window: .second).queryKey: "efg",
        SingularAdNetworkHelper.PersistedObject.windowLockTimestamp(window: .third).queryKey: "hij"
    ]
    private static let mockExpectedSkanParameters = [
        "skan_current_conversion_value": "test",
        "skan_first_call_to_skadnetwork_timestamp": "abc",
        "skan_last_call_to_skadnetwork_timestamp": "def",
        "p0_coarse": "ghi",
        "p1_coarse": "jkl",
        "p2_coarse": "mno",
        "prev_fine_value": "pqr",
        "p0_prev_coarse_value": "stu",
        "p1_prev_coarse_value": "vxw",
        "p2_prev_coarse_value": "yza",
        "p0_window_lock": "bcd",
        "p1_window_lock": "efg",
        "p2_window_lock": "hij"
    ]

    static func assertReceivedParametersEqualToExpected(_ receivedParameters: [String: String]?, includeSkan: Bool = true, event: String? = nil) {
        var parameters = receivedParameters

        // Assert and remove id since it is randomly generated
        XCTAssertNotNil(parameters?.removeValue(forKey: "sing"))

        let isEvent = (event != nil)
        let deviceInfo = isEvent ? mockExpectedReducedDeviceInfoParameters : mockExpectedDeviceInfoParameters
        let expectedParameters = deviceInfo
            .merging(includeSkan ? mockExpectedSkanParameters : [:]) { (current, _) in current }
            .merging(isEvent ? ["n": event!] : [:]) { (current, _) in current }

        XCTAssertEqual(parameters, expectedParameters)
    }
}

#endif
