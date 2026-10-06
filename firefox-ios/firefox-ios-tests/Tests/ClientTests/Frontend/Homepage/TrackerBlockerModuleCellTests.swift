// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import UIKit

@testable import Client

@MainActor
final class TrackerBlockerModuleCellTests: XCTestCase {
    private let theme = DarkTheme()
    private static let count = 1200

    func test_containerPill_isAccessibilityElement() {
        let cell = createSubject()

        cell.configure(count: 0, theme: theme, onTap: nil)

        XCTAssertEqual(containerPill(in: cell)?.isAccessibilityElement, true)
    }

    func test_configure_withOnTap_setsButtonTrait() {
        let cell = createSubject()

        cell.configure(count: 0, theme: theme, onTap: {})

        XCTAssertEqual(containerPill(in: cell)?.accessibilityTraits, .button)
    }

    func test_configure_withoutOnTap_setsStaticTextTrait() {
        let cell = createSubject()

        cell.configure(count: 0, theme: theme, onTap: nil)

        XCTAssertEqual(containerPill(in: cell)?.accessibilityTraits, .staticText)
    }

    func test_configure_withZeroCount_setsNoTrackersAccessibilityLabel() {
        let cell = createSubject()

        cell.configure(count: 0, theme: theme, onTap: nil)

        XCTAssertEqual(containerPill(in: cell)?.accessibilityLabel,
                       .FirefoxHomepage.TrackerBlocker.NoTrackersBlocked)
    }

    func test_configure_withNonZeroCount_setsFormattedAccessibilityLabel() {
        let cell = createSubject()
        let count = 5
        let numberText = count.formatted(.number.notation(.compactName))
        let expected = String(format: .FirefoxHomepage.TrackerBlocker.TrackersBlockedTemp, numberText)

        cell.configure(count: count, theme: theme, onTap: nil)

        XCTAssertEqual(containerPill(in: cell)?.accessibilityLabel, expected)
    }

    /// The bold count used to be built from the base font's `.textStyle` descriptor attribute, which for an
    /// `FXFontStyles` font holds an internal usage value (`CTFontRegularUsage`) rather than a real text style.
    /// The resulting font was pinned to the point size it was built at, so the count kept its size when the
    /// content size category changed — leaving an oversized number next to correctly resized copy.
    func test_configure_withNonZeroCount_usesScaledFootnoteFontsForBothRuns() throws {
        let cell = createSubject()

        cell.configure(count: Self.count, theme: theme, onTap: nil)

        let fonts = try runFonts(in: cell)
        XCTAssertEqual(fonts.bold, FXFontStyles.Bold.footnote.scaledFont())
        XCTAssertEqual(fonts.regular, FXFontStyles.Regular.footnote.scaledFont())
    }

    /// `configure` must not read its base font back out of `titleLabel.font`, which reports the attributed
    /// string's first font once it has been set — the bold count, when the count leads the string.
    func test_configure_calledTwice_usesScaledFootnoteFontsForBothRuns() throws {
        let cell = createSubject()

        cell.configure(count: Self.count, theme: theme, onTap: nil)
        cell.configure(count: Self.count, theme: theme, onTap: nil)

        let fonts = try runFonts(in: cell)
        XCTAssertEqual(fonts.bold, FXFontStyles.Bold.footnote.scaledFont())
        XCTAssertEqual(fonts.regular, FXFontStyles.Regular.footnote.scaledFont())
    }

    func test_configure_withZeroCount_usesBoldTitleFont() {
        let cell = createSubject()

        cell.configure(count: 0, theme: theme, onTap: nil)

        XCTAssertEqual(titleLabel(in: cell)?.font, FXFontStyles.Bold.footnote.scaledFont())
    }

    func test_configure_withZeroCountAfterNonZeroCount_usesBoldTitleFont() {
        let cell = createSubject()

        cell.configure(count: 5, theme: theme, onTap: nil)
        cell.configure(count: 0, theme: theme, onTap: nil)

        XCTAssertEqual(titleLabel(in: cell)?.font, FXFontStyles.Bold.footnote.scaledFont())
    }

    func test_pill_isVerticallyCenteredAndContained() throws {
        let cell = createSubject()
        cell.configure(count: 0, theme: theme, onTap: nil)
        cell.frame = CGRect(x: 0, y: 0, width: 320, height: 100)

        cell.layoutIfNeeded()

        let pill = try XCTUnwrap(containerPill(in: cell))
        XCTAssertEqual(pill.frame.midY, cell.contentView.bounds.midY, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(pill.frame.minY, 0)
        XCTAssertLessThanOrEqual(pill.frame.maxY, cell.contentView.bounds.height)
    }

    func test_fittingHeight_fitsPillContent() throws {
        let cell = createSubject()
        cell.configure(count: 0, theme: theme, onTap: nil)

        let fittingHeight = fittingHeight(for: cell, width: 320)
        cell.frame = CGRect(x: 0, y: 0, width: 320, height: fittingHeight)
        cell.layoutIfNeeded()

        let pill = try XCTUnwrap(containerPill(in: cell))
        XCTAssertEqual(fittingHeight, pill.frame.height, accuracy: 0.5)
    }

    /// Guards against the pill overflowing its section, which made it overlap the following homepage section
    func test_fittingHeight_growsWhenLabelWraps() {
        let cell = createSubject()
        cell.configure(count: 0, theme: theme, onTap: nil)

        let wideHeight = fittingHeight(for: cell, width: 320)
        let narrowHeight = fittingHeight(for: cell, width: 140)

        XCTAssertGreaterThan(narrowHeight, wideHeight)
    }

    private func fittingHeight(for cell: TrackerBlockerModuleCell, width: CGFloat) -> CGFloat {
        return cell.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func createSubject() -> TrackerBlockerModuleCell {
        let cell = TrackerBlockerModuleCell(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        trackForMemoryLeaks(cell)
        return cell
    }

    /// The count is bold and the surrounding copy is not; the count's position within the string depends on the
    /// localized format, so the unbolded run is sampled from whichever side of it has characters.
    private func runFonts(in cell: TrackerBlockerModuleCell) throws -> (bold: UIFont?, regular: UIFont?) {
        let attributedText = try XCTUnwrap(titleLabel(in: cell)?.attributedText)
        let string = attributedText.string
        let numberText = Self.count.formatted(.number.notation(.compactName))
        let boldRange = NSRange(try XCTUnwrap(string.range(of: numberText)), in: string)
        let regularLocation = boldRange.location > 0 ? 0 : NSMaxRange(boldRange)

        XCTAssertLessThan(regularLocation, attributedText.length, "Expected copy surrounding the count")

        return (attributedText.attribute(.font, at: boldRange.location, effectiveRange: nil) as? UIFont,
                attributedText.attribute(.font, at: regularLocation, effectiveRange: nil) as? UIFont)
    }

    private func titleLabel(in view: UIView) -> UILabel? {
        return allSubviews(in: view).first {
            $0.accessibilityIdentifier == AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.titleLabel
        } as? UILabel
    }

    private func containerPill(in view: UIView) -> UIView? {
        return allSubviews(in: view).first {
            $0.accessibilityIdentifier == AccessibilityIdentifiers.FirefoxHomepage.TrackerBlockerModule.containerPill
        }
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        return view.subviews + view.subviews.flatMap { allSubviews(in: $0) }
    }
}
