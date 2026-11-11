// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import QuickAnswersKit
import Shared
import XCTest

@testable import Client

@MainActor
final class QuickAnswersReturnPillPresenterTests: XCTestCase {
    private var hostView: UIView!
    private var anchorView: UIView!
    private var overlayState: MockOverlayState!
    private static let defaultLocationViewFrame = CGRect(x: 40, y: 760, width: 200, height: 30)

    override func setUp() async throws {
        try await super.setUp()
        hostView = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        anchorView = UIView()
        anchorView.translatesAutoresizingMaskIntoConstraints = false
        hostView.addSubview(anchorView)
        overlayState = MockOverlayState()
    }

    override func tearDown() async throws {
        hostView = nil
        anchorView = nil
        overlayState = nil
        try await super.tearDown()
    }

    // MARK: - show

    func test_show_addsPillWithExpandedConstraints() {
        let subject = createSubject()

        showPill(on: subject)

        XCTAssertNotNil(pill)
        XCTAssertEqual(activeAttributes(), [.bottom, .centerX, .leading])
        let bottomConstraint = activeConstraint(for: .bottom)
        XCTAssertTrue(bottomConstraint?.secondItem === anchorView)
        XCTAssertEqual(bottomConstraint?.secondAttribute, .top)
    }

    func test_show_calledTwice_keepsOnePill() {
        let subject = createSubject()

        showPill(on: subject)
        showPill(on: subject)

        XCTAssertEqual(pills.count, 1)
        XCTAssertEqual(activeConstraints().count, 3)
    }

    // MARK: - hide

    func test_hide_removesPillAndConstraints() {
        let subject = createSubject()
        showPill(on: subject)
        let shownPill = pill

        subject.hide()

        XCTAssertNil(pill)
        XCTAssertTrue(hostView.constraints.filter { $0.firstItem === shownPill }.isEmpty)
    }

    func test_hide_withoutPill_doesNothing() {
        let subject = createSubject()

        subject.hide()

        XCTAssertNil(pill)
    }

    func test_show_afterHide_addsNewPill() {
        let subject = createSubject()
        showPill(on: subject)
        subject.hide()

        showPill(on: subject)

        XCTAssertEqual(pills.count, 1)
        XCTAssertEqual(activeAttributes(), [.bottom, .centerX, .leading])
    }

    // MARK: - updateLayout

    func test_updateLayout_notMinimized_keepsExpandedConstraints() {
        let subject = createSubject()
        showPill(on: subject)

        subject.updateLayout(layoutContext(isMinimized: false), animated: false)

        XCTAssertEqual(activeAttributes(), [.bottom, .centerX, .leading])
    }

    func test_updateLayout_minimizedBottomSearchBar_followsLocationView() {
        let subject = createSubject()
        showPill(on: subject)

        subject.updateLayout(layoutContext(isMinimized: true), animated: false)

        XCTAssertEqual(activeAttributes(), [.centerY, .leading])
        XCTAssertEqual(activeConstraint(for: .centerY)?.constant, Self.defaultLocationViewFrame.midY)
        XCTAssertGreaterThan(activeConstraint(for: .leading)?.constant ?? 0, Self.defaultLocationViewFrame.maxX)
    }

    func test_updateLayout_minimizedBottomSearchBarWithoutFrame_centersAtBottom() {
        let subject = createSubject()
        showPill(on: subject)

        subject.updateLayout(layoutContext(isMinimized: true, locationViewFrame: nil), animated: false)

        XCTAssertEqual(activeAttributes(), [.centerX, .bottom])
    }

    func test_updateLayout_minimizedTopSearchBar_centersAtBottom() {
        let subject = createSubject()
        showPill(on: subject)

        subject.updateLayout(layoutContext(isMinimized: true, isBottomSearchBar: false), animated: false)

        XCTAssertEqual(activeAttributes(), [.centerX, .bottom])
    }

    func test_updateLayout_minimizedThenExpanded_restoresExpandedConstraints() {
        let subject = createSubject()
        showPill(on: subject)
        subject.updateLayout(layoutContext(isMinimized: true), animated: false)

        subject.updateLayout(layoutContext(isMinimized: false), animated: false)

        XCTAssertEqual(activeAttributes(), [.bottom, .centerX, .leading])
    }

    func test_updateLayout_changedLocationViewFrame_rebuildsConstraintsWithNewConstants() {
        let subject = createSubject()
        showPill(on: subject)
        subject.updateLayout(layoutContext(isMinimized: true), animated: false)
        let newFrame = CGRect(x: 60, y: 700, width: 220, height: 30)

        subject.updateLayout(layoutContext(isMinimized: true, locationViewFrame: newFrame), animated: false)

        XCTAssertEqual(activeConstraints().count, 2)
        XCTAssertEqual(activeConstraint(for: .centerY)?.constant, newFrame.midY)
    }

    func test_updateLayout_sameContextTwice_keepsSameConstraints() {
        let subject = createSubject()
        showPill(on: subject)
        subject.updateLayout(layoutContext(isMinimized: true), animated: false)
        let constraints = activeConstraints()

        subject.updateLayout(layoutContext(isMinimized: true), animated: false)

        let updatedConstraints = activeConstraints()
        XCTAssertEqual(updatedConstraints.count, constraints.count)
        XCTAssertTrue(zip(constraints, updatedConstraints).allSatisfy { $0 === $1 })
    }

    func test_updateLayout_withoutPill_doesNotAddConstraints() {
        let subject = createSubject()

        subject.updateLayout(layoutContext(isMinimized: true), animated: false)

        XCTAssertTrue(activeConstraints().isEmpty)
    }

    // MARK: - updateVisibility

    func test_updateVisibility_withToast_hidesPill() {
        let subject = createSubject()
        showPill(on: subject)
        hostView.addSubview(Toast(frame: .zero))

        subject.updateVisibility()

        XCTAssertFalse(pill?.isUserInteractionEnabled ?? true)
    }

    func test_updateVisibility_afterToastRemoved_showsPill() {
        let subject = createSubject()
        showPill(on: subject)
        let toast = Toast(frame: .zero)
        hostView.addSubview(toast)
        subject.updateVisibility()

        toast.removeFromSuperview()
        subject.updateVisibility()

        XCTAssertTrue(pill?.isUserInteractionEnabled ?? false)
    }

    func test_updateVisibility_inOverlayMode_hidesPill() {
        let subject = createSubject()
        showPill(on: subject)
        overlayState.inOverlayMode = true

        subject.updateVisibility()

        XCTAssertFalse(pill?.isUserInteractionEnabled ?? true)
    }

    func test_updateVisibility_afterLeavingOverlayMode_showsPill() {
        let subject = createSubject()
        showPill(on: subject)
        overlayState.inOverlayMode = true
        subject.updateVisibility()

        overlayState.inOverlayMode = false
        subject.updateVisibility()

        XCTAssertTrue(pill?.isUserInteractionEnabled ?? false)
    }

    // MARK: - bringPillToFront

    func test_bringPillToFront_movesPillAboveSiblings() {
        let subject = createSubject()
        showPill(on: subject)
        hostView.addSubview(UIView())

        subject.bringPillToFront()

        XCTAssertTrue(hostView.subviews.last === pill)
    }

    // MARK: - Helpers

    private var pills: [QuickAnswersReturnPillView] {
        hostView.subviews.compactMap { $0 as? QuickAnswersReturnPillView }
    }

    private var pill: QuickAnswersReturnPillView? {
        pills.first
    }

    private func createSubject() -> QuickAnswersReturnPillPresenter {
        return QuickAnswersReturnPillPresenter(hostView: hostView, anchorView: anchorView, overlayState: overlayState)
    }

    private func showPill(on subject: QuickAnswersReturnPillPresenter, question: String = "Question") {
        subject.show(question: question, theme: LightTheme(), onTap: { _ in }, onSwipeAway: {})
    }

    private func layoutContext(
        isMinimized: Bool,
        isBottomSearchBar: Bool = true,
        locationViewFrame: CGRect? = QuickAnswersReturnPillPresenterTests.defaultLocationViewFrame
    ) -> QuickAnswersReturnPillPresenter.LayoutContext {
        return QuickAnswersReturnPillPresenter.LayoutContext(
            isMinimized: isMinimized,
            isBottomSearchBar: isBottomSearchBar,
            locationViewFrame: locationViewFrame
        )
    }

    private func activeConstraints() -> [NSLayoutConstraint] {
        hostView.constraints.filter { $0.isActive && $0.firstItem === pill }
    }

    private func activeAttributes() -> Set<NSLayoutConstraint.Attribute> {
        Set(activeConstraints().map(\.firstAttribute))
    }

    private func activeConstraint(for attribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        activeConstraints().first { $0.firstAttribute == attribute }
    }
}

private final class MockOverlayState: OverlayStateProtocol {
    var inOverlayMode = false
}
