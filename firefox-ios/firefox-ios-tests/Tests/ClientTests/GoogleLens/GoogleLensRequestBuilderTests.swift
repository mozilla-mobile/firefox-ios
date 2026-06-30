// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class GoogleLensRequestBuilderTests: XCTestCase {
    private let fixedDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let boundary = "TESTBOUNDARY"
    private let jpegData = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10])

    func test_makeUploadRequest_isPostToUploadEndpoint() {
        let request = makeSubject().makeUploadRequest(for: makeInput())

        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.url?.scheme, "https")
        XCTAssertEqual(request.url?.host, "lens.google.com")
        XCTAssertEqual(request.url?.path, "/upload")
    }

    func test_makeUploadRequest_setsRequiredAndRecommendedQueryParams() throws {
        let input = makeInput(viewportSize: CGSize(width: 390, height: 844))

        let request = makeSubject(localeProvider: MockLocaleProvider(languageCode: "en"))
            .makeUploadRequest(for: input)

        let items = try queryItems(from: request)
        XCTAssertEqual(items["ep"], "fntpubb")
        XCTAssertEqual(items["st"], "1700000000000")
        XCTAssertEqual(items["vpw"], "390")
        XCTAssertEqual(items["vph"], "844")
        XCTAssertEqual(items["hl"], "en")
    }

    func test_makeUploadRequest_omitsLanguageParam_whenLocaleProviderHasNoLanguageCode() throws {
        let request = makeSubject(localeProvider: MockLocaleProvider(languageCode: nil)).makeUploadRequest(for: makeInput())

        let items = try queryItems(from: request)
        XCTAssertNil(items["hl"])
    }

    func test_makeUploadRequest_setsMultipartContentTypeWithBoundary() {
        let request = makeSubject().makeUploadRequest(for: makeInput())

        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"),
                       "multipart/form-data; boundary=\(boundary)")
    }

    func test_makeUploadRequest_bodyContainsImagePartAndDimensions() throws {
        let input = makeInput(imageDimensions: CGSize(width: 800, height: 600))

        let request = makeSubject().makeUploadRequest(for: input)
        let body = try XCTUnwrap(request.httpBody)

        XCTAssertNotNil(body.range(of: data("--\(boundary)\r\n")))
        XCTAssertNotNil(body.range(of: data("name=\"encoded_image\"; filename=\"image.jpg\"")))
        XCTAssertNotNil(body.range(of: data("Content-Type: image/jpeg")))
        XCTAssertNotNil(body.range(of: jpegData), "Image bytes should be embedded in the body")
        XCTAssertNotNil(body.range(of: data("name=\"processed_image_dimensions\"")))
        XCTAssertNotNil(body.range(of: data("800,600")))
        XCTAssertNotNil(body.range(of: data("--\(boundary)--\r\n")))
    }

    // MARK: - Helpers
    private func makeSubject(
        localeProvider: LocaleProvider = MockLocaleProvider(languageCode: "en")
    ) -> GoogleLensRequestBuilder {
        return GoogleLensRequestBuilder(dateProvider: { self.fixedDate },
                                        localeProvider: localeProvider,
                                        boundaryProvider: { self.boundary })
    }

    private func makeInput(imageDimensions: CGSize = CGSize(width: 800, height: 600),
                           viewportSize: CGSize = CGSize(width: 390, height: 844)) -> GoogleLensUploadInput {
        return GoogleLensUploadInput(jpegData: jpegData,
                                     imageDimensions: imageDimensions,
                                     viewportSize: viewportSize)
    }

    private func data(_ string: String) -> Data {
        return Data(string.utf8)
    }

    private func queryItems(from request: URLRequest) throws -> [String: String] {
        let url = try XCTUnwrap(request.url)
        let components = try XCTUnwrap(URLComponents(url: url, resolvingAgainstBaseURL: false))
        return Dictionary(uniqueKeysWithValues: (components.queryItems ?? []).map { ($0.name, $0.value ?? "") })
    }
}
