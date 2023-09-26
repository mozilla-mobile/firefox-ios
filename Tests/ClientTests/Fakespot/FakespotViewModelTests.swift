// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class FakespotViewModelTests: XCTestCase {
    var client: MockShoppingProduct!
    var apiClient: TestFakespotClient!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        apiClient = TestFakespotClient()
        client = MockShoppingProduct(url: URL(string: "https://www.example.com")!, client: apiClient)
    }

    override func tearDown() {
        super.tearDown()
        client = nil
        apiClient = nil
    }

    // Mock ShoppingProduct for testing
    class MockShoppingProduct: ShoppingProduct {
        var shouldThrowError = false

        override func fetchProductAnalysisData(maxRetries: Int = 3, retryTimeout: Int = 100) async throws -> ProductAnalysisData? {
            if shouldThrowError {
                throw NSError(domain: "MockErrorDomain", code: 123, userInfo: nil)
            }
            return .empty
        }
    }

    func testFetchDataSuccess() async throws {
        client.shouldThrowError = false
        let viewModel = FakespotViewModel(shoppingProduct: client)

        await viewModel.fetchData()
        switch viewModel.state {
        case .loaded(let data):
            XCTAssertNotNil(data)
        default:
            XCTFail("Unexpected state")
        }
    }

    func testFetchDataFailure() async throws {
        client.shouldThrowError = true
        let viewModel = FakespotViewModel(shoppingProduct: client)

        await viewModel.fetchData()
        switch viewModel.state {
        case .error(let error):
            XCTAssertNotNil(error)
        default:
            XCTFail("Unexpected state")
        }
    }
}
