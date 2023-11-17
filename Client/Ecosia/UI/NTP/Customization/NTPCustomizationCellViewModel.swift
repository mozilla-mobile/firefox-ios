// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common

protocol NTPCustomizationCellDelegate: AnyObject {
    func openNTPCustomizationSettings()
}

final class NTPCustomizationCellViewModel {
    weak var delegate: NTPCustomizationCellDelegate?
    var theme: Theme
    
    init(delegate: NTPCustomizationCellDelegate? = nil, theme: Theme) {
        self.delegate = delegate
        self.theme = theme
    }
}

extension NTPCustomizationCellViewModel: HomepageViewModelProtocol {
    
    func setTheme(theme: Theme) {
        self.theme = theme
    }
    
    var sectionType: HomepageSectionType { .ntpCustomization }
    
    var headerViewModel: LabelButtonHeaderViewModel { .emptyHeader }
    
    var isEnabled: Bool { true }
    
    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1),
                              heightDimension: .estimated(NTPCustomizationCell.UX.buttonHeight))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1),
                              heightDimension: .estimated(NTPCustomizationCell.UX.buttonHeight)),
            subitem: item,
            count: 1
        )
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = sectionType.sectionInsets(traitCollection)
        return section
    }
    
    func numberOfItemsInSection() -> Int { 1 }
}

extension NTPCustomizationCellViewModel: HomepageSectionHandler {
    
    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPCustomizationCell else {
            return UICollectionViewCell()
        }
        cell.delegate = delegate
        return cell
    }
}
