// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Foundation
@testable import Ecosia

class UnleashFeatureManagementSessionInitializerTests: XCTestCase {

    // MARK: - Test Mocks

    class MockHTTPClient: HTTPClient {

        var performCalled = false
        var performRequest: BaseRequest?
        var performResult: HTTPClient.Result?
        var performError: Error?

        func perform(_ request: BaseRequest) async throws -> HTTPClient.Result {
            performCalled = true
            performRequest = request

            if let error = performError {
                throw error
            }

            return performResult ?? (Data(), HTTPURLResponse())
        }
    }

    // MARK: - Test Cases

    func testInitializeSession_WithValidData_ReturnsDecodedObject() async throws {
        // Arrange
        let client = MockHTTPClient()
        let request = UnleashTests.stagingUnleashRequest
        let expectedData = "{\"etag\": \"a-etag\"}".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://ecosia.org")!, statusCode: 200, httpVersion: nil, headerFields: ["etag": "a-etag"])!
        let model = try await UnleashTests.makeAvailableUnleashModel()
        let initializer = UnleashFeatureManagementSessionInitializer(client: client, request: request, model: model)

        client.performResult = (expectedData, expectedResponse)

        // Act
        let latestAvailableModel: Unleash.Model = try await initializer.startSession()!

        // Assert
        XCTAssertTrue(client.performCalled, "The `perform` method should be called.")
        XCTAssertEqual(try? client.performRequest?.makeURLRequest(), try? request.makeURLRequest(), "The request passed to the `perform` method should match the initialized request.")
        XCTAssertEqual(latestAvailableModel.etag, "a-etag", "The decoded value should match the expected value.")
    }

    func testInitializeSession_WithNoData_ThrowsNoDataError() async throws {
        // Arrange
        let client = MockHTTPClient()
        let request = UnleashTests.stagingUnleashRequest
        let model = try await UnleashTests.makeAvailableUnleashModel()
        let initializer = UnleashFeatureManagementSessionInitializer(client: client, request: request, model: model)

        let expectedResponse = HTTPURLResponse(url: URL(string: "https://ecosia.org")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client.performResult = (Data(), expectedResponse)

        // Act & Assert
        do {
            let _: Unleash.Model = try await initializer.startSession()!
        } catch {
            XCTAssertEqual(error as? UnleashFeatureManagementSessionInitializer.Error, .noData, "The error should be `.noData`.")
        }
    }

    func testInitializeSession_WithNetworkError_ThrowsNetworkError() async throws {
        // Arrange
        let client = MockHTTPClient()
        let model = try await UnleashTests.makeAvailableUnleashModel()
        let initializer = UnleashFeatureManagementSessionInitializer(client: client, request: UnleashTests.stagingUnleashRequest, model: model)

        let expectedError = UnleashFeatureManagementSessionInitializer.Error.network
        client.performError = expectedError

        // Act & Assert
        do {
            let _: Unleash.Model = try await initializer.startSession()!
        } catch {
            XCTAssertEqual(error as? UnleashFeatureManagementSessionInitializer.Error, expectedError, "The error should be `.network`.")
        }
    }
}
