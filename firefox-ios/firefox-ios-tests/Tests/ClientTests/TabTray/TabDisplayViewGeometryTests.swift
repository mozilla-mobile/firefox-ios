// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest

@testable import Client

/// Checks that an item's layout attributes frame matches the rect its cell occupies, including for cells the
/// collection view has not realized yet. `TabAnimation` reads that frame to size the browser snapshot
/// instead of forcing a layout pass.
@MainActor
final class TabDisplayViewGeometryTests: XCTestCase {
    let viewSize = CGSize(width: 390, height: 844)
    let tabCount = 20

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testLayoutAttributesFrame_matchesRealizedCellFrame() throws {
        let subject = createSubject()
        let collectionView = subject.collectionView
        let indexPath = IndexPath(item: 0, section: 0)

        let cell = try XCTUnwrap(collectionView.cellForItem(at: indexPath) as? ExperimentTabCell)
        let attributes = try XCTUnwrap(collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath))

        XCTAssertEqual(collectionView.convert(attributes.frame, to: subject),
                       cell.convert(cell.backgroundHolder.bounds, to: subject))
    }

    func testLayoutAttributesFrame_matchesRealizedCellFrame_forOffscreenTabAfterScrolling() throws {
        let subject = createSubject()
        let collectionView = subject.collectionView
        let indexPath = IndexPath(item: tabCount - 1, section: 0)
        XCTAssertNil(collectionView.cellForItem(at: indexPath),
                     "The last tab is expected to start off screen, otherwise this isn't testing anything.")

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        let attributes = try XCTUnwrap(collectionView.collectionViewLayout.layoutAttributesForItem(at: indexPath))
        let frameBeforeLayout = collectionView.convert(attributes.frame, to: subject)

        collectionView.layoutIfNeeded()

        let cell = try XCTUnwrap(collectionView.cellForItem(at: indexPath) as? ExperimentTabCell)
        XCTAssertEqual(frameBeforeLayout, cell.convert(cell.backgroundHolder.bounds, to: subject))
    }

    func testMinimizingTabUUID_hidesOnlyTheMatchingCell() throws {
        // The subject has to stay alive: it owns the diffable data source the collection view only holds weakly.
        let subject = createSubject(minimizingTabUUID: tabUUID(for: 0))
        let collectionView = subject.collectionView

        let minimizedCell = try XCTUnwrap(collectionView.cellForItem(at: IndexPath(item: 0, section: 0)))
        let otherCell = try XCTUnwrap(collectionView.cellForItem(at: IndexPath(item: 1, section: 0)))

        XCTAssertTrue(minimizedCell.isHidden)
        XCTAssertFalse(otherCell.isHidden)
    }

    /// The animation sets `minimizingTabUUID` before scrolling so that cells dequeued on the way to the
    /// selected tab also come back hidden.
    func testMinimizingTabUUID_hidesMatchingCellDequeuedWhileScrolling() throws {
        let indexPath = IndexPath(item: tabCount - 1, section: 0)
        let subject = createSubject(minimizingTabUUID: tabUUID(for: indexPath.item))
        let collectionView = subject.collectionView
        XCTAssertNil(collectionView.cellForItem(at: indexPath),
                     "The last tab is expected to start off screen, otherwise this isn't testing anything.")

        collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
        collectionView.layoutIfNeeded()

        let cell = try XCTUnwrap(collectionView.cellForItem(at: indexPath))
        XCTAssertTrue(cell.isHidden)
    }

    // MARK: - Private
    private func createSubject(minimizingTabUUID: TabUUID? = nil,
                               file: StaticString = #filePath,
                               line: UInt = #line) -> TabDisplayView {
        let tabs = (0..<tabCount).map {
            TabModel.emptyState(tabUUID: tabUUID(for: $0), title: "Tab \($0)")
        }
        let state = TabsPanelState(windowUUID: .XCTestDefaultUUID).copy(tabs: tabs)

        let subject = TabDisplayView(panelType: .tabs,
                                     state: state,
                                     windowUUID: .XCTestDefaultUUID,
                                     tabTrayUtils: MockTabTrayUtils())
        subject.minimizingTabUUID = minimizingTabUUID
        subject.frame = CGRect(origin: .zero, size: viewSize)
        subject.newState(state: state)
        subject.layoutIfNeeded()

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func tabUUID(for index: Int) -> TabUUID { return "tab-\(index)" }
}
