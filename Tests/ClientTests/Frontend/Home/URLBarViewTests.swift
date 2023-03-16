// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import XCTest

class URLBarViewTests: XCTestCase {
    
    var profile: MockProfile!

    override func setUp() {
        super.setUp()
        profile = MockProfile()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
    }

    override func tearDown() {
        super.tearDown()
        profile = nil
    }

    func testURLBarView_presentsStandardSearchIcon_onURLBarDefaultState() {
        let sut = makeSUT()
        sut.loadView()
        sut.addSubviews()
        sut.urlBar(sut.urlBar, didEnterText: "")
        
        XCTAssertTrue(sut.urlBar.isPrivate == false)
        
        XCTAssertTrue(sut.urlBar.searchIconImageView.image?.pngData() == UIImage(named: "search")?.pngData())
    }
    
    func testURLBarView_presentsSearchLogoIcon_onURLBarSearchState() {
        let sut = makeSUT()
        sut.loadView()
        sut.addSubviews()
        sut.urlBar.inOverlayMode = true
        sut.urlBar(sut.urlBar, didEnterText: "")

        XCTAssertTrue(sut.urlBar.isPrivate == false)
        
        XCTAssertTrue(sut.urlBar.searchIconImageView.image?.pngData() == UIImage(themed: "searchLogo")?.pngData())
    }
    
    func testURLBarView_presentsPrivateSearchIcon_onURLBarPrivateSeachState() {
        let sut = makeSUT()
        sut.loadView()
        sut.addSubviews()
        sut.urlBar.applyUIMode(isPrivate: true)
        sut.urlBar.inOverlayMode = true
        sut.urlBar(sut.urlBar, didEnterText: "")
        
        XCTAssertTrue(sut.urlBar.isPrivate == true)
        
        XCTAssertTrue(sut.urlBar.searchIconImageView.image?.pngData() == UIImage(named: ImageIdentifiers.newPrivateTab)?.pngData())
    }
}

extension URLBarViewTests {
    
    private func makeSUT() -> BrowserViewController {
        let tabManager = TabManager(profile: profile, imageStore: nil)
        return BrowserViewController(profile: profile, tabManager: tabManager)
    }
    
}
