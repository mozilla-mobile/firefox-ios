// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class FakespotViewModelTests: XCTestCase {
//    var client: MockShoppingProduct!
//    var apiClient: TestFakespotClient!
//    var productAdsCache: ProductAdsCache!
//
//    override func setUp() {
//        super.setUp()
//        DependencyHelperMock().bootstrapDependencies()
//        apiClient = TestFakespotClient()
//        client = MockShoppingProduct(url: URL(string: "https://www.example.com")!, client: apiClient)
//        productAdsCache = .shared
//    }
//
//    override func tearDown() {
//        super.tearDown()
//        client = nil
//        apiClient = nil
//        productAdsCache = nil
//    }
//
//    // Mock ShoppingProduct for testing
//    class MockShoppingProduct: ShoppingProduct {
//        var shouldThrowError = false
//        var isEmptyAdsResponse = false
//        // Mocked ads data for testing
//        let ads = [
//            ProductAdsResponse(
//                name: "Mocked Ads",
//                url: URL(string: "https://mocked-ads.com")!,
//                imageUrl: URL(string: "https://mocked-ads.com/image.jpg")!,
//                price: "29.99",
//                currency: "USD",
//                grade: .a,
//                adjustedRating: 4.8,
//                analysisUrl: URL(string: "https://mocked-as.com/analysis")!,
//                sponsored: true,
//                aid: "mocked123"
//            )
//        ]
//
//        override func fetchProductAnalysisData(
//            maxRetries: Int = 3,
//            retryTimeout: Int = 100
//        ) async throws -> ProductAnalysisResponse? {
//            if shouldThrowError {
//                throw NSError(domain: "MockErrorDomain", code: 123, userInfo: nil)
//            }
//            return .empty
//        }
//
//        override func fetchProductAdsData() async -> [ProductAdsResponse] {
//            isEmptyAdsResponse ? [] : ads
//        }
//    }
//
//    func testLoadProductsAds_FromCache() async {
//        let viewModel = FakespotViewModel(shoppingProduct: client, tabManager: MockTabManager())
//        let ads = [ProductAdsResponse(
//            name: "Cached Ad",
//            url: URL(string: "https://cached-ad.com")!,
//            imageUrl: URL(string: "https://cached-ad.com/image.jpg")!,
//            price: "29.99",
//            currency: "USD",
//            grade: .d,
//            adjustedRating: 4.2,
//            analysisUrl: URL(string: "https://cached-ad.com/analysis")!,
//            sponsored: false,
//            aid: "cached456")
//        ]
//
//        await productAdsCache.cacheAds(ads, forKey: "testProductId")
//        let cachedAds = await viewModel.loadProductAds(for: "testProductId")
//        XCTAssertEqual(cachedAds, ads, "Should load cached ads")
//    }
//
//    func testLoadProductsAds_ProductIdIsNil() async {
//        let viewModel = FakespotViewModel(shoppingProduct: client, tabManager: MockTabManager())
//        let newAds = await viewModel.loadProductAds(for: nil)
//        XCTAssertEqual(newAds, client.ads, "Should load new ads from server")
//    }
//
//    func testLoadProductsAds_EmptyProductAdsResponse() async {
//        client.isEmptyAdsResponse = true
//        let viewModel = FakespotViewModel(shoppingProduct: client, tabManager: MockTabManager())
//        let newAds = await viewModel.loadProductAds(for: "testProductId")
//        XCTAssertEqual(newAds, [], "Should load new ads from server")
//        let cachedAds = await productAdsCache.getCachedAds(forKey: "testProductId")
//        XCTAssertNil(cachedAds)
//    }
//
//    func testLoadProductsAds_LoadingAndCaching() async {
//        let viewModel = FakespotViewModel(shoppingProduct: client, tabManager: MockTabManager())
//        let ads = [ProductAdsResponse(
//            name: "Cached Ad",
//            url: URL(string: "https://cached-ad.com")!,
//            imageUrl: URL(string: "https://cached-ad.com/image.jpg")!,
//            price: "29.99",
//            currency: "USD",
//            grade: .d,
//            adjustedRating: 4.2,
//            analysisUrl: URL(string: "https://cached-ad.com/analysis")!,
//            sponsored: false,
//            aid: "cached456")
//        ]
//
//        await productAdsCache.cacheAds(ads, forKey: "testProductId")
//        let cachedAds = await viewModel.loadProductAds(for: "testProductId")
//        XCTAssertEqual(cachedAds, ads, "Should load cached ads")
//        await productAdsCache.clearCache()
//        let newAds = await viewModel.loadProductAds(for: "testProductId2")
//        let newCachedAds = await viewModel.loadProductAds(for: "testProductId2")
//        XCTAssertEqual(newAds, client.ads, "Should load new ads")
//        XCTAssertEqual(newCachedAds, client.ads, "Should cache new ads")
//    }
//
//    func testFetchDataSuccess() async throws {
//        client.shouldThrowError = false
//        let viewModel = FakespotViewModel(shoppingProduct: client, tabManager: MockTabManager())
//
//        await viewModel.fetchProductAnalysis()
//        switch viewModel.state {
//        case .loaded(let data):
//            XCTAssertNotNil(data.product)
//        default:
//            XCTFail("Unexpected state")
//        }
//    }
//
//    func testFetchDataFailure() async throws {
//        client.shouldThrowError = true
//        let viewModel = FakespotViewModel(shoppingProduct: client, tabManager: MockTabManager())
//
//        await viewModel.fetchProductAnalysis()
//        switch viewModel.state {
//        case .error(let error):
//            XCTAssertNotNil(error)
//        default:
//            XCTFail("Unexpected state")
//        }
//    }
}
