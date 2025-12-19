// swiftlint:disable force_try
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class UnleashTests: XCTestCase {

    static let appVersion = "0.0.0"

    override func setUp() {
        Unleash.clearInstanceModel()
        Unleash.rules = []
        try? FileManager.default.removeItem(at: FileManager.unleash)
    }

    override func tearDown() {
        Unleash.clearInstanceModel()
        Unleash.rules = []
        try? FileManager.default.removeItem(at: FileManager.unleash)
    }

    func testSaveAndLoadFromCache() async throws {
        var model = Unleash.Model()
        let toggle = Unleash.Toggle(name: Unleash.Toggle.Name.configTest.rawValue,
                                    enabled: true,
                                    variant: .init(name: "control", enabled: true, payload: nil))
        model.toggles.insert(toggle)
        try await Unleash.save(model)

        let loaded = await Unleash.load()
        Unleash.model = loaded!

        XCTAssertTrue(Unleash.isEnabled(.configTest))
        XCTAssertTrue(Unleash.getVariant(.configTest).name == "control")
        XCTAssertTrue(Unleash.getVariant(.configTest).enabled)
    }

    func testReset() async throws {
        let model = try await Unleash.start(env: .staging, appVersion: Self.appVersion)
        let resetModel = try await Unleash.reset(env: .staging, appVersion: Self.appVersion)

        XCTAssertNotEqual(model.id, resetModel.id)
    }

    func testMakeURL() {
        let base = URL(string: "https://ecosia.org")!
        let context = ["foo": "bar"]
        var request = UnleashTests.stagingUnleashRequest
        request.queryParameters = context
        let url = request.baseURL

        XCTAssertTrue(url.absoluteString.hasPrefix(base.absoluteString))
        XCTAssertEqual(URLComponents(string: try request.makeURLRequest().url!.absoluteString)?.queryItems?.count, 1)
    }

    func testMakeRequest() {
        let stagingRequest = try! UnleashTests.stagingUnleashRequest.makeURLRequest()
        XCTAssertNotNil(stagingRequest.value(forHTTPHeaderField: CloudflareKeyProvider.clientId))
        XCTAssertNotNil(stagingRequest.value(forHTTPHeaderField: CloudflareKeyProvider.clientSecret))
        XCTAssertNotNil(stagingRequest.value(forHTTPHeaderField: "If-None-Match"))

        let prodRequest = try! UnleashTests.prodUnleashRequest.makeURLRequest()
        XCTAssertNil(prodRequest.value(forHTTPHeaderField: CloudflareKeyProvider.clientId))
        XCTAssertNil(prodRequest.value(forHTTPHeaderField: CloudflareKeyProvider.clientSecret))
        XCTAssertNotNil(stagingRequest.value(forHTTPHeaderField: "If-None-Match"))
    }

    func testConfigTestEnabled() {

        let expectedEnabledStatus = true
        let toggleName: Unleash.Toggle.Name = .configTest
        let exampleToggle = Unleash.Toggle(name: toggleName.rawValue,
                                           enabled: expectedEnabledStatus,
                                           variant: Unleash.Variant(name: "", enabled: false, payload: nil))

        let mockModel = Unleash.Model(toggles: Set([exampleToggle]))

        Unleash.model = mockModel

        let isEnabled = Unleash.isEnabled(toggleName)

        XCTAssertEqual(isEnabled, expectedEnabledStatus)
    }

    func testIsLoadedFlagReflectsUnleashState() async {
        XCTAssertFalse(Unleash.isLoaded)

        _ = try? await Unleash.start(appVersion: "1.0.0")
        XCTAssertTrue(Unleash.isLoaded)
        let firstId = Unleash.model.id

        Unleash.clearInstanceModel()
        XCTAssertFalse(Unleash.isLoaded)

        _ = try? await Unleash.start(appVersion: "1.0.0")
        XCTAssertEqual(Unleash.model.id, firstId, "Id should remain the same between sessions")

        _ = try? await Unleash.reset(env: .production, appVersion: "1.0.0")
        XCTAssertTrue(Unleash.isLoaded)
        XCTAssertNotEqual(Unleash.model.id, firstId, "Id should change after reset")
    }

    func testQueryParametersWithMockedUser() {
        let originalUser = User.shared

        var mockUser = User()
        mockUser.versionOnInstall = "2.5.0"
        mockUser.marketCode = Local.make(for: .init(identifier: "de-de"))
        mockUser.searchCount = 150
        User.shared = mockUser

        let parameters = Unleash.queryParameters(appVersion: "3.0.0")
        XCTAssertEqual(parameters["versionOnInstall"], "2.5.0")
        XCTAssertEqual(parameters["market"], "de-de")
        XCTAssertEqual(parameters["personalCounterSearches"], "150")
        XCTAssertEqual(parameters["appVersion"], "3.0.0")

        User.shared = originalUser
    }

    func testQueryParametersWithMockedLocale() {
        let originalLocaleSource = Unleash.localeSource

        let mockLocale = MockLocale("fr", countryName: "France")
        Unleash.localeSource = mockLocale

        let parameters = Unleash.queryParameters(appVersion: "2.0.0")
        XCTAssertEqual(parameters["deviceRegion"], "fr")
        XCTAssertEqual(parameters["country"], "France")

        Unleash.localeSource = originalLocaleSource
    }

    func testQueryParametersWithMockedLocaleNilCountry() {
        let originalLocaleSource = Unleash.localeSource

        let mockLocale = MockLocale("xx", countryName: nil)
        Unleash.localeSource = mockLocale

        let parameters = Unleash.queryParameters(appVersion: "1.5.0")
        XCTAssertEqual(parameters["deviceRegion"], "xx")
        XCTAssertEqual(parameters["country"], "Unknown")

        Unleash.localeSource = originalLocaleSource
    }
}

extension UnleashTests {

    static func makeAvailableUnleashModel() async throws -> Unleash.Model {
        try await Unleash.start(client: MockOKHTTPClient(), request: UnleashTests.stagingUnleashRequest, env: .staging, appVersion: Self.appVersion)
    }
}

extension UnleashTests {

    struct MockOKHTTPClient: HTTPClient {

        func perform(_ request: BaseRequest) async throws -> HTTPClient.Result {
            let url = URL(string: "https://ecosia.org")!
            let okResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
            let model = Unleash.Model(id: UUID(), toggles: [], updated: Date(), etag: "a-etag")
            let modelData = try JSONEncoder().encode(model)
            return (modelData, okResponse)
        }
    }
}

extension UnleashTests {

    static var stagingUnleashRequest = MockStagingUnleashRequest(etag: "a-tag")
    static var prodUnleashRequest = MockProdUnleashRequest(etag: "a-tag")

    static func mockMakeURLRequest(for url: URL,
                                   path: String?,
                                   queryParameters: [String: String]?,
                                   etag: String,
                                   method: HTTPMethod,
                                   body: Data?,
                                   environment: Environment) -> URLRequest {

        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)

        if let queryParameters {
            urlComponents?.queryItems = queryParameters.map({ .init(name: $0.key, value: $0.value ) })
        }

        if let path {
            urlComponents?.path = path
        }

        var request = URLRequest(url: urlComponents?.url ?? url)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.httpBody = body
        return request.withCloudFlareAuthParameters(environment: environment)
    }

    struct MockStagingUnleashRequest: BaseRequest {

        var environment: Environment {
            .staging
        }

        var method: Ecosia.HTTPMethod {
            .get
        }

        var baseURL: URL {
            URL(string: "https://ecosia.org")!
        }

        var path: String {
            ""
        }

        var etag: String

        var queryParameters: [String: String]?

        var additionalHeaders: [String: String]? {
            ["If-None-Match": etag]
        }

        var body: Data?

        func makeURLRequest() throws -> URLRequest {
            UnleashTests.mockMakeURLRequest(for: baseURL,
                                            path: path,
                                            queryParameters: queryParameters,
                                            etag: etag,
                                            method: method,
                                            body: body,
                                            environment: environment)
        }
    }

    struct MockProdUnleashRequest: BaseRequest {

        var environment: Environment {
            .production
        }

        var method: Ecosia.HTTPMethod {
            .get
        }

        var baseURL: URL {
            URL(string: "https://ecosia.org")!
        }

        var path: String {
            ""
        }

        var etag: String

        var queryParameters: [String: String]?

        var additionalHeaders: [String: String]? {
            ["If-None-Match": etag]
        }

        var body: Data?

        func makeURLRequest() throws -> URLRequest {
            UnleashTests.mockMakeURLRequest(for: baseURL,
                                            path: path,
                                            queryParameters: queryParameters,
                                            etag: etag,
                                            method: method,
                                            body: body,
                                            environment: environment)
        }
    }
}

extension UnleashTests {

    // Need two types of mocks as the `Unleash.addRule` performs a type-safe addition

    struct MockAppUpdateRule: RefreshingRule {
        let shouldRefresh: Bool
    }

    struct MockDeviceRegionChangeRule: RefreshingRule {
        let shouldRefresh: Bool
    }

    func testShouldRefreshIfAnyRuleIsTrue() async {
        // Given
        let rule1 = MockAppUpdateRule(shouldRefresh: false)
        let rule2 = MockDeviceRegionChangeRule(shouldRefresh: true)

        // When
        Unleash.addRule(rule1)
        Unleash.addRule(rule2)

        // Then
        XCTAssertTrue(Unleash.shouldRefresh, "Unleash should refresh if any rule returns true.")
    }

    func testShouldNotRefreshIfAllRulesAreFalse() async {
        // Given
        let rule1 = MockAppUpdateRule(shouldRefresh: false)
        let rule2 = MockDeviceRegionChangeRule(shouldRefresh: false)

        // When
        Unleash.addRule(rule1)
        Unleash.addRule(rule2)

        // Then
        XCTAssertFalse(Unleash.shouldRefresh, "Unleash should not refresh if all rules return false.")
    }
}
// swiftlint:enable force_try
