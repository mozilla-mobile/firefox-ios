// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class HomeLogoHeaderViewModel {
    struct UX {
        static let bottomSpacing: CGFloat = 8
    }
}

// MARK: HomeViewModelProtocol
extension HomeLogoHeaderViewModel: HomepageViewModelProtocol, FeatureFlaggable {

    var sectionType: HomepageSectionType {
        return .logoHeader
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        // different top insets for different search bar layouts
        let height = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let pos: SearchBarPosition = FeatureFlagsManager.shared.getCustomState(for: .searchBarPosition) ?? .top
        let factor = pos == .bottom ? 0.1 : 0.05

        section.contentInsets = NSDirectionalEdgeInsets(
            top: height * factor,
            leading: 0,
            bottom: UX.bottomSpacing,
            trailing: 0)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        true
    }

    func refreshData(for traitCollection: UITraitCollection,
                     isPortrait: Bool = UIWindow.isPortrait,
                     device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {}
}

extension HomeLogoHeaderViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let logoHeaderCell = cell as? NTPLogoCell else { return UICollectionViewCell() }
        return logoHeaderCell
    }
}
