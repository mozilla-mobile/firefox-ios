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
        super.tearDown()
        client = nil
    }

    func testAmazonURL_returnsExpectedProduct() {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!

        let sut = ShoppingProduct(url: url, client: client)
        let expected = Product(id: "B087T8Q2C4", host: "amazon.com", topLevelDomain: "com", sitename: "amazon")

        XCTAssertEqual(sut.product, expected)
    }

    func testBestBuyURL_returnsExpectedProduct() {
        let url = URL(string: "https://www.bestbuy.com/site/macbook-air-13-3-laptop-apple-m1-chip-8gb-memory-256gb-ssd-space-gray/5721600.p?skuId=5721600")!

        let sut = ShoppingProduct(url: url, client: client)
        let expected = Product(id: "5721600.p", host: "bestbuy.com", topLevelDomain: "com", sitename: "bestbuy")

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

    func testFetchingProductAdData_WithInvalidURL_ReturnsEmptyArray() async throws {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url, client: client)
        let productAdData = try await sut.fetchProductAdsData()

        XCTAssertTrue(productAdData.isEmpty)
    }

    func testFetchingProductAdData_WithValidURL_CallsClientAPI() async throws {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!

        let sut = ShoppingProduct(url: url, client: client)
        let productAdData = try await sut.fetchProductAdsData()

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
}

final class ThrowingFakeSpotClient: FakespotClientType {
    var fetchProductAnalysisDataCallCount = 0
    var fetchProductAdDataCallCount = 0
    var triggerProductAnalyzeCallCount = 0
    var getProductAnalysisStatusCount = 0
    var reportProductBackInStockCallCount = 0

    let error: Error

    init(error: Error) {
        self.error = error
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

final class TestFakespotClient: FakespotClientType {
    var productId: String = ""
    var website: String = ""
    var fetchProductAnalysisDataCalled = false
    var fetchProductAdsDataCalled = false
    var fetchProductAnalysisDataCallCount = 0
    var triggerProductAnalyzeCallCalled = false
    var getProductAnalysisStatusCallCalled = false
    var reportProductBackInStockCalled = false

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
