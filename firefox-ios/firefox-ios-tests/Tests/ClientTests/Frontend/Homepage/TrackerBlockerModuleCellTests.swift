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

    private func createSubject() -> TrackerBlockerModuleCell {
        let cell = TrackerBlockerModuleCell(frame: CGRect(x: 0, y: 0, width: 320, height: 44))
        trackForMemoryLeaks(cell)
        return cell
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
