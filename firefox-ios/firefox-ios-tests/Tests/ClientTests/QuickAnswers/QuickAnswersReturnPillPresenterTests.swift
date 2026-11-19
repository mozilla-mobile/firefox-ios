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

    func test_show_addsPill() {
        let subject = createSubject()

        showPill(on: subject)

        XCTAssertNotNil(pill)
    }

    func test_show_calledTwice_keepsOnePill() {
        let subject = createSubject()

        showPill(on: subject)
        showPill(on: subject)

        XCTAssertEqual(pills.count, 1)
    }

    // MARK: - hide

    func test_hide_removesPill() {
        let subject = createSubject()
        showPill(on: subject)

        subject.hide()

        XCTAssertNil(pill)
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
}

private final class MockOverlayState: OverlayStateProtocol {
    var inOverlayMode = false
}
