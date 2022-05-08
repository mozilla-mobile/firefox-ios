//
// Created by Michael Pace on 5/5/22.
// Copyright (c) 2022 Mozilla. All rights reserved.
//

@testable import Client
import XCTest

class FirefoxHomeJumpBackInViewModelTests: XCTestCase {
    var subject: FirefoxHomeJumpBackInViewModel!
    
    var mockBrowserProfile: MockBrowserProfile!
    var mockTabManager: MockTabManager!

    override func setUp() {
        super.setUp()

        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("Unable to set BrowserViewController")
        }

        // TODO: Inject BrowserViewController into FirefoxHomeJumpBackInViewModel
        mockBrowserProfile = MockBrowserProfile(
                localName: "",
                syncDelegate: nil,
                clear: false
        )
        mockTabManager = MockTabManager()
        appDelegate.browserViewController = BrowserViewController(
                profile: mockBrowserProfile,
                tabManager: TabManager(profile: mockBrowserProfile, imageStore: nil)
        )

        subject = FirefoxHomeJumpBackInViewModel(
                isZeroSearch: false,
                profile: mockBrowserProfile,
                isPrivate: false,
                tabManager: mockTabManager
        )
    }

    func test_switchToGroup_() {
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [], timestamp: 0)
        var completionDidRun = false
        
        subject.onTapGroup = { tab in
            completionDidRun = true
        }

        subject.switchTo(group: group)
        
        XCTAssertTrue(completionDidRun)
    }
}

class MockTabManager: MozillaTabManager {
    private(set) var recentlyAccessedNormalTabs: [Tab] = []
    
    func selectTab(_ tab: Tab?, previous: Tab?) {}
}

class MockBrowserViewController: BrowserViewController {

}