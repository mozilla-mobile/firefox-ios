// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@testable import Client

@MainActor
final class BrowserViewControllerLayoutManagerTests: XCTestCase {
    var parentView: UIView!
    var headerView: UIView!
    private var toolbarHelper: MockToolbarHelper!

    override func setUp() async throws {
        try await super.setUp()
        parentView = UIView(frame: CGRect(x: 0, y: 0, width: 375, height: 812))
        headerView = UIView()
        toolbarHelper = MockToolbarHelper()
    }

    override func tearDown() async throws {
        toolbarHelper = nil
        headerView = nil
        parentView = nil
        try await super.tearDown()
    }

    // MARK: - Setup Header Constraints

    func test_setupHeaderConstraints_topToolbar_createsHorizontalConstraints() {
        let subject = createSubject()
        subject.setupHeaderConstraints(isBottomSearchBar: false)

        let hasLeading = parentView.constraints.contains {
            $0.firstItem === headerView && $0.firstAttribute == .leading
        }
        let hasTrailing = parentView.constraints.contains {
            $0.firstItem === headerView && $0.firstAttribute == .trailing
        }

        XCTAssertTrue(hasLeading)
        XCTAssertTrue(hasTrailing)
    }

    func test_setupHeaderConstraints_topToolbar_createsTopConstraint() {
        let subject = createSubject()
        subject.setupHeaderConstraints(isBottomSearchBar: false)

        let hasTopConstraint = parentView.constraints.contains {
            ($0.firstItem === headerView && $0.firstAttribute == .top) ||
            ($0.secondItem === headerView && $0.secondAttribute == .top)
        }

        XCTAssertTrue(hasTopConstraint)
    }

    func test_setupHeaderConstraints_bottomToolBar_heightIsZero() {
        let subject = createSubject()
        subject.setupHeaderConstraints(isBottomSearchBar: true)

        // Height constraints are stored on the view itself, not the parent
        let heightConstraint = headerView.constraints.first {
            $0.firstAttribute == .height
        }

        XCTAssertNotNil(heightConstraint)
        XCTAssertEqual(heightConstraint?.constant, 0)
    }

    // MARK: - Update Header Constraints

    func test_updateHeaderConstraints_topToolBar_deactivatesOldConstraint() {
        let subject = createSubject()
        subject.setupHeaderConstraints(isBottomSearchBar: false)
        let initialConstraintCount = parentView.constraints.count

        subject.updateHeaderConstraints(isBottomSearchBar: false)

        // Constraint count should stay the same (one removed, one added)
        XCTAssertEqual(parentView.constraints.count, initialConstraintCount)
    }

    func test_updateHeaderConstraints_bottomToolBar_heightIsZero() {
        let subject = createSubject()
        subject.updateHeaderConstraints(isBottomSearchBar: true)

        // Height constraints are stored on the view itself, not the parent
        let heightConstraint = headerView.constraints.first {
            $0.firstAttribute == .height
        }

        XCTAssertNotNil(heightConstraint)
        XCTAssertEqual(heightConstraint?.constant, 0)
    }

    func test_updateHeaderConstraints_bottomToolBar_ActivateExistingConstraint() {
        let subject = createSubject()
        subject.setupHeaderConstraints(isBottomSearchBar: true)

        let heightConstraint = headerView.constraints.first {
            $0.firstAttribute == .height
        }

        guard let heightConstraint else {
            return XCTFail("Height constraint not present on header view")
        }
        // Initially height constraint is active
        XCTAssertTrue(heightConstraint.isActive)

        // Setting for top toolbar should be not active
        subject.updateHeaderConstraints(isBottomSearchBar: false)
        XCTAssertFalse(heightConstraint.isActive)

        // Setting back to bottom toolbar should be active
        subject.updateHeaderConstraints(isBottomSearchBar: true)
        XCTAssertTrue(heightConstraint.isActive)
    }

    // MARK: - Anchor Selection

    func test_setupHeaderConstraints_topToolbarWithNavToolbar_usesSafeArea() {
        let subject = createSubject()
        toolbarHelper.shouldShowNavigationToolbar = true
        subject.setupHeaderConstraints(isBottomSearchBar: false)

        let topConstraint = parentView.constraints.first {
            ($0.firstItem === headerView && $0.firstAttribute == .top)
        }

        // If using safe area, the secondItem should be a UILayoutGuide
        XCTAssertTrue(topConstraint?.secondItem is UILayoutGuide)
    }

    func test_setupHeaderConstraints_topToolbarWithoutNavToolbar_usesViewTop() {
        let subject = createSubject()
        toolbarHelper.shouldShowNavigationToolbar = false
        toolbarHelper.shouldShowTopTabs = false
        subject.setupHeaderConstraints(isBottomSearchBar: false)

        let topConstraint = parentView.constraints.first {
            ($0.firstItem === headerView && $0.firstAttribute == .top)
        }

        // If using view.topAnchor directly, secondItem should be the parentView
        XCTAssertTrue(topConstraint?.secondItem === parentView)
    }

    func test_setupHeaderConstraints_bottomSearchBar_alwaysUsesSafeArea() {
        let subject = createSubject()
        toolbarHelper.shouldShowNavigationToolbar = false
        toolbarHelper.shouldShowTopTabs = false
        subject.setupHeaderConstraints(isBottomSearchBar: true)

        let topConstraint = parentView.constraints.first {
            ($0.firstItem === headerView && $0.firstAttribute == .top)
        }

        // Bottom search bar should always use safe area
        XCTAssertTrue(topConstraint?.secondItem is UILayoutGuide)
    }

    func test_updateHeaderConstraints_withoutScrollController_doesNotCrash() {
        let subject = createSubject()
        subject.setupHeaderConstraints(isBottomSearchBar: false)

        XCTAssertNoThrow(subject.updateHeaderConstraints(isBottomSearchBar: false))
    }

    // MARK: - Layout Tests

    func test_setupHeaderConstraints_allowsLayoutPass() {
        let subject = createSubject()
        subject.setupHeaderConstraints(isBottomSearchBar: false)

        XCTAssertNoThrow(parentView.layoutIfNeeded())
    }

    func test_updateHeaderConstraints_allowsLayoutPass() {
        let subject = createSubject()
        subject.setupHeaderConstraints(isBottomSearchBar: false)
        subject.updateHeaderConstraints(isBottomSearchBar: false)

        XCTAssertNoThrow(parentView.layoutIfNeeded())
    }

    // MARK: - Reader Mode Bar Constraints

    func test_addReaderModeButton_addsHeightConstraints() {
        let subject = createSubject()
        let readerModeBar = ReaderModeBarView(frame: .zero)
        subject.addReaderModeBarHeight(readerModeBar)

        let heightConstraints = readerModeBar.constraints.filter {
            $0.firstAttribute == .height
        }

        XCTAssertNotNil(heightConstraints)
    }

    // MARK: - Private helpers

    private func createSubject() -> BrowserViewControllerLayoutManager {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(headerView)
        let subject = BrowserViewControllerLayoutManager(parentView: parentView,
                                                         headerView: headerView,
                                                         toolbarHelper: toolbarHelper)
        trackForMemoryLeaks(subject)
        return subject
    }
}
