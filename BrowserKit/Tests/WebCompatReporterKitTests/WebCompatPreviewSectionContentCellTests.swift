// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
@testable import WebCompatReporterKit

@MainActor
final class WebCompatPreviewSectionContentCellTests: XCTestCase {
    // The lines stack tight inside one card, no blank line between.
    func testConfigure_withSeveralRows_joinsThemOnePerLine() {
        let subject = createSubject()

        configure(subject, rows: [row("is_tablet", .bool(false)), row("memory", .quantity(6144))])

        XCTAssertEqual(text(in: subject), "is_tablet: false\nmemory: 6144")
    }

    // The whole line is secondary, key included.
    func testApplyTheme_usesTheCardAndSecondaryTextTokens() {
        let subject = createSubject()
        configure(subject, rows: [row("memory", .quantity(6144))])

        subject.applyTheme(theme: LightTheme())

        XCTAssertEqual(cardView(in: subject)?.backgroundColor, LightTheme().colors.layer5)
        XCTAssertEqual(label(in: subject)?.textColor, LightTheme().colors.textSecondary)
    }

    // Measured against a short value at the same width, so it doesn't depend on font metrics.
    func testLongValue_wrapsInsteadOfTruncating() {
        let shortSubject = createSubject()
        configure(shortSubject, rows: [row("url", .string(UX.shortURL))])
        let longSubject = createSubject()
        configure(longSubject, rows: [row("url", .string(UX.longURL))])

        XCTAssertEqual(label(in: longSubject)?.numberOfLines, 0)
        XCTAssertGreaterThan(fittingHeight(of: longSubject), fittingHeight(of: shortSubject))
    }

    // MARK: - Helpers

    private enum UX {
        static let cellWidth: CGFloat = 320
        static let cellHeight: CGFloat = 44
        static let identifier = "WebCompatReporter.Preview.Section.basic.content"
        static let shortURL = "https://a.example"
        static let longURL = "https://houseandhome.example.com/recipes/2026/07/croque-monsieur-with-bechamel"
    }

    private func createSubject() -> WebCompatPreviewSectionContentCell {
        return WebCompatPreviewSectionContentCell(
            frame: CGRect(x: 0, y: 0, width: UX.cellWidth, height: UX.cellHeight)
        )
    }

    private func configure(
        _ cell: WebCompatPreviewSectionContentCell,
        rows: [WebCompatReportPreviewViewModel.PreviewRow]
    ) {
        cell.configure(rows: rows, accessibilityIdentifier: UX.identifier)
    }

    /// The card is the cell's only content subview; the label lives inside it.
    private func cardView(in cell: WebCompatPreviewSectionContentCell) -> UIView? {
        return cell.contentView.subviews.first
    }

    /// `systemLayoutSizeFitting(_:)` alone leaves the width unconstrained, so the label
    /// never wraps and every value measures one line.
    private func fittingHeight(of cell: WebCompatPreviewSectionContentCell) -> CGFloat {
        return cell.contentView.systemLayoutSizeFitting(
            CGSize(width: UX.cellWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func row(
        _ label: String,
        _ value: WebCompatReportPreviewViewModel.PreviewValue
    ) -> WebCompatReportPreviewViewModel.PreviewRow {
        return WebCompatReportPreviewViewModel.PreviewRow(id: label, label: label, value: value)
    }

    private func label(in cell: WebCompatPreviewSectionContentCell) -> UILabel? {
        return firstSubview(ofType: UILabel.self, in: cell)
    }

    private func text(in cell: WebCompatPreviewSectionContentCell) -> String? {
        return label(in: cell)?.text
    }
}
