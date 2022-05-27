// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class FxHomeCustomizeButtonViewModel {
    // Customize button is always present at the bottom of the page
}

// MARK: FXHomeViewModelProtocol
extension FxHomeCustomizeButtonViewModel: FXHomeViewModelProtocol {

    var sectionType: FirefoxHomeSectionType {
        return .customizeHome
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

    var isEnabled: Bool {
        return true
    }
}
