// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit
import XCTest

final class QuickAnswersReturnPillDragEvaluatorTests: XCTestCase {
    // MARK: - shouldRemove
    func test_shouldRemove_belowBothThresholds_returnsFalse() {
        let shouldRemove = QuickAnswersReturnPillDragEvaluator.shouldRemove(
            translation: CGPoint(x: 30, y: 40),
            velocity: CGPoint(x: 200, y: 300)
        )

        XCTAssertFalse(shouldRemove)
    }

    func test_shouldRemove_atDistanceThreshold_returnsTrue() {
        let shouldRemove = QuickAnswersReturnPillDragEvaluator.shouldRemove(
            translation: CGPoint(x: 0, y: QuickAnswersReturnPillDragEvaluator.removeDistance),
            velocity: .zero
        )

        XCTAssertTrue(shouldRemove)
    }

    func test_shouldRemove_diagonalDistanceOverThreshold_returnsTrue() {
        let shouldRemove = QuickAnswersReturnPillDragEvaluator.shouldRemove(
            translation: CGPoint(x: 70, y: 72),
            velocity: .zero
        )

        XCTAssertTrue(shouldRemove)
    }

    func test_shouldRemove_fastFlingWithSmallDistance_returnsTrue() {
        let shouldRemove = QuickAnswersReturnPillDragEvaluator.shouldRemove(
            translation: CGPoint(x: 5, y: 5),
            velocity: CGPoint(x: 0, y: QuickAnswersReturnPillDragEvaluator.removeVelocity)
        )

        XCTAssertTrue(shouldRemove)
    }
}
