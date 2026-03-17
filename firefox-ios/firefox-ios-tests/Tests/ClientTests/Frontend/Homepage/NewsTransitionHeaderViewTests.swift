// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import UIKit

@testable import Client

@MainActor
final class NewsTransitionHeaderViewTests: XCTestCase {
    private let theme = DarkTheme()
    private let sectionHeaderState = SectionHeaderConfiguration(
        title: "Top Stories",
        a11yIdentifier: "news-transition-header"
    )

    func test_configure_withTransitionEnabledAndZeroProgress_showsAffordance() {
        let view = createSubject()

        view.configure(state: sectionHeaderState, textColor: nil, theme: theme, transitionEnabled: true)
        view.setTransitionProgress(0)
        view.layoutIfNeeded()

        XCTAssertEqual(affordanceView(in: view)?.alpha, 1)
        XCTAssertEqual(labelHeaderView(in: view)?.alpha, 0)
    }

    func test_configure_withTransitionEnabledAndFullProgress_showsSectionTitle() {
        let view = createSubject()

        view.configure(state: sectionHeaderState, textColor: nil, theme: theme, transitionEnabled: true)
        view.setTransitionProgress(1)
        view.layoutIfNeeded()

        XCTAssertEqual(affordanceView(in: view)?.alpha, 0)
        XCTAssertEqual(labelHeaderView(in: view)?.alpha, 1)
    }

    func test_configure_withTransitionDisabled_showsSectionTitleOnly() {
        let view = createSubject()

        view.configure(state: sectionHeaderState, textColor: nil, theme: theme, transitionEnabled: false)
        view.setTransitionProgress(0)
        view.layoutIfNeeded()

        XCTAssertEqual(affordanceView(in: view)?.alpha, 0)
        XCTAssertEqual(labelHeaderView(in: view)?.alpha, 1)
        XCTAssertEqual(affordanceView(in: view)?.accessibilityElementsHidden, true)
        XCTAssertEqual(labelHeaderView(in: view)?.accessibilityElementsHidden, false)
    }

    private func createSubject() -> NewsTransitionHeaderView {
        let view = NewsTransitionHeaderView(frame: CGRect(x: 0,
                                                          y: 0,
                                                          width: 320,
                                                          height: NewsAffordanceHeaderView.UX.totalHeight
                                                         )
        )
        trackForMemoryLeaks(view)
        return view
    }

    private func affordanceView(in view: UIView) -> NewsAffordanceHeaderView? {
        return allSubviews(in: view).compactMap { $0 as? NewsAffordanceHeaderView }.first
    }

    private func labelHeaderView(in view: UIView) -> LabelButtonHeaderView? {
        return allSubviews(in: view).compactMap { $0 as? LabelButtonHeaderView }.first
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        return view.subviews + view.subviews.flatMap { allSubviews(in: $0) }
    }
}
