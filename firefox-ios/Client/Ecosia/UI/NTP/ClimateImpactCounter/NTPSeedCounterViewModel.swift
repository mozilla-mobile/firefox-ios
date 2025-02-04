// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

class NTPSeedCounterViewModel {
    struct UX {
        static let topInset: CGFloat = 24
    }

    private let profile: Profile
    weak var delegate: NTPSeedCounterDelegate?
    var onTapAction: ((UIButton) -> Void)?
    var theme: Theme

    init(profile: Profile, theme: Theme) {
        self.profile = profile
        self.theme = theme
    }
}

// MARK: HomeViewModelProtocol
extension NTPSeedCounterViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .climateImpactCounter
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(50))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(50))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.topInset,
            leading: 0,
            bottom: 0,
            trailing: 0)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        SeedCounterNTPExperiment.isEnabled
    }

    func screenWasShown() {
        SeedCounterNTPExperiment.trackSeedCollectionIfNewDayAppOpening()
        SeedCounterNTPExperiment.progressManagerType.collectDailySeed()
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

extension NTPSeedCounterViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let seedCounterCell = cell as? NTPSeedCounterCell else { return UICollectionViewCell() }
        seedCounterCell.delegate = delegate
        seedCounterCell.applyTheme(theme: theme)
        return seedCounterCell
    }
}
