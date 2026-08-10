// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class BaseRequestTests: XCTestCase {

    private struct TestRequest: BaseRequest {
        var baseURL: BaseURL = .api
        var path: String = "/test"
        var queryParameters: [String: String]?
        var additionalHeaders: [String: String]?
        var body: Data?

        var method: HTTPMethod { .get }
    }

    // MARK: - resolvedBaseURL

    func testResolvedBaseURLForAPI() {
        let request = TestRequest(baseURL: .api)
        XCTAssertEqual(request.resolvedBaseURL, Environment.current.urlProvider.apiRoot)
    }

    func testResolvedBaseURLForWeb() {
        let request = TestRequest(baseURL: .web)
        XCTAssertEqual(request.resolvedBaseURL, Environment.current.urlProvider.root)
    }

    func testResolvedBaseURLForCustom() {
        let customURL = URL(string: "https://example.com/asset.json")!
        let request = TestRequest(baseURL: .custom(customURL))
        XCTAssertEqual(request.resolvedBaseURL, customURL)
    }

    // MARK: - X-Ecosia-App header

    func testAPIRequestAttachesEcosiaAppHeader() throws {
        let request = try TestRequest(baseURL: .api).makeURLRequest()
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Ecosia-App"), "ios")
    }

    func testWebRequestAttachesEcosiaAppHeader() throws {
        let request = try TestRequest(baseURL: .web).makeURLRequest()
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-Ecosia-App"), "ios")
    }

    func testCustomRequestDoesNotAttachEcosiaAppHeader() throws {
        let customURL = URL(string: "https://example.com/asset.json")!
        let request = try TestRequest(baseURL: .custom(customURL)).makeURLRequest()
        XCTAssertNil(request.value(forHTTPHeaderField: "X-Ecosia-App"))
    }

    // MARK: - Cloudflare Access headers
    //
    // Only the `.custom` case is asserted here: the real presence of these headers for
    // `.api`/`.web` depends on `Environment.current` (derived from `Bundle.main.bundleIdentifier`,
    // see `withCloudFlareAuthParameters()`), which always resolves to `.debug` in this test
    // target and so can't be flipped to `.staging` per-test. The security property that
    // matters here doesn't need that: a `.custom` host must never get these headers, full stop.

    func testCustomRequestDoesNotAttachCloudflareAccessHeaders() throws {
        let customURL = URL(string: "https://example.com/asset.json")!
        let request = try TestRequest(baseURL: .custom(customURL)).makeURLRequest()
        XCTAssertNil(request.value(forHTTPHeaderField: CloudflareKeyProvider.clientId))
        XCTAssertNil(request.value(forHTTPHeaderField: CloudflareKeyProvider.clientSecret))
    }

    // MARK: - Custom URL is used as-is

    /// A `.custom` URL (e.g. a presigned upload URL) already carries its own path/query,
    /// often signed, and must survive untouched — even though `path` here is non-empty.
    func testCustomRequestUsesExactURLIgnoringPath() throws {
        let customURL = URL(string: "https://example.com/asset.json?signature=abc123")!
        let request = try TestRequest(baseURL: .custom(customURL), path: "/should-be-ignored").makeURLRequest()
        XCTAssertEqual(request.url, customURL)
    }
}
