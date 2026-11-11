// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import TestKit
import UIKit
import XCTest

@MainActor
final class QuickAnswersReturnPillViewTests: XCTestCase {
    private var tapMinimizedStates: [Bool] = []
    private var swipeAwayCallCount = 0
    private let question = "How tall is Mount Everest?"
    private let subtitle = "Tap to return"
    private let identifier = "QuickAnswers.returnPill"
    private let minimizedSize: CGFloat = 28.0
    private let expandedHeight: CGFloat = 47.0

    override func setUp() async throws {
        try await super.setUp()
        tapMinimizedStates = []
        swipeAwayCallCount = 0
    }

    override func tearDown() async throws {
        tapMinimizedStates = []
        swipeAwayCallCount = 0
        try await super.tearDown()
    }

    // MARK: - configure
    func test_configure_setsAccessibilityLabelAndHint() {
        let subject = createSubject()

        XCTAssertEqual(subject.accessibilityLabel, question)
        XCTAssertEqual(subject.accessibilityHint, subtitle)
    }

    // MARK: - init
    func test_init_setsInjectedAccessibilityIdentifier() {
        let subject = createSubject()

        XCTAssertEqual(subject.accessibilityIdentifier, identifier)
    }

    // MARK: - accessibilityPerformEscape
    func test_accessibilityPerformEscape_callsOnSwipeAway() {
        let subject = createSubject()

        let handled = subject.accessibilityPerformEscape()

        XCTAssertTrue(handled)
        XCTAssertEqual(swipeAwayCallCount, 1)
    }

    // MARK: - accessibilityActivate
    func test_accessibilityActivate_callsOnTapWithMinimizedState() {
        let subject = createSubject()

        _ = subject.accessibilityActivate()
        subject.setMinimized(true, animated: false)
        _ = subject.accessibilityActivate()

        XCTAssertEqual(tapMinimizedStates, [false, true])
    }

    // MARK: - setMinimized
    func test_setMinimized_true_shrinksToMinimizedSize() {
        let subject = createSubject()

        subject.setMinimized(true, animated: false)

        XCTAssertTrue(subject.isMinimized)
        XCTAssertEqual(fittingSize(of: subject), CGSize(width: minimizedSize, height: minimizedSize))
    }

    func test_setMinimized_falseAfterTrue_restoresExpandedSize() {
        let subject = createSubject()
        subject.setMinimized(true, animated: false)

        subject.setMinimized(false, animated: false)

        XCTAssertFalse(subject.isMinimized)
        XCTAssertEqual(fittingSize(of: subject).height, expandedHeight)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #filePath, line: UInt = #line) -> QuickAnswersReturnPillView {
        let subject = QuickAnswersReturnPillView(
            accessibilityIdentifier: identifier,
            onTap: { [weak self] isMinimized in self?.tapMinimizedStates.append(isMinimized) },
            onSwipeAway: { [weak self] in self?.swipeAwayCallCount += 1 }
        )
        subject.configure(question: question, subtitle: subtitle)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func fittingSize(of subject: QuickAnswersReturnPillView) -> CGSize {
        return subject.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
}
