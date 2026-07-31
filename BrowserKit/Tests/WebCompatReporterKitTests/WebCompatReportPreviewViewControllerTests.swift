// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatReportPreviewViewControllerTests: XCTestCase {
    private enum UX {
        static let presentationSize = CGSize(width: 390, height: 844)
    }

    func testSectionsStartCollapsed() {
        let subject = createSubject(sections: sampleSections)
        layout(subject)

        // Collapsed means header only.
        XCTAssertEqual(collectionView(in: subject)?.numberOfItems(inSection: 0), 1)
    }

    func testExpandingSection_revealsItsValueRows() throws {
        let subject = createSubject(sections: sampleSections)
        layout(subject)

        try expandFirstSection(in: subject)

        let collectionView = collectionView(in: subject)
        XCTAssertEqual(collectionView?.numberOfItems(inSection: 0), 2)
        XCTAssertTrue(collectionView?.cellForItem(at: IndexPath(item: 1, section: 0)) is WebCompatPreviewSectionContentCell)
    }

    // The Client re-configures on every state change. An unchanged re-configure must skip the
    // top-level apply, which would drop every item and close the open group.
    func testConfigure_withUnchangedSections_keepsTheExistingCells() throws {
        let subject = createSubject(sections: sampleSections)
        layout(subject)
        try expandFirstSection(in: subject)
        let contentIndexPath = IndexPath(item: 1, section: 0)
        let cellBeforeReconfigure = collectionView(in: subject)?.cellForItem(at: contentIndexPath)
        XCTAssertNotNil(cellBeforeReconfigure)

        subject.configure(with: makeViewModel(sections: sampleSections))
        subject.view.layoutIfNeeded()

        XCTAssertIdentical(
            cellBeforeReconfigure,
            collectionView(in: subject)?.cellForItem(at: contentIndexPath)
        )
    }

    func testApplyTheme_afterExpanding_keepsTheSectionExpanded() throws {
        let subject = createSubject(sections: sampleSections)
        layout(subject)
        try expandFirstSection(in: subject)

        subject.applyTheme(theme: DarkTheme())
        subject.view.layoutIfNeeded()

        XCTAssertEqual(collectionView(in: subject)?.numberOfItems(inSection: 0), 2)
    }

    // If a round-tripped snapshot omitted collapsed children, applying it would delete them.
    func testApplyTheme_whileCollapsed_thenExpanding_stillRevealsRows() throws {
        let subject = createSubject(sections: sampleSections)
        layout(subject)

        subject.applyTheme(theme: DarkTheme())
        subject.view.layoutIfNeeded()
        try expandFirstSection(in: subject)

        XCTAssertEqual(collectionView(in: subject)?.numberOfItems(inSection: 0), 2)
    }

    // A changed section set forces the apply that drops items, so expansion is restored by hand.
    func testConfigure_withAnAddedSection_keepsTheOpenSectionExpanded() throws {
        let subject = createSubject(sections: sampleSections)
        layout(subject)
        try expandFirstSection(in: subject)

        subject.configure(with: makeViewModel(sections: [addedSection] + sampleSections))
        subject.view.layoutIfNeeded()

        let basicSection = try XCTUnwrap(
            sectionIndex(ofHeader: "section.basic", in: subject),
            "The pre-existing section should survive the added one"
        )
        XCTAssertEqual(basicSection, 1, "The added section should sort ahead of it")
        XCTAssertEqual(collectionView(in: subject)?.numberOfItems(inSection: basicSection), 2)
    }

    // A value edited under a stable id still has to reach the cell; the diff can't see it.
    func testConfigure_withChangedRowValue_updatesTheVisibleRow() throws {
        let subject = createSubject(sections: sampleSections)
        layout(subject)
        try expandFirstSection(in: subject)

        subject.configure(with: makeViewModel(sections: [changedFirstSection, sampleSections[1]]))
        subject.view.layoutIfNeeded()

        let cell = collectionView(in: subject)?.cellForItem(at: IndexPath(item: 1, section: 0))
        XCTAssertTrue(cell?.accessibilityLabel?.contains("https://changed.example") == true)
    }

    func testConfigure_withDifferentSections_replacesTheList() {
        let subject = createSubject(sections: sampleSections)
        layout(subject)

        subject.configure(with: makeViewModel(sections: [sampleSections[1]]))
        subject.view.layoutIfNeeded()

        let collectionView = collectionView(in: subject)
        XCTAssertEqual(collectionView?.numberOfSections, 1)
        let header = collectionView?.cellForItem(at: IndexPath(item: 0, section: 0))
        XCTAssertEqual(header?.accessibilityIdentifier, "section.system")
    }

    func testCloseTap_notifiesDelegate() throws {
        let delegate = MockWebCompatReportPreviewDelegate()
        let subject = createSubject(sections: sampleSections)
        subject.delegate = delegate
        subject.loadViewIfNeeded()

        let closeButton = try XCTUnwrap(
            subject.navigationItem.rightBarButtonItem?.customView as? CloseButton,
            "The close button should be the bar button item's custom view"
        )
        fireActions(on: closeButton, for: .touchUpInside)

        XCTAssertEqual(delegate.didRequestDismissCallCount, 1)
    }

    // Reporting the gesture as handled with nobody listening would swallow it silently.
    func testAccessibilityEscape_withoutDelegate_isNotHandled() {
        XCTAssertFalse(createSubject(sections: sampleSections).accessibilityPerformEscape())
    }

    func testConfigure_fromSectionsToEmpty_clearsTheList() {
        let subject = createSubject(sections: sampleSections)
        layout(subject)

        subject.configure(with: makeViewModel())
        subject.view.layoutIfNeeded()

        XCTAssertEqual(collectionView(in: subject)?.numberOfSections, 0)
    }

    // MARK: - Helpers

    private func makeViewModel(
        sections: [WebCompatReportPreviewViewModel.PreviewSection] = []
    ) -> WebCompatReportPreviewViewModel {
        return WebCompatReportPreviewViewModel(
            title: "Report Preview",
            closeAccessibilityLabel: "Close",
            closeA11yIdentifier: "close",
            sections: sections
        )
    }

    private func createSubject(
        sections: [WebCompatReportPreviewViewModel.PreviewSection] = []
    ) -> WebCompatReportPreviewViewController {
        return WebCompatReportPreviewViewController(
            viewModel: makeViewModel(sections: sections),
            theme: LightTheme()
        )
    }

    private func layout(_ subject: WebCompatReportPreviewViewController) {
        subject.view.frame = CGRect(origin: .zero, size: UX.presentationSize)
        subject.loadViewIfNeeded()
        subject.view.layoutIfNeeded()
    }

    /// UIKit owns the disclosure gesture, so expand the way that gesture ends up doing. Reached
    /// through the collection view, since the screen keeps its data source private.
    private func expandFirstSection(in subject: WebCompatReportPreviewViewController) throws {
        let dataSource = try XCTUnwrap(
            collectionView(in: subject)?.dataSource as? UICollectionViewDiffableDataSource<String, String>
        )
        let sectionID = sampleSections[0].id
        var snapshot = dataSource.snapshot(for: sectionID)
        // The header is the section snapshot's only root; its id format is private.
        snapshot.expand(snapshot.rootItems)
        dataSource.apply(snapshot, to: sectionID, animatingDifferences: false)
        subject.view.layoutIfNeeded()
    }

    private let sampleSections: [WebCompatReportPreviewViewModel.PreviewSection] = [
        WebCompatReportPreviewViewModel.PreviewSection(
            id: "basic",
            title: "basic",
            a11yIdentifier: "section.basic",
            contentA11yIdentifier: "section.basic.content",
            rows: [
                WebCompatReportPreviewViewModel.PreviewRow(
                    id: "basic.url", label: "url", value: .string("https://example.com")
                ),
                WebCompatReportPreviewViewModel.PreviewRow(
                    id: "basic.breakage_category", label: "breakage_category", value: .string("no_audio")
                )
            ]
        ),
        WebCompatReportPreviewViewModel.PreviewSection(
            id: "system",
            title: "system",
            a11yIdentifier: "section.system",
            contentA11yIdentifier: "section.system.content",
            rows: [
                WebCompatReportPreviewViewModel.PreviewRow(
                    id: "system.is_tablet", label: "is_tablet", value: .bool(false)
                )
            ]
        )
    ]

    private var addedSection: WebCompatReportPreviewViewModel.PreviewSection {
        return WebCompatReportPreviewViewModel.PreviewSection(
            id: "graphics",
            title: "graphics",
            a11yIdentifier: "section.graphics",
            contentA11yIdentifier: "section.graphics.content",
            rows: [
                WebCompatReportPreviewViewModel.PreviewRow(
                    id: "graphics.has_touch_screen", label: "has_touch_screen", value: .bool(true)
                )
            ]
        )
    }

    /// `sampleSections[0]` with one value changed and every id the same, which the diff misses.
    private var changedFirstSection: WebCompatReportPreviewViewModel.PreviewSection {
        let section = sampleSections[0]
        return WebCompatReportPreviewViewModel.PreviewSection(
            id: section.id,
            title: section.title,
            a11yIdentifier: section.a11yIdentifier,
            contentA11yIdentifier: section.contentA11yIdentifier,
            rows: [
                WebCompatReportPreviewViewModel.PreviewRow(
                    id: "basic.url", label: "url", value: .string("https://changed.example")
                ),
                section.rows[1]
            ]
        )
    }

    private func collectionView(in subject: WebCompatReportPreviewViewController) -> UICollectionView? {
        return subject.view.subviews.compactMap { $0 as? UICollectionView }.first
    }

    /// A section is recognisable from outside by its header cell's identifier.
    private func sectionIndex(
        ofHeader accessibilityIdentifier: String,
        in subject: WebCompatReportPreviewViewController
    ) -> Int? {
        guard let collectionView = collectionView(in: subject) else { return nil }
        return (0..<collectionView.numberOfSections).first { section in
            collectionView.cellForItem(at: IndexPath(item: 0, section: section))?
                .accessibilityIdentifier == accessibilityIdentifier
        }
    }
}

private final class MockWebCompatReportPreviewDelegate: WebCompatReportPreviewDelegate {
    var didRequestDismissCallCount = 0

    func webCompatReportPreviewDidRequestDismiss() {
        didRequestDismissCallCount += 1
    }
}
