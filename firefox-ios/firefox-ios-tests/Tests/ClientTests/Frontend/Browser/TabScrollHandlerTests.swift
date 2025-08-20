// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
import Common
import Shared

@testable import Client

@MainActor
final class TabScrollHandlerTests: XCTestCase {
    var tab: Tab!
    var mockProfile: MockProfile!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()

        DependencyHelperMock().bootstrapDependencies()
        mockProfile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: mockProfile)
        tab = Tab(profile: mockProfile, windowUUID: windowUUID)
    }

    override func tearDown() {
        mockProfile?.shutdown()
        mockProfile = nil
        tab = nil
        super.tearDown()
    }

    func testHandlePan_ScrollingUpWithTranslation() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let translation = CGPoint(x: 0, y: -100)
        let velocity = CGPoint(x: 10, y: 10)
        subject.handleScroll(for: translation, velocity: velocity)
        XCTAssertEqual(subject.toolbarDisplayState, .collapsed)
    }

    func testHandlePan_ScrollingDownWithTranslation() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let translation = CGPoint(x: 0, y: 100)
        let velocity = CGPoint(x: 10, y: 10)
        subject.handleScroll(for: translation, velocity: velocity)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)
        XCTAssertEqual(subject.toolbarDisplayState, .expanded)
    }

    func testHandlePan_ScrollingUpWithVelocity() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let translation = CGPoint(x: 0, y: -10)
        let velocity = CGPoint(x: 10, y: 110)
        subject.handleScroll(for: translation, velocity: velocity)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)
        XCTAssertEqual(subject.toolbarDisplayState, .collapsed)
    }

    func testHandlePan_ScrollingDownWithVelocity() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let translation = CGPoint(x: 0, y: 10)
        let velocity = CGPoint(x: 10, y: 110)
        subject.handleScroll(for: translation, velocity: velocity)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)
        XCTAssertEqual(subject.toolbarDisplayState, .expanded)
    }

    func testHandlePan_ToolbarVisible_ScrollingUp() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let translation = CGPoint(x: 0, y: 10)
        let velocity = CGPoint(x: 10, y: 10)
        subject.handleScroll(for: translation, velocity: velocity)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)
        XCTAssertEqual(subject.toolbarDisplayState, .expanded)
    }

    func testHandlePan_ToolbarVisible_ScrollingDown() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        let translation = CGPoint(x: 0, y: -10)
        let velocity = CGPoint(x: 10, y: 10)
        subject.handleScroll(for: translation, velocity: velocity)
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)
        XCTAssertEqual(subject.toolbarDisplayState, .expanded)
    }

    func testShowToolbar_AfterHidingWithScroll() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        // Hide toolbar
        let translation = CGPoint(x: 0, y: 100)
        let velocity = CGPoint(x: 10, y: 80)
        subject.handleScroll(for: translation, velocity: velocity)

        // Force call to showToolbars like clicking on top bar area
        subject.showToolbars(animated: true)
        XCTAssertEqual(subject.toolbarDisplayState, .expanded)
    }

    func testShouldScrollToTop_AfterHidingBar() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        guard let scrollView = tab.webView?.scrollView else {
            return XCTFail("Could not find scrollview")
        }

        // Hide toolbar
        let translation = CGPoint(x: 0, y: 100)
        let velocity = CGPoint(x: 10, y: 80)
        subject.handleScroll(for: translation, velocity: velocity)
        XCTAssertTrue(subject.scrollViewShouldScrollToTop(scrollView))
        subject.scrollViewDidEndDragging(tab.webView!.scrollView, willDecelerate: true)
        XCTAssertEqual(subject.toolbarDisplayState, .expanded)
    }

    func testToolbarDisplayState_TransitioningFromCollapsed() {
        let subject = createSubject()
        setupTabScroll(with: subject)

        subject.hideToolbars(animated: true)
        XCTAssertEqual(subject.toolbarDisplayState, .collapsed)

        let translation = CGPoint(x: 0, y: -30)
        let velocity = CGPoint(x: 0, y: 110)
        subject.handleScroll(for: translation, velocity: velocity)

        XCTAssertEqual(subject.toolbarDisplayState, .transitioning)
    }

    // MARK: - Setup
    private func setupTabScroll(with subject: TabScrollHandler) {
        tab.createWebview(configuration: .init())
        tab.webView?.scrollView.frame.size = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.contentSize = CGSize(width: 200, height: 2000)
        tab.webView?.scrollView.delegate = subject
        subject.tab = tab
    }

    private func createSubject() -> TabScrollHandler {
        let subject = TabScrollHandler(windowUUID: .XCTestDefaultUUID)

        let header: BaseAlphaStackView = .build()
        let overKeyboardContainer: BaseAlphaStackView = .build()
        let bottomContainer: BaseAlphaStackView = .build()

        overKeyboardContainer.frame = CGRect(x: 0, y: 0, width: 200, height: 100)

        subject.configureToolbarViews(overKeyboardContainer: overKeyboardContainer,
                                      bottomContainer: bottomContainer,
                                      headerContainer: header)
        trackForMemoryLeaks(subject)
        return subject
    }
}
