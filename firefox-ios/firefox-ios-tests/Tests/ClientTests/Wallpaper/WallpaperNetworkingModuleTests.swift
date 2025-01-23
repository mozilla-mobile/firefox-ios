// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class WallpaperNetworkingModuleTests: XCTestCase, WallpaperTestDataProvider {
    let url = URL(string: "my.testurl.com")!

    func testAsyncDataCall() async {
        let expectedData = "Test data".data(using: .utf8)!
        let expectedResponse = HTTPURLResponse(url: URL(string: "https://example.com")!,
                                               statusCode: 200,
                                               httpVersion: nil,
                                               headerFields: nil)!

        let session = WallpaperURLSessionMock(
            with: expectedData,
            response: expectedResponse,
            and: nil
        )
        let subject = WallpaperNetworkingModule(with: session)

        do {
            let (responseData, response) = try await subject.data(from: url)
            XCTAssertEqual(responseData, expectedData)
            XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
        } catch {
            XCTFail("This test should not throw an error, but it did.")
        }
    }

    func testServerReturnsError() async {
        let expectedError = URLError(.cannotConnectToHost)
        let session = WallpaperURLSessionMock(with: nil,
                                              response: nil,
                                              and: expectedError)
        let subject = WallpaperNetworkingModule(with: session)

        do {
            _ = try await subject.data(from: url)
            XCTFail("This test should throw an error, but it did not.")
        } catch {
            XCTAssertEqual(error as? URLError, expectedError)
        }
    }

    func testResponseUnder200() async {
        let response = createResponseWith(statusCode: Int.random(in: 0..<200))
        let session = WallpaperURLSessionMock(with: nil,
                                              response: response,
                                              and: nil)
        let subject = WallpaperNetworkingModule(with: session)

        do {
            _ = try await subject.data(from: url)
            XCTFail("This test should throw an error, but it did not.")
        } catch {
            XCTAssertEqual(error as? URLError,
                           URLError(.badServerResponse))
        }
    }

    func testResponseOver300() async {
        let response = createResponseWith(statusCode: Int.random(in: 300...599))
        let session = WallpaperURLSessionMock(with: nil,
                                              response: response,
                                              and: nil)
        let subject = WallpaperNetworkingModule(with: session)

        do {
            _ = try await subject.data(from: url)
            XCTFail("This test should throw an error, but it did not.")
        } catch {
            XCTAssertEqual(error as? URLError,
                           URLError(.badServerResponse))
        }
    }

    func testDataReturned() async {
        let response = createResponseWith(statusCode: Int.random(in: 200..<300))
        let data = getDataFromJSONFile(named: .goodData)
        let session = WallpaperURLSessionMock(with: data,
                                              response: response,
                                              and: nil)
        let subject = WallpaperNetworkingModule(with: session)

        do {
            let (data, _) = try await subject.data(from: url)
            XCTAssertEqual(data, getDataFromJSONFile(named: .goodData))
        } catch {
            XCTFail("This test should not throw an error, but it did: \(error.localizedDescription)")
        }
    }

    func testDataNotReturnedButWithGoodResponse() async {
        let response = createResponseWith(statusCode: Int.random(in: 200..<300))
        let session = WallpaperURLSessionMock(with: nil,
                                              response: response,
                                              and: nil)
        let subject = WallpaperNetworkingModule(with: session)

        do {
            _ = try await subject.data(from: url)
            XCTFail("This test should throw an error, but it did not.")
        } catch {
            XCTAssertEqual(error as? WallpaperServiceError,
                           WallpaperServiceError.dataUnavailable)
        }
    }
}

extension WallpaperNetworkingModuleTests {
    private func createResponseWith(statusCode: Int) -> HTTPURLResponse? {
        return HTTPURLResponse(url: url,
                               statusCode: statusCode,
                               httpVersion: nil,
                               headerFields: nil)
    }
}
