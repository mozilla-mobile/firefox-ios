// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core

class NTPImpactViewModel {
    struct UX {
        static let bottomSpacing: CGFloat = 12
    }

    private let personalCounter: PersonalCounter

    init(personalCounter: PersonalCounter) {
        self.personalCounter = personalCounter
    }

    fileprivate var treesCellModel: NTPImpactCell.Model {
        let trees = Referrals.isEnabled ? User.shared.impact : User.shared.searchImpact
        return .init(trees: trees, searches: personalCounter.state!, style: .ntp)
    }

    weak var cell: NTPImpactCell?
}

// MARK: HomeViewModelProtocol
extension NTPImpactViewModel: HomepageViewModelProtocol {

    var sectionType: HomepageSectionType {
        return .impact
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

        let insets = sectionType.sectionInsets(traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: 0,
            leading: insets,
            bottom: UX.bottomSpacing,
            trailing: insets)

        // Adding a header if needed
        if ntpLayoutHighlightText() != nil {
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                          heightDimension: .absolute(1.0))
            let header = NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top)
            section.boundarySupplementaryItems = [header]
        }
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

extension NTPImpactViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPImpactCell else { return UICollectionViewCell() }
        cell.display(treesCellModel)
        self.cell = cell
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {
        homePanelDelegate?.homePanelDidRequestToOpenImpact()
    }
}

extension NTPImpactViewModel: NTPLayoutHighlightDataSource {
    func ntpLayoutHighlightText() -> String? {
        return NTPTooltip.highlight(for: User.shared)?.text
    }
}
