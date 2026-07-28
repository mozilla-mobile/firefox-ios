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

    func testExpandingSection_revealsItsValueRows() {
        let subject = createSubject(sections: sampleSections)
        layout(subject)

        expandFirstSection(in: subject)

        let collectionView = collectionView(in: subject)
        XCTAssertEqual(collectionView?.numberOfItems(inSection: 0), 2)
        XCTAssertTrue(collectionView?.cellForItem(at: IndexPath(item: 1, section: 0)) is WebCompatPreviewSectionContentCell)
    }

    // The Client re-configures on every state change. That must not close an open group.
    func testConfigure_afterExpanding_keepsTheSectionExpanded() {
        let subject = createSubject(sections: sampleSections)
        layout(subject)
        expandFirstSection(in: subject)

        subject.configure(with: makeViewModel(sections: sampleSections))
        subject.view.layoutIfNeeded()

        XCTAssertEqual(collectionView(in: subject)?.numberOfItems(inSection: 0), 2)
    }

    // An unchanged re-configure should skip the top-level apply, which would drop every item.
    func testConfigure_withUnchangedSections_keepsTheExistingCells() {
        let subject = createSubject(sections: sampleSections)
        layout(subject)
        expandFirstSection(in: subject)
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

    func testApplyTheme_afterExpanding_keepsTheSectionExpanded() {
        let subject = createSubject(sections: sampleSections)
        layout(subject)
        expandFirstSection(in: subject)

        subject.applyTheme(theme: DarkTheme())
        subject.view.layoutIfNeeded()

        XCTAssertEqual(collectionView(in: subject)?.numberOfItems(inSection: 0), 2)
    }

    // If a round-tripped snapshot omitted collapsed children, applying it would delete them.
    func testApplyTheme_whileCollapsed_thenExpanding_stillRevealsRows() {
        let subject = createSubject(sections: sampleSections)
        layout(subject)

        subject.applyTheme(theme: DarkTheme())
        subject.view.layoutIfNeeded()
        expandFirstSection(in: subject)

        XCTAssertEqual(collectionView(in: subject)?.numberOfItems(inSection: 0), 2)
    }

    // A changed section set forces the apply that drops items, so expansion is restored by hand.
    func testConfigure_withAnAddedSection_keepsTheOpenSectionExpanded() throws {
        let subject = createSubject(sections: sampleSections)
        layout(subject)
        expandFirstSection(in: subject)

        subject.configure(with: makeViewModel(sections: [addedSection] + sampleSections))
        subject.view.layoutIfNeeded()

        let basicSection = try XCTUnwrap(
            subject.dataSource.snapshot().sectionIdentifiers.firstIndex(of: "basic"),
            "The pre-existing section should survive the added one"
        )
        XCTAssertEqual(basicSection, 1, "The added section should sort ahead of it")
        XCTAssertEqual(collectionView(in: subject)?.numberOfItems(inSection: basicSection), 2)
    }

    // A value edited under a stable id still has to reach the cell; the diff can't see it.
    func testConfigure_withChangedRowValue_updatesTheVisibleRow() {
        let subject = createSubject(sections: sampleSections)
        layout(subject)
        expandFirstSection(in: subject)

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

    /// A `backgroundConfiguration` card renders square on top and round on the bottom, because a
    /// list cell masks by group position. Only visible in the list, hence real pixels.
    func testExpandedCard_isRoundedOnAllFourCorners() throws {
        let cardRows = try cardRowExtents(in: try renderExpandedScreen())

        let topRow = try XCTUnwrap(cardRows.first)
        let bottomRow = try XCTUnwrap(cardRows.last)
        let widestRow = try XCTUnwrap(cardRows.max(by: { $0.width < $1.width }))
        XCTAssertLessThan(
            topRow.width,
            widestRow.width,
            "The card's first scanline spans its full width, so the top corners are square"
        )
        XCTAssertLessThan(
            bottomRow.width,
            widestRow.width,
            "The card's last scanline spans its full width, so the bottom corners are square"
        )
    }

    // MARK: - Helpers

    private func renderExpandedScreen() throws -> UIImage {
        let subject = createSubject(sections: sampleSections)
        let window = UIWindow(frame: CGRect(origin: .zero, size: UX.presentationSize))
        window.rootViewController = UINavigationController(rootViewController: subject)
        window.isHidden = false
        addTeardownBlock { window.rootViewController = nil }
        window.layoutIfNeeded()
        expandFirstSection(in: subject)
        window.layoutIfNeeded()

        return UIGraphicsImageRenderer(bounds: window.bounds).image { context in
            window.layer.render(in: context.cgContext)
        }
    }

    /// Every card scanline's horizontal extent, top to bottom. The card is the only `layer5` fill
    /// wide enough to span most of the screen.
    ///
    /// Matched against a swatch from the same renderer, not against colour components: the buffer
    /// is BGRA, so comparing components works only while the colour is channel-symmetric.
    private func cardRowExtents(in image: UIImage) throws -> [(y: Int, width: Int)] {
        let cgImage = try XCTUnwrap(image.cgImage)
        let data = try XCTUnwrap(cgImage.dataProvider?.data)
        let pointer = try XCTUnwrap(CFDataGetBytePtr(data))
        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let cardPixel = try swatchBytes(of: LightTheme().colors.layer5, bytesPerPixel: bytesPerPixel)

        var extents: [(y: Int, width: Int)] = []
        for y in 0..<cgImage.height {
            var longestRun = 0
            var run = 0
            for x in 0..<cgImage.width {
                let offset = y * cgImage.bytesPerRow + x * bytesPerPixel
                let isCard = (0..<bytesPerPixel).allSatisfy { pointer[offset + $0] == cardPixel[$0] }
                if isCard {
                    run += 1
                    longestRun = max(longestRun, run)
                } else {
                    run = 0
                }
            }
            // Wide enough to be the card rather than a glyph or the disclosure chevron.
            if longestRun > cgImage.width / 2 { extents.append((y, longestRun)) }
        }
        XCTAssertFalse(extents.isEmpty, "Found no card in the render, so the scan proves nothing")
        return extents
    }

    /// The colour's bytes as this renderer lays them out, so channel order can't matter.
    private func swatchBytes(of color: UIColor, bytesPerPixel: Int) throws -> [UInt8] {
        let swatch = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            color.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
        let cgImage = try XCTUnwrap(swatch.cgImage)
        let data = try XCTUnwrap(cgImage.dataProvider?.data)
        let pointer = try XCTUnwrap(CFDataGetBytePtr(data))
        return (0..<bytesPerPixel).map { pointer[$0] }
    }

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

    /// UIKit owns the disclosure gesture, so expand the way that gesture ends up doing.
    private func expandFirstSection(in subject: WebCompatReportPreviewViewController) {
        let sectionID = sampleSections[0].id
        var snapshot = subject.dataSource.snapshot(for: sectionID)
        // The header is the section snapshot's only root; its id format is private.
        snapshot.expand(snapshot.rootItems)
        subject.dataSource.apply(snapshot, to: sectionID, animatingDifferences: false)
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
}

private final class MockWebCompatReportPreviewDelegate: WebCompatReportPreviewDelegate {
    var didRequestDismissCallCount = 0

    func webCompatReportPreviewDidRequestDismiss() {
        didRequestDismissCallCount += 1
    }
}
