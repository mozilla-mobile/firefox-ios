// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

@MainActor
final class BrowserViewControllerConstraintTests: BrowserViewControllerConstraintTestsBase {
    // MARK: - Container View Existence Tests

    func test_containerViews_existInHierarchy() {
        let subject = createSubject()
        XCTAssertNotNil(subject.header)
        XCTAssertNotNil(subject.overKeyboardContainer)
        XCTAssertNotNil(subject.bottomContainer)
    }

    func test_containerViews_addedToViewHierarchy() {
        let subject = createSubject()
        XCTAssertNotNil(subject.header.superview)
        XCTAssertNotNil(subject.overKeyboardContainer.superview)
        XCTAssertNotNil(subject.bottomContainer.superview)
    }

    // MARK: - Bottom Container Constraints Tests

    func test_bottomContainer_hasLeadingConstraint() {
        let subject = createSubject()
        let hasLeading = hasConstraint(for: subject.bottomContainer,
                                       attribute: .leading,
                                       relatedTo: subject.view)
        let hasTrailing = hasConstraint(for: subject.bottomContainer,
                                        attribute: .trailing,
                                        relatedTo: subject.view)
        XCTAssertTrue(hasLeading)
        XCTAssertTrue(hasTrailing)
    }

    func test_bottomContainer_hasBottomConstraint() {
        let subject = createSubject()
        let hasBottom = hasConstraint(for: subject.bottomContainer,
                                      attribute: .bottom,
                                      relatedTo: subject.view)
        XCTAssertTrue(hasBottom)
    }

    // MARK: - OverKeyboard Container Constraints Tests

    func test_overKeyboardContainer_hasHorizontalConstraints() {
        let subject = createSubject()
        let hasLeading = hasConstraint(for: subject.overKeyboardContainer,
                                       attribute: .leading,
                                       relatedTo: subject.view)
        let hasTrailing = hasConstraint(for: subject.overKeyboardContainer,
                                        attribute: .trailing,
                                        relatedTo: subject.view)

        XCTAssertTrue(hasLeading)
        XCTAssertTrue(hasTrailing)
    }

    func test_overKeyboardContainer_hasBottomConstraintToBottomContainer() {
        let subject = createSubject()

        // Search for sibling constraint between overKeyboardContainer and bottomContainer
        let hasBottomConstraint = hasConstraintBetween(firstView: subject.overKeyboardContainer,
                                                       firstAttribute: .bottom,
                                                       secondView: subject.bottomContainer,
                                                       secondAttribute: .top,
                                                       in: subject.view)
        XCTAssertTrue(hasBottomConstraint)
    }

    // MARK: - Header Constraints Tests

    func test_header_hasHorizontalConstraint_WithSnapKitRefactorDisabled() {
        let subject = createSubject()

        // Header view uses .left and .right instead of .leading and .trailing
        let hasLeft = hasConstraint(for: subject.header,
                                    attribute: .left,
                                    relatedTo: subject.view)

        let hasRight = hasConstraint(for: subject.header,
                                     attribute: .right,
                                     relatedTo: subject.view)
        XCTAssertTrue(hasLeft)
        XCTAssertTrue(hasRight)
    }

    func test_header_hasHorizontalConstraint_WithSnapKitRefactorEnabled() {
        let subject = createSubject(isFeatureFlagEnabled: true)

        // As part of the refactor header view is using .leading and .trailing as the other views
        let hasLeading = hasConstraint(for: subject.header,
                                       attribute: .leading,
                                       relatedTo: subject.view)

        let hasTrailing = hasConstraint(for: subject.header,
                                        attribute: .trailing,
                                        relatedTo: subject.view)
        XCTAssertTrue(hasLeading)
        XCTAssertTrue(hasTrailing)
    }

    func test_header_hasTopConstraint() {
        let subject = createSubject()
        let header = subject.header

        // Search for header top constraint own by the view or its superview
        let hasTopConstraint = header.constraints.contains { $0.firstAttribute == .top } ||
        subject.view.constraints.contains {
            ($0.firstItem === header && $0.firstAttribute == .top) ||
            ($0.secondItem === header && $0.secondAttribute == .top)
        }

        XCTAssertTrue(hasTopConstraint)
    }

    // MARK: - Constraint Count Baseline Tests

    func test_bottomContainer_TopToolbar_constraintCount() {
        let subject = createSubject(isBottomSearchBar: false)
        // Record baseline constraint count for future comparison
        let constraintsCount = countRelevantConstraints(for: subject.bottomContainer)

        XCTAssertEqual(constraintsCount, 3)
    }

    func test_bottomContainer_bottomToolbar_constraintCount() {
        let subject = createSubject()
        // Record baseline constraint count for future comparison
        let constraintsCount = countRelevantConstraints(for: subject.bottomContainer)

        XCTAssertEqual(constraintsCount, 3)
    }

    func test_overKeyboardContainer_topToolbar_constraintCount() {
        let subject = createSubject(isBottomSearchBar: false)
        // Record baseline constraint count for future comparison
        let constraintsCount = countRelevantConstraints(for: subject.overKeyboardContainer)

        XCTAssertEqual(constraintsCount, 1)
    }

    func test_overKeyboardContainer_bottomToolbar_constraintCount() {
        let subject = createSubject()
        // Record baseline constraint count for future comparison
        let constraintsCount = countRelevantConstraints(for: subject.overKeyboardContainer)

        XCTAssertEqual(constraintsCount, 3)
    }

    func test_header_topToolbar_constraintCount() {
        let subject = createSubject(isBottomSearchBar: false)
        // Record baseline constraint count for future comparison
        let constraintsCount = countRelevantConstraints(for: subject.header)

        XCTAssertEqual(constraintsCount, 3)
    }

    func test_header_bottomToolbar_constraintCount() {
        let subject = createSubject()
        // Record baseline constraint count for future comparison
        let constraintsCount = countRelevantConstraints(for: subject.header)

        XCTAssertEqual(constraintsCount, 1)
    }

    // MARK: - Constraint Activation Tests

    func test_allConstraints_areActive() {
        let subject = createSubject()
        let bottomConstraints = subject.bottomContainer.constraints
        let overKeyboardConstraints = subject.overKeyboardContainer.constraints
        let headerConstraints = subject.header.constraints

        let allConstraints = bottomConstraints + overKeyboardConstraints + headerConstraints
        let activeConstraints = allConstraints.filter { $0.isActive }

        XCTAssertEqual(allConstraints.count, activeConstraints.count)
    }

    // MARK: - Layout Pass Tests

    func test_updateViewConstraints_doesNotThrow() {
        let subject = createSubject()
        // Calling updateViewConstraints should not crash
        XCTAssertNoThrow(subject.view.setNeedsUpdateConstraints())
        XCTAssertNoThrow(subject.view.updateConstraintsIfNeeded())
    }

    func test_multipleLayoutPasses_producesConsistentResults() {
        let subject = createSubject(isBottomSearchBar: false)
        // Multiple layout passes should be stable (no constraint conflicts)
        subject.view.layoutIfNeeded()
        let frame1 = subject.bottomContainer.frame

        subject.view.setNeedsLayout()
        subject.view.layoutIfNeeded()
        let frame2 = subject.bottomContainer.frame

        XCTAssertEqual(frame1, frame2)
    }

    // MARK: - Frame/Layout Verification Tests

    func test_bottomContainer_isAtBottomOfScreen() {
        let subject = createSubject(isBottomSearchBar: false)
        subject.view.layoutIfNeeded()

        let bottomContainer = subject.bottomContainer
        let viewBottom = subject.view.bounds.maxY
        let containerBottom = bottomContainer.frame.maxY

        XCTAssertEqual(containerBottom, viewBottom, accuracy: 1.0)
    }

    func test_overKeyboardContainer_isAboveBottomContainer() {
        let subject = createSubject()
        subject.view.layoutIfNeeded()

        let overKeyboard = subject.overKeyboardContainer
        let bottomContainer = subject.bottomContainer

        // Verifies that the constraint between overKeyboardContainer and bottomContainer
        // produces the correct layout (no gap, no overlap).
        // Bottom edge of overKeyboard should exactly touch top edge of bottomContainer
        XCTAssertEqual(overKeyboard.frame.maxY, bottomContainer.frame.minY, accuracy: 1.0)
    }

    func test_containerViews_spanFullWidth() {
        let subject = createSubject()
        subject.view.layoutIfNeeded()

        let viewWidth = subject.view.bounds.width

        XCTAssertEqual(subject.bottomContainer.frame.width, viewWidth, accuracy: 1.0)
        XCTAssertEqual(subject.overKeyboardContainer.frame.width, viewWidth, accuracy: 1.0)
        XCTAssertEqual(subject.header.frame.width, viewWidth, accuracy: 1.0)
    }

    // MARK: - Height Constraint Tests

    func test_overKeyboardContainer_hasHeightConstraint() {
        let subject = createSubject(isBottomSearchBar: false)

        let overKeyboard = subject.overKeyboardContainer
        let hasHeightConstraint = overKeyboard.constraints.contains {
            $0.firstAttribute == .height || $0.secondAttribute == .height
        }

        XCTAssertTrue(hasHeightConstraint)
    }

    // MARK: - Additional Container Tests

    func test_bottomContentStackView_existsInHierarchy() {
        let subject = createSubject()

        XCTAssertNotNil(subject.bottomContentStackView)
        XCTAssertNotNil(subject.bottomContentStackView.superview)
    }

    func test_readerModeBar_hasConstraintsWhenPresent() {
        let subject = createSubject()

        // ReaderModeBar is optional, but when present should have constraints
        if let readerModeBar = subject.readerModeBar {
            XCTAssertNotNil(readerModeBar.superview)
            XCTAssertGreaterThan(readerModeBar.constraints.count, 0)
        }
    }

    // MARK: - Constraint Priority Tests

    func test_bottomContainer_hasRequiredPriorityConstraints() {
        let subject = createSubject()

        // Important structural constraints should be required priority
        let bottomConstraints = subject.view.constraints.filter {
            $0.firstItem === subject.bottomContainer || $0.secondItem === subject.bottomContainer
        }

        let requiredConstraints = bottomConstraints.filter {
            $0.priority == .required
        }

        XCTAssertGreaterThan(requiredConstraints.count, 0)
    }

    // MARK: - Helper Methods

    /// Check if a view has a constraint with the given attribute related to another view
    private func hasConstraint(for view: UIView,
                               attribute: NSLayoutConstraint.Attribute,
                               relatedTo relatedView: UIView) -> Bool {
        // Check view's own constraints
        let hasInOwnConstraints = view.constraints.contains { constraint in
            (constraint.firstAttribute == attribute && constraint.secondItem === relatedView) ||
            (constraint.secondAttribute == attribute && constraint.firstItem === relatedView)
        }

        // Check superview's constraints (where most constraints actually live)
        let hasInSuperviewConstraints = view.superview?.constraints.contains { constraint in
            ((constraint.firstItem === view && constraint.firstAttribute == attribute) ||
             (constraint.secondItem === view && constraint.secondAttribute == attribute))
        } ?? false

        return hasInOwnConstraints || hasInSuperviewConstraints
    }

    private func countRelevantConstraints(for view: UIView) -> Int {
        let relevantConstraints = view.constraints.filter {
            [.leading, .trailing, .bottom, .height].contains($0.firstAttribute)
        }
        return relevantConstraints.count
    }

    /// Check if two sibling views are connected by a constraint
    /// Example: overKeyboard.bottom connects to bottomContainer.top
    private func hasConstraintBetween(firstView: UIView,
                                      firstAttribute: NSLayoutConstraint.Attribute,
                                      secondView: UIView,
                                      secondAttribute: NSLayoutConstraint.Attribute,
                                      in containerView: UIView) -> Bool {
        return containerView.constraints.contains { constraint in
            // Check: firstView.firstAttribute = secondView.secondAttribute
            (constraint.firstItem === firstView &&
             constraint.firstAttribute == firstAttribute &&
             constraint.secondItem === secondView &&
             constraint.secondAttribute == secondAttribute) ||
            // Check reverse: secondView.secondAttribute = firstView.firstAttribute
            (constraint.firstItem === secondView &&
             constraint.firstAttribute == secondAttribute &&
             constraint.secondItem === firstView &&
             constraint.secondAttribute == firstAttribute)
        }
    }
}
