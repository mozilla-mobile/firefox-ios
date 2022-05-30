// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class FxHomeLogoHeaderViewModel {

    private let profile: Profile
    var onTapAction: ((UIButton) -> Void)?

    init(profile: Profile) {
        self.profile = profile
    }

    func shouldRunLogoAnimation() -> Bool {
        let localesAnimationIsAvailableFor = ["en_US", "es_US"]
        guard profile.prefs.intForKey(PrefsKeys.IntroSeen) != nil,
              !UserDefaults.standard.bool(forKey: PrefsKeys.WallpaperLogoHasShownAnimation),
              localesAnimationIsAvailableFor.contains(Locale.current.identifier)
        else { return false }

        return true
    }
}

// MARK: FXHomeViewModelProtocol
extension FxHomeLogoHeaderViewModel: FXHomeViewModelProtocol, FeatureFlaggable {

    var sectionType: FirefoxHomeSectionType {
        return .logoHeader
    }

    var headerViewModel: ASHeaderViewModel {
        return ASHeaderViewModel.emptyHeader
    }

    var section: NSCollectionLayoutSection {
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
        return featureFlags.isFeatureEnabled(.wallpapers, checking: .buildOnly)
    }
}

extension FxHomeLogoHeaderViewModel: FxHomeSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let logoHeaderCell = cell as? FxHomeLogoHeaderCell else { return UICollectionViewCell() }
        logoHeaderCell.configure(onTapAction: onTapAction)
        return logoHeaderCell
    }
}
