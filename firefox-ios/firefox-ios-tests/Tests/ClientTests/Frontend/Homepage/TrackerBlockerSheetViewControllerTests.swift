// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import UIKit

@testable import Client

@MainActor
final class TrackerBlockerSheetViewControllerTests: XCTestCase {
    private typealias A11y = AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.Sheet

    func test_loadView_setsUpKeySubviews() {
        let subject = createSubject()

        subject.loadViewIfNeeded()

        XCTAssertNotNil(view(subject, withID: A11y.shieldIcon))
        XCTAssertNotNil(view(subject, withID: A11y.weeklyCountLabel))
        XCTAssertNotNil(view(subject, withID: A11y.categoriesCard))
    }

    func test_configureEmptyState_hidesWeeklyCountAndFooter() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .dummyEmpty)

        XCTAssertEqual(view(subject, withID: A11y.weeklyCountLabel)?.isHidden, true)
        // The footer stays in the layout but is empty (no a11y label) in the empty state.
        XCTAssertEqual(footerPill(in: subject)?.isAccessibilityElement, false)
        XCTAssertNil(footerPill(in: subject)?.accessibilityLabel)
        XCTAssertEqual((view(subject, withID: A11y.headerLabel) as? UILabel)?.text,
                       TrackerBlockerSheetState.dummyEmpty.emptyMessage)
    }

    func test_configureFilledState_showsWeeklyCountAndFooter() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .dummyFilled)

        let weeklyLabel = view(subject, withID: A11y.weeklyCountLabel) as? UILabel
        XCTAssertEqual(weeklyLabel?.isHidden, false)
        XCTAssertEqual(weeklyLabel?.text, TrackerBlockerSheetState.dummyFilled.weeklyCount?.formatted(.number))
        XCTAssertEqual(footerPill(in: subject)?.accessibilityLabel, TrackerBlockerSheetState.dummyFilled.totalText)
    }

    func test_configureFilledState_setsCategoryRowIdentifiers() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .dummyFilled)

        for index in 0..<TrackerBlockerSheetState.dummyFilled.categories.count {
            XCTAssertNotNil(view(subject, withID: A11y.categoryRow(index)),
                            "Expected a category row for index \(index)")
        }
    }

    func test_configureWeeklyResetState_showsZeroWeeklyCountAndFooter() {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        subject.configure(with: .dummyWeeklyReset)

        let weeklyLabel = view(subject, withID: A11y.weeklyCountLabel) as? UILabel
        XCTAssertEqual(weeklyLabel?.isHidden, false)
        XCTAssertEqual(weeklyLabel?.text, 0.formatted(.number))
        XCTAssertEqual(footerPill(in: subject)?.accessibilityLabel, TrackerBlockerSheetState.dummyWeeklyReset.totalText)
    }

    func test_loadView_setsUpCloseButton() {
        let subject = createSubject()

        subject.loadViewIfNeeded()

        XCTAssertNotNil(view(subject, withID: A11y.closeButton))
    }

    // MARK: - Fill ratios

    func test_fillRatio_isCategoryShareOfWeeklyCount() {
        let subject = TrackerBlockerSheetState(
            weeklyCount: 100,
            emptyMessage: nil,
            categories: [
                .init(title: "Fingerprinters", count: 70),
                .init(title: "Tracking Content", count: 30)
            ],
            totalText: nil
        )

        XCTAssertEqual(subject.fillRatio(for: subject.categories[0]), 0.7, accuracy: 0.0001)
        XCTAssertEqual(subject.fillRatio(for: subject.categories[1]), 0.3, accuracy: 0.0001)
    }

    func test_fillRatio_withZeroWeeklyCount_isZero() {
        let subject = TrackerBlockerSheetState.dummyWeeklyReset

        for category in subject.categories {
            XCTAssertEqual(subject.fillRatio(for: category), 0)
        }
    }

    func test_fillRatio_withNilWeeklyCount_isZero() {
        let subject = TrackerBlockerSheetState.dummyEmpty

        for category in subject.categories {
            XCTAssertEqual(subject.fillRatio(for: category), 0)
        }
    }

    /// The weekly count is the source of truth, so a category can never overfill its bar.
    func test_fillRatio_withCountAboveWeeklyCount_isClampedToOne() {
        let subject = TrackerBlockerSheetState(
            weeklyCount: 10,
            emptyMessage: nil,
            categories: [.init(title: "Fingerprinters", count: 25)],
            totalText: nil
        )

        XCTAssertEqual(subject.fillRatio(for: subject.categories[0]), 1)
    }

    // MARK: - Category row layout

    func test_categoryRow_withoutCount_collapsesProgressBarHeight() {
        let filled = makeRow(count: 12)
        let empty = makeRow(count: nil)

        XCTAssertLessThan(height(of: empty), height(of: filled))
    }

    /// Neither the icon nor a single line of title fills the empty row, so it sits at the fixed minimum.
    func test_categoryRow_emptyState_usesMinimumHeight() {
        let empty = makeRow(count: nil)

        XCTAssertEqual(height(of: empty), UX.emptyStateMinHeight, accuracy: 0.5)
    }

    func test_categoryRow_emptyState_centersIconInRow() throws {
        let row = laidOutRow(count: nil)

        let iconFrame = try frame(of: XCTUnwrap(row.subviews.first { type(of: $0) == UIView.self }), in: row)

        XCTAssertEqual(iconFrame.midY, row.bounds.midY, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(iconFrame.minY, UX.rowVerticalPadding)
    }

    /// The minimum is a floor, not a fixed height: a wrapping title still grows the row past it.
    func test_categoryRow_emptyStateWithWrappingTitle_growsPastMinimumHeight() {
        let empty = makeRow(count: nil, title: String(repeating: "Cross-Site Tracking Cookies ", count: 4))

        XCTAssertGreaterThan(height(of: empty), UX.emptyStateMinHeight)
    }

    /// The icon is centred on the title rather than on the row, so it stays beside the text when the title wraps.
    func test_categoryRow_withWrappingTitle_centersIconOnTitle() throws {
        let title = String(repeating: "Cross-Site Tracking Cookies ", count: 4)
        let row = laidOutRow(count: 12, title: title)

        let iconFrame = try frame(of: XCTUnwrap(row.subviews.first { type(of: $0) == UIView.self }), in: row)
        let titleFrame = try frame(of: XCTUnwrap(label(in: row, withText: title)), in: row)

        XCTAssertGreaterThan(titleFrame.height, iconFrame.height, "Expected the title to wrap past the icon height")
        XCTAssertEqual(iconFrame.midY, titleFrame.midY, accuracy: 0.5)
        XCTAssertNotEqual(iconFrame.midY, row.bounds.midY, accuracy: 0.5)
    }

    func test_categoryRow_placesCountInlineWithProgressBar() throws {
        let row = laidOutRow(count: 12)

        let titleFrame = try frame(of: XCTUnwrap(label(in: row, withText: "Fingerprinters")), in: row)
        let countFrame = try frame(of: XCTUnwrap(label(in: row, withText: 12.formatted(.number))), in: row)
        let barFrame = try frame(
            of: XCTUnwrap(allSubviews(in: row).first { $0 is TrackerBlockerProgressBarView }),
            in: row
        )

        XCTAssertGreaterThan(countFrame.minY, titleFrame.maxY, "Expected the count to sit below the title")
        XCTAssertEqual(countFrame.midY, barFrame.midY, accuracy: 0.5)
        XCTAssertLessThan(barFrame.maxX, countFrame.minX, "Expected the count to trail the bar")
    }

    // MARK: - Helpers

    /// Mirrors the private `TrackerCategoryRowView.UX` values the layout assertions depend on.
    private enum UX {
        static let rowWidth: CGFloat = 320
        static let rowVerticalPadding: CGFloat = 12
        static let emptyStateMinHeight: CGFloat = 55
    }

    private func makeRow(count: Int?, title: String = "Fingerprinters") -> TrackerCategoryRowView {
        let row = TrackerCategoryRowView()
        row.configure(with: .init(title: title, count: count), fillRatio: 0.5, theme: LightTheme())
        return row
    }

    private func laidOutRow(count: Int?, title: String = "Fingerprinters") -> TrackerCategoryRowView {
        let row = makeRow(count: count, title: title)
        row.frame = CGRect(x: 0, y: 0, width: UX.rowWidth, height: height(of: row))
        row.layoutIfNeeded()
        return row
    }

    private func label(in row: TrackerCategoryRowView, withText text: String) -> UILabel? {
        return allSubviews(in: row).compactMap { $0 as? UILabel }.first { $0.text == text }
    }

    private func frame(of view: UIView, in row: TrackerCategoryRowView) -> CGRect {
        return view.convert(view.bounds, to: row)
    }

    private func height(of row: TrackerCategoryRowView) -> CGFloat {
        return row.systemLayoutSizeFitting(
            CGSize(width: UX.rowWidth, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func createSubject(state: TrackerBlockerSheetState = .dummyFilled) -> TrackerBlockerSheetViewController {
        let subject = TrackerBlockerSheetViewController(
            windowUUID: .XCTestDefaultUUID,
            state: state,
            themeManager: MockThemeManager(),
            notificationCenter: MockNotificationCenter()
        )
        trackForMemoryLeaks(subject)
        return subject
    }

    /// The footer pill is always in the hierarchy; in the empty state it has no total text / a11y label.
    private func footerPill(in controller: UIViewController) -> UIView? {
        return view(controller, withID: A11y.totalPill)
    }

    private func view(_ controller: UIViewController, withID identifier: String) -> UIView? {
        return allSubviews(in: controller.view).first { $0.accessibilityIdentifier == identifier }
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        return view.subviews + view.subviews.flatMap { allSubviews(in: $0) }
    }
}
