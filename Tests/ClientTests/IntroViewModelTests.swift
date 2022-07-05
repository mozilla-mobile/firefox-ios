// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client

class IntroViewModelTests: XCTestCase {

    var viewModel: IntroViewModel!

    override func setUp() {
        viewModel = IntroViewModel()
    }

    override func tearDown() {
        viewModel = nil
    }

    func testGetWelcomeViewModel() {
        let cardType = viewModel.getCardViewModel(index: 0).cardType
        XCTAssertTrue(cardType == IntroViewModel.OnboardingCards.welcome)
    }

    func testGetWallpaperViewModel() {
        let cardType = viewModel.getCardViewModel(index: 1).cardType
        XCTAssertTrue(cardType == IntroViewModel.OnboardingCards.wallpapers)
    }

    func testGetSyncViewModel() {
        let cardType = viewModel.getCardViewModel(index: 2).cardType
        XCTAssertTrue(cardType == IntroViewModel.OnboardingCards.signSync)
    }

    func testNextIndexAfterLastCard() {
        let index = viewModel.getNextIndex(currentIndex: 2, goForward: true)
        XCTAssertNil(index)
    }

    func testNextIndexBeforeFirstCard() {
        let index = viewModel.getNextIndex(currentIndex: 0, goForward: false)
        XCTAssertNil(index)
    }
}
