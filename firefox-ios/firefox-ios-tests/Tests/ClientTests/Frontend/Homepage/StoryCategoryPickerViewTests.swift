// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import UIKit

@testable import Client

@MainActor
final class StoryCategoryPickerViewTests: XCTestCase {
    func test_configure_withEmptyCategories_hidesView() {
        let view = createSubject()

        view.configure(categories: [], selectedNewsfeedCategoryID: nil, onSelection: nil)

        XCTAssertTrue(view.isHidden)
        XCTAssertTrue(chipButtons(in: view).isEmpty)
    }

    func test_configure_withCategories_showsViewAndPrependsAllCategory() {
        let view = createSubject()

        view.configure(categories: testCategories, selectedNewsfeedCategoryID: nil, onSelection: nil)

        let buttons = chipButtons(in: view)

        XCTAssertFalse(view.isHidden)
        XCTAssertEqual(buttons.count, 3)
        XCTAssertEqual(buttons.map { $0.configuration?.title }, [
            .FirefoxHomepage.Pocket.AllStoryCategories,
            "Technology",
            "Science",
        ])
    }

    func test_configure_withNilSelectedCategory_selectsAllCategory() {
        let view = createSubject()

        view.configure(categories: testCategories, selectedNewsfeedCategoryID: nil, onSelection: nil)

        XCTAssertTrue(button(withA11yID: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory,
                             in: view)?.isSelected == true)
        XCTAssertTrue(button(withA11yID: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory + ".technology",
                             in: view)?.isSelected == false)
    }

    func test_configure_withSelectedFeedID_selectsMatchingCategory() {
        let view = createSubject()

        view.configure(categories: testCategories, selectedNewsfeedCategoryID: "technology", onSelection: nil)

        XCTAssertTrue(button(withA11yID: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory,
                             in: view)?.isSelected == false)
        XCTAssertTrue(button(withA11yID: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory + ".technology",
                             in: view)?.isSelected == true)
    }

    func test_selectingAllCategory_callsOnSelectionWithNil() {
        let view = createSubject()
        var selectedNewsfeedCategoryID: String? = "technology"

        view.configure(categories: testCategories, selectedNewsfeedCategoryID: "technology", onSelection: { newSelection in
            selectedNewsfeedCategoryID = newSelection
        })

        button(withA11yID: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory, in: view)?
            .sendActions(for: .touchUpInside)

        XCTAssertNil(selectedNewsfeedCategoryID)
    }

    func test_selectingSpecificCategory_callsOnSelectionWithFeedID() {
        let view = createSubject()
        var selectedNewsfeedCategoryID: String?

        view.configure(categories: testCategories, selectedNewsfeedCategoryID: nil, onSelection: { newSelection in
            selectedNewsfeedCategoryID = newSelection
        })

        button(withA11yID: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory + ".science", in: view)?
            .sendActions(for: .touchUpInside)

        XCTAssertEqual(selectedNewsfeedCategoryID, "science")
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

    private func createSubject() -> StoryCategoryPickerView {
        let view = StoryCategoryPickerView()
        trackForMemoryLeaks(view)
        return view
    }

    private func chipButtons(in view: UIView) -> [UIButton] {
        allSubviews(in: view).compactMap { $0 as? UIButton }.filter { $0.configuration?.title != nil }
    }

    private func button(withA11yID a11yID: String, in view: UIView) -> UIButton? {
        chipButtons(in: view).first(where: { $0.accessibilityIdentifier == a11yID })
    }

    private func allSubviews(in view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap { allSubviews(in: $0) }
    }
}
