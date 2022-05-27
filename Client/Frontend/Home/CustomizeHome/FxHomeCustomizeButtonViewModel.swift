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
        return ASHeaderViewModel.emptyHeader
    }

    static var section: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        return NSCollectionLayoutSection(group: group)
    }

    var numberOfItemsInSection: Int {
        return 1
    }

    var isEnabled: Bool {
        return true
    }
}

// MARK: FxHomeSectionHandler
extension FxHomeCustomizeButtonViewModel: FxHomeSectionHandler {

    func configure(cell: UICollectionViewCell,
                   at indexPath: IndexPath) -> UICollectionViewCell {
        guard let customizeHomeCell = cell as? FxHomeCustomizeHomeView else { return UICollectionViewCell() }
        customizeHomeCell.configure(onTapAction: onTapAction)
        return customizeHomeCell
    }

}
