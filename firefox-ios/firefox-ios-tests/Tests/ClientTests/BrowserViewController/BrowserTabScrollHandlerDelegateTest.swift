// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices
import Storage
import XCTest
import Glean
import Common
import Shared

@testable import Client

@MainActor
final class BrowserTabScrollHandlerDelegateTest: BrowserViewControllerConstraintTestsBase {
    private let minimalHeaderOffset = BrowserViewController.UX.minimalHeaderOffset

    // MARK: - Top Toolbar

    func testHideToolbar_TopToolbar_headerMovesUp() {
        let subject = createSubject(isBottomSearchBar: false)
        subject.setupToolbarAnimator()

        let initialHeaderFrame = subject.header.frame

        subject.hideToolbar()

        // Current Y position should be less than initial position, the offset should be
        // the height plus UX.minimalHeaderOffset
        let minimalHeaderOffset = (initialHeaderFrame.minY - initialHeaderFrame.height) + minimalHeaderOffset
        XCTAssertLessThan(subject.header.frame.minY, initialHeaderFrame.minY)
        XCTAssertEqual(subject.header.frame.minY, minimalHeaderOffset)
    }

    func testShowToolbar_TopToolbar_afterHide_restoresHeaderPosition() {
        let subject = createSubject(isBottomSearchBar: false)
        subject.setupToolbarAnimator()
        let initialHeaderMinY = subject.header.frame.minY

        subject.hideToolbar()
        subject.showToolbar()

        XCTAssertEqual(subject.header.frame.minY, initialHeaderMinY)
    }

    // MARK: - Top Toolbar Transition

    func testUpdateToolbarTransition_TopToolbar_collapsing_movesHeaderUp() {
        let subject = createSubject(isBottomSearchBar: false)
        subject.setupToolbarAnimator()
        let initialHeaderMinY = subject.header.frame.minY

        subject.updateToolbarTransition(progress: 20, towards: .collapsed)

        XCTAssertLessThan(subject.header.frame.minY, initialHeaderMinY)
    }

    func testUpdateToolbarTransition_TopToolbar_expanding_resetsTransform() {
        let subject = createSubject(isBottomSearchBar: false)
        subject.setupToolbarAnimator()
        subject.updateToolbarTransition(progress: 20, towards: .collapsed)

        subject.updateToolbarTransition(progress: 0, towards: .expanded)

        XCTAssertEqual(subject.header.transform, .identity)
    }

    // MARK: - Top Toolbar + Reader Mode

    func testHideToolbar_ReaderModeActive_headerMovesUp() {
        let subject = createSubject(isBottomSearchBar: false)
        selectReaderModeTab()
        subject.setupToolbarAnimator()
        let initialHeaderFrame = subject.header.frame

        subject.hideToolbar()

        // Current Y position should be less than initial position, the offset should be the height
        let minimalHeaderOffset = initialHeaderFrame.minY - initialHeaderFrame.height
        XCTAssertLessThan(subject.header.frame.minY, initialHeaderFrame.minY)
        XCTAssertEqual(subject.header.frame.minY, minimalHeaderOffset)
    }

    func testShowToolbar_ReaderModeActive_afterHide_restoresHeaderPosition() {
        let subject = createSubject(isBottomSearchBar: false)
        selectReaderModeTab()
        subject.setupToolbarAnimator()
        let initialHeaderMinY = subject.header.frame.minY

        subject.hideToolbar()
        subject.showToolbar()

        XCTAssertEqual(subject.header.frame.minY, initialHeaderMinY)
    }

    // MARK: - Bottom Search Bar

    func testHideToolbar_BottomSearchBar_overKeyboardContainerMovesDown() {
        let subject = createSubject()
        guard subject.overKeyboardContainer.frame.height > 0 else { return }
        let initialMinY = subject.overKeyboardContainer.frame.minY

        setupAnimator(for: subject, overKeyboardContainerHeight: subject.overKeyboardContainer.frame.height)
        subject.toolbarAnimator?.hideToolbar()

        XCTAssertGreaterThan(subject.overKeyboardContainer.frame.minY, initialMinY)
    }

    func testShowToolbar_BottomSearchBar_afterHide_restoresOverKeyboardPosition() {
        let subject = createSubject()
        guard subject.overKeyboardContainer.frame.height > 0 else { return }
        let initialMinY = subject.overKeyboardContainer.frame.minY

        setupAnimator(for: subject, overKeyboardContainerHeight: subject.overKeyboardContainer.frame.height)
        subject.toolbarAnimator?.hideToolbar()
        subject.toolbarAnimator?.showToolbar()

        XCTAssertEqual(subject.overKeyboardContainer.frame.minY, initialMinY)
    }

    func testHideToolbar_BottomSearchBar_topHeaderDoesNotMove() {
        let subject = createSubject(isBottomSearchBar: true)
        subject.setupToolbarAnimator()
        let initialHeaderMinY = subject.header.frame.minY

        subject.hideToolbar()

        // For Bottom search bar header has height = 0 and should not be animated.
        XCTAssertEqual(subject.header.frame.minY, initialHeaderMinY)
        XCTAssertEqual(subject.header.frame.height, 0)
    }

    // MARK: - Animator Setup

    func testSetupToolbarAnimator_setsViewAndDelegate() {
        let subject = createSubject(isBottomSearchBar: false)

        subject.setupToolbarAnimator()

        XCTAssertNotNil(subject.toolbarAnimator)
        XCTAssertTrue(subject.toolbarAnimator?.view === subject)
    }

    func testSetupToolbarAnimator_calledTwice_replacesAnimator() {
        let subject = createSubject(isBottomSearchBar: false)
        subject.setupToolbarAnimator()
        let firstAnimator = subject.toolbarAnimator

        subject.setupToolbarAnimator()

        XCTAssertFalse(subject.toolbarAnimator === firstAnimator)
    }

    // MARK: - Private

    private func selectReaderModeTab() {
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        tab.url = URL(string: "http://localhost:6571/reader-mode/page?url=https://example.com")
        tabManager.selectedTab = tab
    }

    private func createToolbarAnimator(headerHeight: CGFloat = 60,
                                       bottomContainerHeight: CGFloat = 60,
                                       overKeyboardContainerHeight: CGFloat = 60) -> ToolbarAnimator {
        let context = ToolbarContext(overKeyboardContainerHeight: overKeyboardContainerHeight,
                                     bottomContainerHeight: bottomContainerHeight,
                                     headerHeight: headerHeight)
        return ToolbarAnimator(context: context)
    }

    /// Wires a ToolbarAnimator with an explicit context onto the subject, bypassing
    /// `updateToolbarContext()`. Use this when the calculated context would be 0 in the test environment
    private func setupAnimator(for subject: BrowserViewController,
                               headerHeight: CGFloat = 60,
                               bottomContainerHeight: CGFloat = 60,
                               overKeyboardContainerHeight: CGFloat = 60) {
        let animator = createToolbarAnimator(headerHeight: headerHeight,
                                             bottomContainerHeight: bottomContainerHeight,
                                             overKeyboardContainerHeight: overKeyboardContainerHeight)
        animator.view = subject
        animator.delegate = subject
        subject.toolbarAnimator = animator
    }

    private func setupNimbusTabScrollRefactorTesting(isEnabled: Bool) {
        FxNimbus.shared.features.tabScrollRefactorFeature.with { _, _ in
            return TabScrollRefactorFeature(enabled: isEnabled)
        }
    }
}
