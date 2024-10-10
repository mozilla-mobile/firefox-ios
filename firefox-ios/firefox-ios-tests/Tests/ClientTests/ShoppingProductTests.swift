// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import MozillaAppServices

final class ShoppingProductTests: XCTestCase {
    var client: TestFakespotClient!

    override func setUp() {
        super.setUp()
        client = TestFakespotClient()
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }

    func testAmazonURL_returnsExpectedProduct() {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!

        let sut = ShoppingProduct(url: url, client: client)
        let expected = Product(
            id: "B087T8Q2C4",
            host: "amazon.com",
            topLevelDomain: "com",
            sitename: "amazon"
        )

        XCTAssertEqual(sut.product, expected)
    }

    func testBestBuyURL_returnsExpectedProduct() {
        let url = URL(string: "https://www.bestbuy.com/site/macbook-air-13-3-laptop-apple-m1-chip-8gb-memory-256gb-ssd-space-gray/5721600.p?skuId=5721600")!

        let sut = ShoppingProduct(url: url, client: client)
        let expected = Product(
            id: "5721600.p",
            host: "bestbuy.com",
            topLevelDomain: "com",
            sitename: "bestbuy"
        )

        XCTAssertEqual(sut.product, expected)
    }

    func testBasicURL_returnsNilProduct() {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url, client: client)

        XCTAssertNil(sut.product)
    }

    func testBasicURL_hidesShoppingIcon() {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url, client: client)

        XCTAssertFalse(sut.isShoppingButtonVisible)
    }

    func testFetchingProductAnalysisData_WithInvalidURL_ReturnsNil() async throws {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url, client: client)
        let productData = try await sut.fetchProductAnalysisData()

        XCTAssertNil(productData)
    }

    func testFetchingProductAnalysisData_WithValidURL_CallsClientAPI() async throws {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!

        let sut = ShoppingProduct(url: url, client: client)
        let productData = try await sut.fetchProductAnalysisData()

        XCTAssertNotNil(productData)
        XCTAssertTrue(client.fetchProductAnalysisDataCalled)
        XCTAssertEqual(client.productId, "B087T8Q2C4")
        XCTAssertEqual(client.website, "amazon.com")
    }

    func testTriggerProductAnalyzeData_WithInvalidURL_ReturnsNil() async throws {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url, client: client)
        let analyzeStatus = try await sut.triggerProductAnalyze()

        XCTAssertNil(analyzeStatus)
    }

    func testTriggerProductAnalyzeData_WithValidURL_CallsClientAPI() async throws {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!

        let sut = ShoppingProduct(url: url, client: client)
        let productData = try await sut.triggerProductAnalyze()

        XCTAssertNotNil(productData)
        XCTAssertTrue(client.triggerProductAnalyzeCallCalled)
        XCTAssertEqual(client.productId, "B087T8Q2C4")
        XCTAssertEqual(client.website, "amazon.com")
    }

    func testgetProductAnalysisStatusResponse_WithInvalidURL_ReturnsNil() async throws {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url, client: client)
        let analyzeStatus = try await sut.getProductAnalysisStatus()

        XCTAssertNil(analyzeStatus)
    }

    func testgetProductAnalysisStatusResponse_WithValidURL_CallsClientAPI() async throws {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!

        let sut = ShoppingProduct(url: url, client: client)
        let productData = try await sut.getProductAnalysisStatus()

        XCTAssertNotNil(productData)
        XCTAssertTrue(client.getProductAnalysisStatusCallCalled)
        XCTAssertEqual(client.productId, "B087T8Q2C4")
        XCTAssertEqual(client.website, "amazon.com")
    }

    func testFetchingProductAdData_WithInvalidURL_ReturnsEmptyArray() async {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url, client: client)
        let productAdData = await sut.fetchProductAdsData()

        XCTAssertTrue(productAdData.isEmpty)
    }

    func testFetchingProductAdData_WithValidURL_CallsClientAPI() async {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!

        let sut = ShoppingProduct(url: url, client: client)
        let productAdData = await sut.fetchProductAdsData()

        XCTAssertNotNil(productAdData)
        XCTAssertTrue(client.fetchProductAdsDataCalled)
        XCTAssertEqual(client.productId, "B087T8Q2C4")
        XCTAssertEqual(client.website, "amazon.com")
    }

    func testFetchingProductAnalysisData_WithThrowingServerError_RetriesClientAPI() async {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!
        let client = ThrowingFakeSpotClient(error: NSError(domain: "HTTP Error", code: 500, userInfo: nil))
        let sut = ShoppingProduct(url: url, client: client)
        _ = try? await sut.fetchProductAnalysisData(maxRetries: 3)

        let expected = 4 // 3 + the original API call
        XCTAssertEqual(client.fetchProductAnalysisDataCallCount, expected)
    }

    func testFetchingProductAnalysisData_WithThrowingRelayError_RetriesClientAPI() async {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!
        let client = ThrowingFakeSpotClient(error: OhttpError.RelayFailed(message: "Relay error"))
        let sut = ShoppingProduct(url: url, client: client)
        _ = try? await sut.fetchProductAnalysisData(maxRetries: 3)

        let expected = 4 // 3 + the original API call
        XCTAssertEqual(client.fetchProductAnalysisDataCallCount, expected)
    }

    func testFetchingProductAnalysisData_WithAnyThrowing_DoesNotRetryClientAPI() async {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!
        let client = ThrowingFakeSpotClient(error: NSError(domain: "Any Error", code: 404, userInfo: nil))
        let sut = ShoppingProduct(url: url, client: client)
        _ = try? await sut.fetchProductAnalysisData(maxRetries: 3)

        let expected = 1
        XCTAssertEqual(client.fetchProductAnalysisDataCallCount, expected)
    }

    func testFetchingProductAnalysisData_WithSuccess_DoesNotRetryClientAPI() async {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!
        let sut = ShoppingProduct(url: url, client: client)
        _ = try? await sut.fetchProductAnalysisData(maxRetries: 3)

        let expected = 1
        XCTAssertEqual(client.fetchProductAnalysisDataCallCount, expected)
    }

    func testReportProductBackInStock_WithInvalidURL_ReturnsNil() async throws {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url, client: client)
        let reportStatus = try await sut.reportProductBackInStock()

        XCTAssertNil(reportStatus)
    }

    func testReportProductBackInStock_WithValidURL_CallsClientAPI() async throws {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!

        let sut = ShoppingProduct(url: url, client: client)
        let reportStatus = try await sut.reportProductBackInStock()

        XCTAssertNotNil(reportStatus)
        XCTAssertTrue(client.reportProductBackInStockCalled)
        XCTAssertEqual(client.productId, "B087T8Q2C4")
        XCTAssertEqual(client.website, "amazon.com")
    }

    func testAdsWithRatingsHigherThanMinRating() {
        let minRating = 4.0
        let productAds = [
            ProductAdsResponse(adjustedRating: 4.5),
            ProductAdsResponse(adjustedRating: 4.7),
            ProductAdsResponse(adjustedRating: 4.2)
        ]

        let selectedAdCard = productAds
            .sorted(by: { $0.adjustedRating > $1.adjustedRating })
            .first(where: { $0.adjustedRating >= minRating })

        XCTAssertEqual(
            selectedAdCard,
            ProductAdsResponse(adjustedRating: 4.7),
            "The ad with the highest rating should be selected."
        )
    }

    func testAdsWithRatingsLowerThanMinRating() {
        let minRating = 4.0
        let productAds = [
            ProductAdsResponse(adjustedRating: 3.5),
            ProductAdsResponse(adjustedRating: 3.7),
            ProductAdsResponse(adjustedRating: 3.2)
        ]

        let selectedAdCard = productAds
            .sorted(by: { $0.adjustedRating > $1.adjustedRating })
            .first(where: { $0.adjustedRating >= minRating })

        XCTAssertNil(selectedAdCard)
    }

    func testAdsWithSomeRatingsEqualToMinRating() {
        let minRating = 4.0
        let productAds = [
            ProductAdsResponse(adjustedRating: 4.0),
            ProductAdsResponse(adjustedRating: 3.9),
            ProductAdsResponse(adjustedRating: 4.2)
        ]

        let selectedAdCard = productAds
            .sorted(by: { $0.adjustedRating > $1.adjustedRating })
            .first(where: { $0.adjustedRating >= minRating })

        XCTAssertEqual(selectedAdCard, ProductAdsResponse(adjustedRating: 4.2))
    }

    func testSupportedTLDWebsites_TopLevelDomainFound() {
        let product = Product(
            id: "123",
            host: "example.com",
            topLevelDomain: "com",
            sitename: "example"
        )

        let fakeConfig: [String: WebsiteConfig] = [
            "website1": WebsiteConfig(validTlDs: ["com", "net"]),
            "website2": WebsiteConfig(validTlDs: ["org", "gov"]),
            "website3": WebsiteConfig(validTlDs: ["edu", "io"])
        ]

        let fakeFeatureLayer = NimbusFakespotFeatureLayerMock(config: fakeConfig)

        let sut = ShoppingProduct(
            url: URL(string: "https://example.com")!,
            nimbusFakespotFeatureLayer: fakeFeatureLayer,
            client: client
        )
        sut.product = product

        let result = sut.supportedTLDWebsites
        XCTAssertEqual(result, ["website1"])
    }

    func testSupportedTLDWebsites_TopLevelDomainNotFound() {
        let product = Product(
            id: "123",
            host: "example.com",
            topLevelDomain: "xyz",
            sitename: "example"
        )

        let fakeConfig: [String: WebsiteConfig] = [
            "website1": WebsiteConfig(validTlDs: ["com", "net"]),
            "website2": WebsiteConfig(validTlDs: ["org", "gov"]),
            "website3": WebsiteConfig(validTlDs: ["edu", "io"])
        ]

        let fakeFeatureLayer = NimbusFakespotFeatureLayerMock(config: fakeConfig)
        let sut = ShoppingProduct(
            url: URL(string: "https://example.com")!,
            nimbusFakespotFeatureLayer: fakeFeatureLayer,
            client: client
        )
        sut.product = product

        let result = sut.supportedTLDWebsites
        XCTAssertEqual(result, [])
    }

    func testSupportedTLDWebsites_ProductIsNil() {
        let fakeConfig: [String: WebsiteConfig] = [
            "website1": WebsiteConfig(validTlDs: ["com", "net"]),
            "website2": WebsiteConfig(validTlDs: ["org", "gov"]),
            "website3": WebsiteConfig(validTlDs: ["edu", "io"])
        ]

        let fakeFeatureLayer = NimbusFakespotFeatureLayerMock(config: fakeConfig)
        let sut = ShoppingProduct(
            url: URL(string: "https://example.com")!,
            nimbusFakespotFeatureLayer: fakeFeatureLayer,
            client: client
        )
        sut.product = nil

        let result = sut.supportedTLDWebsites
        XCTAssertNil(result)
    }

    func testReportAdEvent_WithValidURL_CallsClientAPI() async throws {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!
        let sut = ShoppingProduct(url: url, client: client)

        _ = try await sut.reportAdEvent(eventName: .trustedDealsLinkClicked, eventSource: "web", aidvs: ["aidv1"])

        XCTAssertTrue(client.reportAdEventCalled)
        XCTAssertEqual(client.lastEventName, .trustedDealsLinkClicked)
        XCTAssertEqual(client.lastEventSource, "web")
        XCTAssertEqual(client.aidvs, ["aidv1"])
    }
}

fileprivate extension ProductAdsResponse {
    init(adjustedRating: Double) {
        self.init(
            name: "",
            url: URL(string: "www.example.com")!,
            imageUrl: URL(string: "www.example.com")!,
            price: "",
            currency: "",
            grade: .a,
            adjustedRating: adjustedRating,
            analysisUrl: URL(string: "www.example.com")!,
            sponsored: false,
            aid: ""
        )
    }
}

final class ThrowingFakeSpotClient: FakespotClientType {
    var fetchProductAnalysisDataCallCount = 0
    var fetchProductAdDataCallCount = 0
    var triggerProductAnalyzeCallCount = 0
    var getProductAnalysisStatusCount = 0
    var reportProductBackInStockCallCount = 0
    var reportAdEventCallCount = 0

    let error: Error

    init(error: Error) {
        self.error = error
    }

    func reportAdEvent(
        eventName: Client.FakespotAdsEvent,
        eventSource: String,
        aidvs: [String]
    ) async throws -> Client.AdEventsResponse? {
        reportAdEventCallCount += 1
        throw error
    }

    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisResponse {
        fetchProductAnalysisDataCallCount += 1
        throw error
    }

    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsResponse] {
        fetchProductAdDataCallCount += 1
        return []
    }

    func triggerProductAnalyze(productId: String, website: String) async throws -> ProductAnalyzeResponse {
        triggerProductAnalyzeCallCount += 1
        throw error
    }

    func getProductAnalysisStatus(productId: String, website: String) async throws -> ProductAnalysisStatusResponse {
        getProductAnalysisStatusCount += 1
        throw error
    }

    func reportProductBackInStock(productId: String, website: String) async throws -> ReportResponse {
        reportProductBackInStockCallCount += 1
        throw error
    }
}

final class NimbusFakespotFeatureLayerMock: NimbusFakespotFeatureLayerProtocol {
    var relayURL: URL?
    let config: [String: WebsiteConfig]

    init(config: [String: WebsiteConfig]) {
        self.config = config
    }

    func getSiteConfig(siteName: String) -> WebsiteConfig? {
        config[siteName]
    }
}

final class TestFakespotClient: FakespotClientType {
    var productId: String = ""
    var website: String = ""
    var fetchProductAnalysisDataCalled = false
    var fetchProductAdsDataCalled = false
    var fetchProductAnalysisDataCallCount = 0
    var triggerProductAnalyzeCallCalled = false
    var getProductAnalysisStatusCallCalled = false
    var reportProductBackInStockCalled = false
    var reportAdEventCalled = false
    var reportAdEventCallCount = 0
    var lastEventName: FakespotAdsEvent?
    var lastEventSource: String?
    var aidvs: [String] = []

    func reportAdEvent(
        eventName: Client.FakespotAdsEvent,
        eventSource: String,
        aidvs: [String]
    ) async throws -> Client.AdEventsResponse? {
        self.reportAdEventCalled = true
        self.reportAdEventCallCount += 1
        self.lastEventName = eventName
        self.lastEventSource = eventSource
        self.aidvs = aidvs
        return [:]
    }

    func fetchProductAnalysisData(productId: String, website: String) async throws -> ProductAnalysisResponse {
        self.fetchProductAnalysisDataCallCount += 1
        self.productId = productId
        self.website = website
        self.fetchProductAnalysisDataCalled = true
        return .empty
    }

    func fetchProductAdData(productId: String, website: String) async throws -> [ProductAdsResponse] {
        self.productId = productId
        self.website = website
        self.fetchProductAdsDataCalled = true
        return []
    }

    func triggerProductAnalyze(productId: String, website: String) async throws -> ProductAnalyzeResponse {
        self.triggerProductAnalyzeCallCalled = true
        self.productId = productId
        self.website = website
        return .inProgress
    }

    func getProductAnalysisStatus(productId: String, website: String) async throws -> ProductAnalysisStatusResponse {
        self.getProductAnalysisStatusCallCalled = true
        self.productId = productId
        self.website = website
        return .init(status: .inProgress, progress: 99.9)
    }

    func reportProductBackInStock(productId: String, website: String) async throws -> ReportResponse {
        self.reportProductBackInStockCalled = true
        self.productId = productId
        self.website = website
        return ReportResponse(message: .reportCreated)
    }
}

extension ProductAnalyzeResponse {
    static let inProgress = ProductAnalyzeResponse(status: .inProgress)
}

extension ProductAnalysisResponse {
    static let empty = Self(
        productId: "",
        grade: .a,
        adjustedRating: 0,
        needsAnalysis: false,
        analysisUrl: URL(string: "https://www.example.com")!,
        highlights: Highlights(price: [], quality: [], competitiveness: [], shipping: [], packaging: []),
        pageNotSupported: true,
        isProductDeletedReported: false,
        isProductDeleted: false,
        notEnoughReviews: false,
        lastAnalysisTime: nil
    )
}
