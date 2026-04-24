// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Common
import UIKit

@testable import Client

@MainActor
final class NewsTransitionHeaderCellTests: XCTestCase {
    private let theme = DarkTheme()
    private let sectionHeaderConfiguration = SectionHeaderConfiguration(
        title: "Top Stories",
        a11yIdentifier: "news-transition-header"
    )

    func test_configure_withTransitionEnabledAndZeroProgress_showsAffordance() {
        let view = createSubject()

        view.configure(
            sectionHeaderConfiguration: sectionHeaderConfiguration,
            textColor: nil,
            theme: theme,
            transitionEnabled: true,
            categories: []
        )
        view.setTransitionProgress(0)
        view.layoutIfNeeded()

        XCTAssertEqual(affordanceView(in: view)?.alpha, 1)
        XCTAssertEqual(labelHeaderView(in: view)?.alpha, 0)
    }

    func test_configure_withTransitionEnabledAndFullProgress_showsSectionTitle() {
        let view = createSubject()

        view.configure(
            sectionHeaderConfiguration: sectionHeaderConfiguration,
            textColor: nil,
            theme: theme,
            transitionEnabled: true,
            categories: []
        )
        view.setTransitionProgress(1)
        view.layoutIfNeeded()

        XCTAssertEqual(affordanceView(in: view)?.alpha, 0)
        XCTAssertEqual(labelHeaderView(in: view)?.alpha, 1)
    }

    func test_configure_withTransitionDisabled_showsSectionTitleOnly() {
        let view = createSubject()

        view.configure(
            sectionHeaderConfiguration: sectionHeaderConfiguration,
            textColor: nil,
            theme: theme,
            transitionEnabled: false,
            categories: []
        )
        view.setTransitionProgress(0)
        view.layoutIfNeeded()

        XCTAssertEqual(affordanceView(in: view)?.alpha, 0)
        XCTAssertEqual(labelHeaderView(in: view)?.alpha, 1)
    }

    func test_updatePickerState_updatesCategorySelection() {
        let view = createSubject()

        view.configure(
            sectionHeaderConfiguration: sectionHeaderConfiguration,
            textColor: nil,
            theme: theme,
            transitionEnabled: false,
            categories: testCategories,
            selectedNewsfeedCategoryID: nil
        )

        view.updatePickerState(selectedNewsfeedCategoryID: "science", newsfeedCategoryPickerOffsetX: 0)

        XCTAssertTrue(button(withA11yID: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory,
                             in: view)?.isSelected == false)
        XCTAssertTrue(button(withA11yID: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory + ".science",
                             in: view)?.isSelected == true)
    }

    private var testCategories: [MerinoCategoryConfiguration] {
        [
            MerinoCategoryConfiguration(
                category: MerinoCategory(
                    feedID: "technology",
                    recommendations: [],
                    isBlocked: false,
                    isFollowed: false,
                    title: "Technology",
                    subtitle: nil,
                    receivedFeedRank: 2
                )
            ),
            MerinoCategoryConfiguration(
                category: MerinoCategory(
                    feedID: "science",
                    recommendations: [],
                    isBlocked: false,
                    isFollowed: false,
                    title: "Science",
                    subtitle: nil,
                    receivedFeedRank: 1
                )
            ),
        ]
    }

    private func createSubject() -> NewsTransitionHeaderCell {
        let view = NewsTransitionHeaderCell(frame: CGRect(x: 0, y: 0, width: 320, height: 72))
        trackForMemoryLeaks(view)
        return view
    }

    private func affordanceView(in view: UIView) -> NewsAffordanceHeaderView? {
        return allSubviews(in: view).compactMap { $0 as? NewsAffordanceHeaderView }.first
    }

    private func labelHeaderView(in view: UIView) -> LabelButtonHeaderView? {
        return allSubviews(in: view).compactMap { $0 as? LabelButtonHeaderView }.first
    }

    private func button(withA11yID a11yID: String, in view: UIView) -> UIButton? {
        return allSubviews(in: view)
            .compactMap { $0 as? UIButton }
            .first(where: { $0.accessibilityIdentifier == a11yID })
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        return view.subviews + view.subviews.flatMap { allSubviews(in: $0) }
    }
}
