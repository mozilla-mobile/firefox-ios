// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Ecosia

#if os(iOS)

class SingularAdNetworkHelperTests: XCTestCase {
    let mockAppDeviceInfo = AppDeviceInfo(platform: "test",
                                          bundleId: "com.test",
                                          osVersion: "16.1",
                                          deviceManufacturer: "d",
                                          deviceModel: "e",
                                          locale: "f",
                                          appVersion: "0.0",
                                          installReceipt: "h")
    let mockAppDeviceInfoParameters = [
            "p": "test",
            "i": "com.test",
            "ve": "16.1",
            "app_v": "0.0",
    ]
    var objectPersister: MockObjectPersister!
    var timestampProvider: MockTimestampProvider!
    private var singularService: MockSingularService!
    var helper: SingularAdNetworkHelper!

    override func setUpWithError() throws {
        objectPersister = MockObjectPersister()
        timestampProvider = MockTimestampProvider(currentTimestamp: 1234567890)
        singularService = MockSingularService()
        helper = SingularAdNetworkHelper(skan: MockSkan.self,
                                         objectPersister: objectPersister,
                                         timestampProvider: timestampProvider,
                                         singularService: singularService)
        MockSkan.shouldThrowError = false
    }

    override func tearDownWithError() throws {
        objectPersister = nil
        timestampProvider = nil
        singularService = nil
        helper = nil
    }

    // MARK: Register for ad network
    func testRegisterForAdNetwork() async throws {
        try await helper.registerAppForAdNetworkAttribution()

        XCTAssertEqual(MockSkan.conversionValue, 0)
        XCTAssertEqual(objectPersister.getValueFor(.firstSkanCallTimestamp) as? Int, 1234567890)
        XCTAssertEqual(objectPersister.getValueFor(.lastSkanCallTimestamp) as? Int, 1234567890)
        XCTAssertEqual(objectPersister.getValueFor(.conversionValue) as? Int, 0)

        XCTAssertNil(objectPersister.getValueFor(.previousFineValue))
        XCTAssertNil(objectPersister.getValueFor(.coarseValue(window: .first)))
        XCTAssertNil(objectPersister.getValueFor(.previousCoarseValue(window: .first)))
        XCTAssertNil(objectPersister.getValueFor(.windowLockTimestamp(window: .first)))
    }

    func testDoesNotRegisterForAdNetworkGivenAleradyDonePreviously() async throws {
        objectPersister.setValueFor(.firstSkanCallTimestamp, value: 1)
        XCTAssertNil(MockSkan.conversionValue)
        XCTAssertNil(objectPersister.getValueFor(.lastSkanCallTimestamp))
        XCTAssertNil(objectPersister.getValueFor(.conversionValue))

        try await helper.registerAppForAdNetworkAttribution()

        XCTAssertNil(MockSkan.conversionValue)
        XCTAssertNil(objectPersister.getValueFor(.lastSkanCallTimestamp))
        XCTAssertNil(objectPersister.getValueFor(.conversionValue))
        XCTAssertNil(objectPersister.getValueFor(.previousFineValue))
        XCTAssertNil(objectPersister.getValueFor(.coarseValue(window: .first)))
        XCTAssertNil(objectPersister.getValueFor(.previousCoarseValue(window: .first)))
        XCTAssertNil(objectPersister.getValueFor(.windowLockTimestamp(window: .first)))
    }

    func testRegisterForAdNetworkHandlesError() async throws {
        MockSkan.shouldThrowError = true

        try await helper.registerAppForAdNetworkAttribution()

        XCTAssertEqual(objectPersister.getValueFor(.errorCode) as? Int, 1234)
    }

    // MARK: Get persisted values
    func testGetPersistedValuesDictionary() {
        objectPersister.setValueFor(.firstSkanCallTimestamp, value: 123)
        objectPersister.setValueFor(.lastSkanCallTimestamp, value: 456)
        objectPersister.setValueFor(.conversionValue, value: 2)
        objectPersister.setValueFor(.coarseValue(window: .first), value: 3)
        objectPersister.setValueFor(.coarseValue(window: .second), value: 4)
        objectPersister.setValueFor(.coarseValue(window: .third), value: 5)
        objectPersister.setValueFor(.previousFineValue, value: 6)
        objectPersister.setValueFor(.previousCoarseValue(window: .first), value: 7)
        objectPersister.setValueFor(.previousCoarseValue(window: .second), value: 8)
        objectPersister.setValueFor(.previousCoarseValue(window: .third), value: 9)
        objectPersister.setValueFor(.windowLockTimestamp(window: .first), value: 10)
        objectPersister.setValueFor(.windowLockTimestamp(window: .second), value: 11)
        objectPersister.setValueFor(.windowLockTimestamp(window: .third), value: 12)
        objectPersister.setValueFor(.errorCode, value: 1234)

        let dictionary = helper.persistedValuesDictionary

        XCTAssertEqual(dictionary["skan_first_call_to_skadnetwork_timestamp"], "123")
        XCTAssertEqual(dictionary["skan_last_call_to_skadnetwork_timestamp"], "456")
        XCTAssertEqual(dictionary["skan_current_conversion_value"], "2")
        XCTAssertEqual(dictionary["p0_coarse"], "3")
        XCTAssertEqual(dictionary["p1_coarse"], "4")
        XCTAssertEqual(dictionary["p2_coarse"], "5")
        XCTAssertEqual(dictionary["prev_fine_value"], "6")
        XCTAssertEqual(dictionary["p0_prev_coarse_value"], "7")
        XCTAssertEqual(dictionary["p1_prev_coarse_value"], "8")
        XCTAssertEqual(dictionary["p2_prev_coarse_value"], "9")
        XCTAssertEqual(dictionary["p0_window_lock"], "10")
        XCTAssertEqual(dictionary["p1_window_lock"], "11")
        XCTAssertEqual(dictionary["p2_window_lock"], "12")
        XCTAssertEqual(dictionary["_skerror"], "1234")
    }

    // MARK: Fetch and update from server
    func testUpdateFetchedConversionValuesFromServerOnFirstWindow() async throws {
        objectPersister.setValueFor(.firstSkanCallTimestamp, value: 1234567880)
        objectPersister.setValueFor(.lastSkanCallTimestamp, value: 123)
        objectPersister.setValueFor(.conversionValue, value: 2)
        objectPersister.setValueFor(.coarseValue(window: .first), value: 3)
        objectPersister.setValueFor(.previousFineValue, value: 6)
        objectPersister.setValueFor(.previousCoarseValue(window: .first), value: 7)
        objectPersister.setValueFor(.windowLockTimestamp(window: .first), value: 10)
        singularService.responseStub = SingularConversionValueResponse(conversionValue: 50,
                                                                       coarseValue: nil,
                                                                       lockWindow: true)

        try await helper.fetchFromSingularServerAndUpdate(sessionIdentifier: "123", appDeviceInfo: mockAppDeviceInfo)

        XCTAssertEqual(singularService.receivedParameters, [
            "n": "__SESSION__",
            "sing": "123",
            "p0_coarse": "3",
            "p0_prev_coarse_value": "7",
            "p0_window_lock": "10",
            "prev_fine_value": "6",
            "skan_current_conversion_value": "2",
            "skan_first_call_to_skadnetwork_timestamp": "1234567880",
            "skan_last_call_to_skadnetwork_timestamp": "123",
        ].merging(mockAppDeviceInfoParameters) { (current, _) in current })
        XCTAssertEqual(MockSkan.conversionValue, 50)
        XCTAssertNil(MockSkan.coarseValue)
        XCTAssertEqual(MockSkan.lockWindow, true)
        XCTAssertEqual(objectPersister.getValueFor(.conversionValue) as? Int, 50)
        XCTAssertEqual(objectPersister.getValueFor(.previousFineValue) as? Int, 2)
        XCTAssertNil(objectPersister.getValueFor(.coarseValue(window: .first)))
        XCTAssertEqual(objectPersister.getValueFor(.previousCoarseValue(window: .first)) as? Int, 3)
        XCTAssertEqual(objectPersister.getValueFor(.windowLockTimestamp(window: .first)) as? Int, 1234567890)
    }

    func testUpdateFetchedConversionValuesFromServerOnSecondWindow() async throws {
        objectPersister.setValueFor(.firstSkanCallTimestamp, value: 1234387890)
        objectPersister.setValueFor(.lastSkanCallTimestamp, value: 456)
        objectPersister.setValueFor(.conversionValue, value: 7)
        objectPersister.setValueFor(.coarseValue(window: .second), value: 5)
        objectPersister.setValueFor(.previousCoarseValue(window: .second), value: 8)
        objectPersister.setValueFor(.windowLockTimestamp(window: .second), value: 15)
        singularService.responseStub = SingularConversionValueResponse(conversionValue: 30,
                                                                       coarseValue: 2,
                                                                       lockWindow: nil)

        try await helper.fetchFromSingularServerAndUpdate(sessionIdentifier: "123", appDeviceInfo: mockAppDeviceInfo)

        XCTAssertEqual(singularService.receivedParameters, [
            "n": "__SESSION__",
            "sing": "123",
            "p1_coarse": "5",
            "p1_prev_coarse_value": "8",
            "p1_window_lock": "15",
            "skan_current_conversion_value": "7",
            "skan_first_call_to_skadnetwork_timestamp": "1234387890",
            "skan_last_call_to_skadnetwork_timestamp": "456",
        ].merging(mockAppDeviceInfoParameters) { (current, _) in current })
        XCTAssertEqual(MockSkan.conversionValue, 30)
        XCTAssertEqual(MockSkan.coarseValue, 2)
        XCTAssertEqual(MockSkan.lockWindow, false)
        XCTAssertEqual(objectPersister.getValueFor(.coarseValue(window: .second)) as? Int, 2)
        XCTAssertEqual(objectPersister.getValueFor(.previousCoarseValue(window: .second)) as? Int, 5)
        XCTAssertEqual(objectPersister.getValueFor(.windowLockTimestamp(window: .second)) as? Int, 15)
    }

    func testUpdateFetchedConversionValuesFromServerOnThirdWindow() async throws {
        objectPersister.setValueFor(.firstSkanCallTimestamp, value: 1233567890)
        objectPersister.setValueFor(.lastSkanCallTimestamp, value: 789)
        objectPersister.setValueFor(.conversionValue, value: 11)
        objectPersister.setValueFor(.coarseValue(window: .third), value: 20)
        objectPersister.setValueFor(.previousCoarseValue(window: .third), value: 23)
        objectPersister.setValueFor(.windowLockTimestamp(window: .third), value: 25)
        singularService.responseStub = SingularConversionValueResponse(conversionValue: 44,
                                                                       coarseValue: 0,
                                                                       lockWindow: false)

        try await helper.fetchFromSingularServerAndUpdate(sessionIdentifier: "123", appDeviceInfo: mockAppDeviceInfo)

        XCTAssertEqual(singularService.receivedParameters, [
            "n": "__SESSION__",
            "sing": "123",
            "p2_coarse": "20",
            "p2_prev_coarse_value": "23",
            "p2_window_lock": "25",
            "skan_current_conversion_value": "11",
            "skan_first_call_to_skadnetwork_timestamp": "1233567890",
            "skan_last_call_to_skadnetwork_timestamp": "789",
        ].merging(mockAppDeviceInfoParameters) { (current, _) in current })
        XCTAssertEqual(MockSkan.conversionValue, 44)
        XCTAssertEqual(MockSkan.coarseValue, 0)
        XCTAssertEqual(MockSkan.lockWindow, false)
        XCTAssertEqual(objectPersister.getValueFor(.coarseValue(window: .third)) as? Int, 0)
        XCTAssertEqual(objectPersister.getValueFor(.previousCoarseValue(window: .third)) as? Int, 20)
        XCTAssertEqual(objectPersister.getValueFor(.windowLockTimestamp(window: .third)) as? Int, 25)
    }

    func testDoesNotFetchConversionValuesFromServerOnOverWindow() async throws {
        objectPersister.setValueFor(.firstSkanCallTimestamp, value: 1231542890)

        try await helper.fetchFromSingularServerAndUpdate(sessionIdentifier: "123", appDeviceInfo: mockAppDeviceInfo)

        XCTAssertNil(singularService.receivedParameters)
        XCTAssertNil(MockSkan.conversionValue)
        XCTAssertNil(MockSkan.coarseValue)
    }

    func testErrorWhenInvalidFetchedConversionValue() async throws {
        objectPersister.setValueFor(.firstSkanCallTimestamp, value: 1234567880)
        singularService.responseStub = SingularConversionValueResponse(conversionValue: 64,
                                                                       coarseValue: 1,
                                                                       lockWindow: false)

        do {
            try await helper.fetchFromSingularServerAndUpdate(sessionIdentifier: "123", appDeviceInfo: mockAppDeviceInfo)
            XCTFail("Did not throw error when it should")
        } catch SingularAdNetworkHelper.Error.invalidConversionValues {
            // expected
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }

    func testErrorWhenInvalidFetchedCoarseValue() async throws {
        objectPersister.setValueFor(.firstSkanCallTimestamp, value: 1234567880)
        singularService.responseStub = SingularConversionValueResponse(conversionValue: 1,
                                                                       coarseValue: 3,
                                                                       lockWindow: false)

        do {
            try await helper.fetchFromSingularServerAndUpdate(sessionIdentifier: "123", appDeviceInfo: mockAppDeviceInfo)
            XCTFail("Did not throw error when it should")
        } catch SingularAdNetworkHelper.Error.invalidConversionValues {
            // expected
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }
}

// MARK: SKAdNetwork Mock
class MockSkan: SKAdNetworkProtocol {

    static var conversionValue: Int?
    static var coarseValue: Int?
    static var lockWindow: Bool?
    static var shouldThrowError = false

    static func updatePostbackConversionValue(_ conversionValue: Int) async throws {
        guard !shouldThrowError else {
            throw NSError(domain: "MockSkanError", code: 1234, userInfo: nil)
        }
        self.conversionValue = conversionValue
    }

    static func updatePostbackConversionValue(_ fineValue: Int, coarseValue: Int?, lockWindow: Bool) async throws {
        self.conversionValue = fineValue
        self.coarseValue = coarseValue
        self.lockWindow = lockWindow
    }

    // Should never call this method on the latest iOS version
    static func registerAppForAdNetworkAttribution() {}

    // Should never call this method on the latest iOS version
    static func updateConversionValue(_ conversionValue: Int) {}
}

// MARK: ObjectPersister Mock
class MockObjectPersister: ObjectPersister {

    var values = [String: Any]()
    func setValueFor(_ object: SingularAdNetworkHelper.PersistedObject, value: Any) {
        values[object.key] = value
    }
    func getValueFor(_ object: SingularAdNetworkHelper.PersistedObject) -> Any? {
        return values[object.key]
    }

    func set(_ value: Any?, forKey key: String) {
        values[key] = value
    }

    func object(forKey key: String) -> Any? {
        return values[key]
    }
}

// MARK: SingularService Mock
private class MockSingularService: SingularServiceProtocol {
    var responseStub: SingularConversionValueResponse?

    var receivedParameters: [String: String]?
    func getConversionValue(request: SingularConversionValueRequest) async throws -> SingularConversionValueResponse {
        receivedParameters = request.queryParameters
        return responseStub!
    }

    func sendNotification(request: SingularNotificationRequest) async throws {
        throw NSError(domain: "SingularAdNetworkHelperTests",
                      code: 0,
                      userInfo: [NSLocalizedDescriptionKey: "Should never get called in this context"])
    }
}

#endif
