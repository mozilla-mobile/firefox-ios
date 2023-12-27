// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Customize button is always present at the bottom of the page
class CustomizeHomepageSectionViewModel {
    var theme: Theme
    var onTapAction: ((UIButton) -> Void)?

    init(theme: Theme) {
        self.theme = theme
    }
}

// MARK: HomeViewModelProtocol
extension CustomizeHomepageSectionViewModel: HomepageViewModelProtocol {
    var sectionType: HomepageSectionType {
        return .customizeHome
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: HomepageViewModel.UX.spacingBetweenSections,
            leading: leadingInset,
            bottom: HomepageViewModel.UX.spacingBetweenSections,
            trailing: 0)
        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        return true
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

// MARK: FxHomeSectionHandler
extension CustomizeHomepageSectionViewModel: HomepageSectionHandler {
    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        guard let customizeHomeCell = cell as? CustomizeHomepageSectionCell else { return UICollectionViewCell() }
        customizeHomeCell.configure(onTapAction: onTapAction, theme: theme)
        return customizeHomeCell
    }
}
