// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
import Common
@testable import Client

final class FakespotOptInCardViewModelTests: XCTestCase {
    private var viewModel: FakespotOptInCardViewModel!
    private var mockProfile: MockProfile!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        viewModel = FakespotOptInCardViewModel()
    }

    override func tearDown() {
        super.tearDown()
        viewModel = nil
        mockProfile = nil
    }

    func testGetWebsites() {
        viewModel.productSitename = "bestbuy"
        var websites = FakespotOptInCardViewModel.PartnerWebsite.orderWebsites(for: viewModel.productSitename)
        XCTAssertEqual(websites[0], "Best Buy")

        viewModel.productSitename = "amazon"
        websites = FakespotOptInCardViewModel.PartnerWebsite.orderWebsites(for: viewModel.productSitename)
        XCTAssertEqual(websites[0], FakespotOptInCardViewModel.PartnerWebsite.amazon.rawValue.capitalized)

        viewModel.productSitename = "walmart"
        websites = FakespotOptInCardViewModel.PartnerWebsite.orderWebsites(for: viewModel.productSitename)
        XCTAssertEqual(websites[0], FakespotOptInCardViewModel.PartnerWebsite.walmart.rawValue.capitalized)

        viewModel.productSitename = "randomShop"
        websites = FakespotOptInCardViewModel.PartnerWebsite.orderWebsites(for: viewModel.productSitename)
        XCTAssertEqual(websites[0], FakespotOptInCardViewModel.PartnerWebsite.amazon.rawValue.capitalized) // as "Amazon" is the default
    }
}
