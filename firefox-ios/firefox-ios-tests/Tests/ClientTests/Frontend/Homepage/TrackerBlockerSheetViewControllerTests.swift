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

    // MARK: - Helpers

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
