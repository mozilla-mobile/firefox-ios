//
// Created by Michael Pace on 5/5/22.
// Copyright (c) 2022 Mozilla. All rights reserved.
//

@testable import Client
import XCTest
import WebKit

class FirefoxHomeJumpBackInViewModelTests: XCTestCase {
    var subject: FirefoxHomeJumpBackInViewModel!

    var mockBrowserProfile: MockBrowserProfile!
    var mockTabManager: MockTabManager!
    var mockBrowserBarViewDelegate: MockBrowserBarViewDelegate!

    var stubBrowserViewController: BrowserViewController!

    override func setUp() {
        super.setUp()

        guard let appDelegate = UIApplication.shared.delegate as? TestAppDelegate else {
            fatalError("Unable to set BrowserViewController")
        }

        // TODO: Inject BrowserViewController into FirefoxHomeJumpBackInViewModel
        mockBrowserProfile = MockBrowserProfile(
                localName: "",
                syncDelegate: nil,
                clear: false
        )
        mockTabManager = MockTabManager()
        stubBrowserViewController = BrowserViewController(
                profile: mockBrowserProfile,
                tabManager: TabManager(profile: mockBrowserProfile, imageStore: nil)
        )
        mockBrowserBarViewDelegate = MockBrowserBarViewDelegate()

        subject = FirefoxHomeJumpBackInViewModel(
                isZeroSearch: false,
                profile: mockBrowserProfile,
                isPrivate: false,
                tabManager: mockTabManager
        )
        subject.browserBarViewDelegate = mockBrowserBarViewDelegate
    }

    func test_switchToGroup_noBrowserDelegate_doNothing() {
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [], timestamp: 0)
        subject.browserBarViewDelegate = nil
        var completionDidRun = false
        subject.onTapGroup = { tab in
            completionDidRun = true
        }

        subject.switchTo(group: group)

        XCTAssertEqual(mockBrowserBarViewDelegate.leaveOverlayModeCount, 0)
        XCTAssertFalse(completionDidRun)
    }

    func test_switchToGroup_inOverlayMode_noGroupedItems_doNothing() {
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [], timestamp: 0)
        mockBrowserBarViewDelegate.inOverlayMode = true
        var completionDidRun = false
        subject.onTapGroup = { tab in
            completionDidRun = true
        }

        subject.switchTo(group: group)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertFalse(completionDidRun)
    }

    func test_switchToGroup_inOverlayMode_callCompletionOnFirstGroupedItem() {
        let expectedTab = Tab(bvc: stubBrowserViewController, configuration: WKWebViewConfiguration())
        let group = ASGroup<Tab>(searchTerm: "", groupedItems: [expectedTab], timestamp: 0)
        mockBrowserBarViewDelegate.inOverlayMode = true
        var receivedTab: Tab?
        subject.onTapGroup = { tab in
            receivedTab = tab
        }

        subject.switchTo(group: group)

        XCTAssertTrue(mockBrowserBarViewDelegate.inOverlayMode)
        XCTAssertEqual(expectedTab, receivedTab)
    }
}

class MockTabManager: MozillaTabManager {
    private(set) var recentlyAccessedNormalTabs: [Tab] = []

    func selectTab(_ tab: Tab?, previous: Tab?) {}
}

class MockBrowserViewController: BrowserViewController {}

class MockBrowserBarViewDelegate: BrowserBarViewDelegate {
    var inOverlayMode = false

    var leaveOverlayModeCount = 0

    func leaveOverlayMode(didCancel cancel: Bool) {
        leaveOverlayModeCount += 1
    }
}