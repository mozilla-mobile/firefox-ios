// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Customize button is always present at the bottom of the page
class FxHomeCustomizeButtonViewModel {
    var onTapAction: ((UIButton) -> Void)?
}

// MARK: FXHomeViewModelProtocol
extension FxHomeCustomizeButtonViewModel: FXHomeViewModelProtocol {

    var sectionType: FirefoxHomeSectionType {
        return .customizeHome
    }

    var headerViewModel: ASHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let leadingInset = FirefoxHomeViewModel.UX.leadingInset(traitCollection: traitCollection)
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: leadingInset,
                                                        bottom: FirefoxHomeViewModel.UX.spacingBetweenSections, trailing: 0)
        return section
    }

    func numberOfItemsInSection(for traitCollection: UITraitCollection) -> Int {
        return 1
    }

    var isEnabled: Bool {
        return true
    }
}

// MARK: FxHomeSectionHandler
extension FxHomeCustomizeButtonViewModel: FxHomeSectionHandler {

    func configure(_ cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        guard let customizeHomeCell = cell as? FxHomeCustomizeHomeView else { return UICollectionViewCell() }
        customizeHomeCell.configure(onTapAction: onTapAction)
        return customizeHomeCell
    }

}
