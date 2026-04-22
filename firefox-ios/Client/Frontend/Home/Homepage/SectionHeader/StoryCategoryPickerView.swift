// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import Foundation
import UIKit

final class StoryCategoryPickerView: UIView, ThemeApplicable {
    struct UX {
        static let topSpacing: CGFloat = 16
    }

    static let allCategoryID = "__all__"

    private lazy var chipPickerView: ChipPickerView = .build()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(
        categories: [MerinoCategoryConfiguration],
        selectedNewsfeedCategoryID: String?,
        newsfeedCategoryPickerOffsetX: CGFloat? = nil,
        onScroll: ((CGFloat) -> Void)? = nil,
        onSelection: (@MainActor (String?) -> Void)? = nil
    ) {
        let items = pickerItems(from: categories)
        let selectedPickerID = selectedNewsfeedCategoryID ?? Self.allCategoryID

        chipPickerView.configure(
            items: items,
            selectedID: selectedPickerID,
            contentOffsetX: newsfeedCategoryPickerOffsetX ?? 0,
            onScroll: onScroll,
            onSelection: { selectedID in
                onSelection?(selectedID == Self.allCategoryID ? nil : selectedID)
            }
        )
        isHidden = items.isEmpty
    }

    func applyTheme(theme: Theme) {
        chipPickerView.applyTheme(theme: theme)
    }

    func applyNewsfeedPickerState(selectedNewsfeedCategoryID: String?, newsfeedCategoryPickerOffsetX: CGFloat?) {
        chipPickerView.updateSelectedID(selectedNewsfeedCategoryID ?? Self.allCategoryID)
        chipPickerView.updateContentOffsetX(newsfeedCategoryPickerOffsetX ?? 0)
    }

    private func setupLayout() {
        addSubview(chipPickerView)

        NSLayoutConstraint.activate([
            chipPickerView.topAnchor.constraint(equalTo: topAnchor, constant: UX.topSpacing),
            chipPickerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            chipPickerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            chipPickerView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func pickerItems(from categories: [MerinoCategoryConfiguration]) -> [ChipPickerItem] {
        guard !categories.isEmpty else { return [] }

        let allItem = ChipPickerItem(
            id: Self.allCategoryID,
            title: .FirefoxHomepage.Pocket.AllStoryCategories,
            a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory
        )
        let categoryItems: [ChipPickerItem] = categories.map { category in
            return ChipPickerItem(
                id: category.feedID,
                title: category.title,
                a11yIdentifier: AccessibilityIdentifiers.FirefoxHomepage.Pocket.allCategory + "." + category.feedID
            )
        }

        return [allItem] + categoryItems
    }
}
