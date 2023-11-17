// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Core
import Common

typealias NTPAboutEcosiaCellDelegate = SharedHomepageCellDelegate & SharedHomepageCellLayoutDelegate

final class NTPAboutEcosiaCellViewModel {
    let sections = AboutEcosiaSection.allCases
    weak var delegate: NTPAboutEcosiaCellDelegate?
    var expandedIndex: IndexPath?
    var theme: Theme
    
    init(theme: Theme) {
        self.theme = theme
    }
    
    func deselectExpanded() {
        guard let index = expandedIndex else { return }
        expandedIndex = nil
        delegate?.invalidateLayout(at: [index])
    }
}

extension NTPAboutEcosiaCellViewModel: HomepageViewModelProtocol {
            
    func setTheme(theme: Theme) {
        self.theme = theme
    }
    
    var isEnabled: Bool {
        User.shared.showAboutEcosia
    }
    
    var sectionType: HomepageSectionType {
        .aboutEcosia
    }
    
    var headerViewModel: LabelButtonHeaderViewModel {
        .init(title: .localized(.aboutEcosia),
              isButtonHidden: true)
    }
    
    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1),
                              heightDimension: .estimated(100))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1),
                              heightDimension: .estimated(100)),
            subitem: item,
            count: 1
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = sectionType.sectionInsets(traitCollection)
        section.boundarySupplementaryItems = [
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                    heightDimension: .estimated(100)),
                  elementKind: UICollectionView.elementKindSectionHeader,
                  alignment: .top)
        ]
        return section
    }
    
    func numberOfItemsInSection() -> Int {
        sections.count
    }
}

extension NTPAboutEcosiaCellViewModel: HomepageSectionHandler {
    
    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPAboutEcosiaCell else {
            return UICollectionViewCell()
        }
        cell.configure(section: sections[indexPath.row], viewModel: self)
        return cell
    }
    
    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {
        guard let previousIndex = expandedIndex else {
            expandedIndex = indexPath
            delegate?.invalidateLayout(at: [indexPath])
            return
        }
        if previousIndex == indexPath {
            deselectExpanded()
        } else {
            expandedIndex = indexPath
            delegate?.invalidateLayout(at: [previousIndex, indexPath])
        }
    }
}
