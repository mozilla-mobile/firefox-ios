// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class HomeLogoHeaderViewModel {
    
    struct UX {
        static let botttomSpacing: CGFloat = 12
    }
    
    private let profile: Profile
    var onTapAction: ((UIButton) -> Void)?
    
    init(profile: Profile) {
        self.profile = profile
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
        
        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: leadingInset,
                                                        bottom: UX.botttomSpacing, trailing: 0)
        
        return section
    }
    
    func numberOfItemsInSection(for traitCollection: UITraitCollection) -> Int {
        return 1
    }
    
    var isEnabled: Bool {
        return featureFlags.isFeatureEnabled(.wallpapers, checking: .buildOnly)
    }
}

extension HomeLogoHeaderViewModel: HomepageSectionHandler {
    
    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let logoHeaderCell = cell as? HomeLogoHeaderCell else { return UICollectionViewCell() }
        logoHeaderCell.configure(onTapAction: onTapAction)
        return logoHeaderCell
    }
}
