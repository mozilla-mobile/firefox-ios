// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

#if os(iOS)

class SingularServiceTests: XCTestCase {

    var httpClientMock: HTTPClientMock!
    let failureResponseMock = HTTPURLResponse(
        url: URL(string: "https://www.example.com")!,
        statusCode: 404,
        httpVersion: nil,
        headerFields: nil
    )
    let successResponseMock = HTTPURLResponse(
        url: URL(string: "https://www.example.com")!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    )
    var sessionInfoRequestMock: SingularSessionInfoSendRequest!
    var eventRequestMock: SingularEventRequest!
    var conversionValueRequestMock: SingularConversionValueRequest!
    var service: SingularService!

    override func setUpWithError() throws {
        httpClientMock = HTTPClientMock()
        let deviceInfo = AppDeviceInfo(
            platform: "a",
            bundleId: "b",
            osVersion: "c",
            deviceManufacturer: "d",
            deviceModel: "e",
            locale: "f",
            country: "g",
            appVersion: "h"
        )
        sessionInfoRequestMock = SingularSessionInfoSendRequest(
            identifier: "123",
            info: deviceInfo,
            skanParameters: ["something": "test"]
        )
        eventRequestMock = SingularEventRequest(
            identifier: "123",
            name: "some-event",
            info: deviceInfo
        )
        conversionValueRequestMock = SingularConversionValueRequest(
            .init(identifier: "123", eventName: "c", appDeviceInfo: deviceInfo),
            skanParameters: ["something": "test"]
        )
        service = SingularService(client: httpClientMock)
    }

    // Since this is a generic method that supports multiple requests, we re-use the tests
    // MARK: Send Notification Info
    func testSessionInfoFailsOnReceivingErrorResult() async throws {
        try await genericFailsOnReceivingErrorResult(sessionInfoRequestMock)
    }
    func testEventFailsOnReceivingErrorResult() async throws {
        try await genericFailsOnReceivingErrorResult(eventRequestMock)
    }
    func genericFailsOnReceivingErrorResult(_ mockRequest: SingularNotificationRequest) async throws {
        // given
        httpClientMock.response = successResponseMock
        let singularResult = SingularResponse(status: "error", errorReason: "a reason")
        httpClientMock.data = try JSONEncoder().encode(singularResult)

        // when
        do {
            try await service.sendNotification(request: mockRequest)
        } catch SingularService.Error.dataReturnedError(let reason) {
            XCTAssertEqual(reason, "a reason")
        } catch {
            XCTFail("Received unexpected error \(error)")
        }

        // then
        XCTAssertEqual(httpClientMock.requests.count, 1)
        XCTAssertEqual(try? httpClientMock.requests[0].makeURLRequest(), try? mockRequest.makeURLRequest())
    }

    func testSessionInfoFailsOnReceivingNoDataInResponse() async throws {
        try await genericFailsOnReceivingNoDataInResponse(sessionInfoRequestMock)
    }
    func testEventFailsOnReceivingNoDataInResponse() async throws {
        try await genericFailsOnReceivingNoDataInResponse(eventRequestMock)
    }
    func genericFailsOnReceivingNoDataInResponse(_ mockRequest: SingularNotificationRequest) async throws {
        // given
        httpClientMock.response = successResponseMock

        // when
        do {
            try await service.sendNotification(request: mockRequest)
        } catch DecodingError.dataCorrupted {
            // expected
        } catch {
            XCTFail("Received unexpected error \(error)")
        }

        // then
        XCTAssertEqual(httpClientMock.requests.count, 1)
        XCTAssertEqual(try? httpClientMock.requests[0].makeURLRequest(), try? mockRequest.makeURLRequest())
    }

    func testSessionInfoReturnsDataResultOK() async throws {
        try await genericReturnsDataResultOK(sessionInfoRequestMock)
    }
    func testEventReturnsDataResultOK() async throws {
        try await genericReturnsDataResultOK(eventRequestMock)
    }
    func genericReturnsDataResultOK(_ mockRequest: SingularNotificationRequest) async throws {
        // given
        httpClientMock.response = successResponseMock
        httpClientMock.data = try JSONEncoder().encode(SingularResponse(status: "ok", errorReason: nil))

        // when
        try await service.sendNotification(request: mockRequest)

        // then
        XCTAssertEqual(httpClientMock.requests.count, 1)
        XCTAssertEqual(try? httpClientMock.requests[0].makeURLRequest(), try? mockRequest.makeURLRequest())
    }

    func testSessionInfoNetworkError() async throws {
        try await genericNetworkError(sessionInfoRequestMock)
    }
    func testEventNetworkError() async throws {
        try await genericNetworkError(eventRequestMock)
    }
    func genericNetworkError(_ mockRequest: SingularNotificationRequest) async throws {
        // given
        httpClientMock.response = failureResponseMock

        // when
        do {
            // when
            try await service.sendNotification(request: mockRequest)

            // then
            XCTFail("Did not throw error when it should")
        } catch SingularService.Error.network {
            // expected
        } catch {
            XCTFail("Received unexpected error \(error)")
        }

        // Then
        XCTAssertEqual(httpClientMock.requests.count, 1)
        XCTAssertEqual(try? httpClientMock.requests[0].makeURLRequest(), try? mockRequest.makeURLRequest())
    }

    // MARK: Get Conversion Value
    func testGetConversionValueFailsOnFailureStatus() async throws {
        // given
        httpClientMock.response = failureResponseMock

        do {
            // when
            _ = try await service.getConversionValue(request: conversionValueRequestMock)

            // then
            XCTFail("Did not throw error when it should")
        } catch SingularService.Error.network {
            // expected
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }

    func testGetConversionValueReturnsResponse() async throws {
        // given
        httpClientMock.response = successResponseMock
        let expectedResponse = SingularConversionValueResponse(conversionValue: 12, coarseValue: 1, lockWindow: true)
        httpClientMock.data = try JSONEncoder().encode(expectedResponse)

        // when
        let response = try await service.getConversionValue(request: conversionValueRequestMock)

        // then
        XCTAssertEqual(httpClientMock.requests.count, 1)
        XCTAssertEqual(try? httpClientMock.requests[0].makeURLRequest(), try? conversionValueRequestMock.makeURLRequest())
        XCTAssertEqual(response, expectedResponse)
    }

    func testGetConversionDecodesFallbackResponseAndReturnsError() async throws {
        // given
        httpClientMock.response = successResponseMock
        let expectedResponse = SingularResponse(status: "ok", errorReason: nil)
        httpClientMock.data = try JSONEncoder().encode(expectedResponse)

        // when
        do {
            // when
            _ = try await service.getConversionValue(request: conversionValueRequestMock)

            // then
            XCTFail("Did not throw error when it should")
        } catch SingularService.Error.noConversionValueReturned {
            // expected
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }

    func testGetConversionReturnsFallbackResponseError() async throws {
        // given
        httpClientMock.response = successResponseMock
        let expectedResponse = SingularResponse(status: "error", errorReason: "any reason")
        httpClientMock.data = try JSONEncoder().encode(expectedResponse)

        // when
        do {
            // when
            _ = try await service.getConversionValue(request: conversionValueRequestMock)

            // then
            XCTFail("Did not throw error when it should")
        } catch SingularService.Error.dataReturnedError(let reason) {
            XCTAssertEqual(reason, "any reason")
        } catch {
            XCTFail("Received unexpected error \(error)")
        }
    }
}

#endif
