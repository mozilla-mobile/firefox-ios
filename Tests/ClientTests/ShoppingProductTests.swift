// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

final class ShoppingProductTests: XCTestCase {
<<<<<<< HEAD
=======
    var client: TestFakeSpotClient!

    override func setUp() {
        super.setUp()
        client = TestFakeSpotClient()
    }

    override func tearDown() {
        super.tearDown()
        client = nil
    }

>>>>>>> ba45c54d3 (Bugfix FXIOS-7066 [v117] customize homepage done button (#15853))
    func testAmazonURL_returnsExpectedProduct() {
        let url = URL(string: "https://www.amazon.com/Under-Armour-Charged-Assert-Running/dp/B087T8Q2C4")!

        let sut = ShoppingProduct(url: url)
        let expected = Product(id: "B087T8Q2C4", host: "amazon.com", topLevelDomain: "com", sitename: "amazon")

        XCTAssertEqual(sut.product, expected)
    }

    func testBestBuyURL_returnsExpectedProduct() {
        let url = URL(string: "https://www.bestbuy.com/site/macbook-air-13-3-laptop-apple-m1-chip-8gb-memory-256gb-ssd-space-gray/5721600.p?skuId=5721600")!

        let sut = ShoppingProduct(url: url)
        let expected = Product(id: "5721600.p", host: "bestbuy.com", topLevelDomain: "com", sitename: "bestbuy")

        XCTAssertEqual(sut.product, expected)
    }

    func testBasicURL_returnsNilProduct() {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url)

        XCTAssertNil(sut.product)
    }

    func testBasicURL_hidesShoppingIcon() {
        let url = URL(string: "https://www.example.com")!

        let sut = ShoppingProduct(url: url)

        XCTAssertFalse(sut.isShoppingCartButtonVisible)
    }
}
