// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core
import Common

protocol NTPLibraryDelegate: AnyObject {
    func libraryCellOpenBookmarks()
    func libraryCellOpenHistory()
    func libraryCellOpenReadlist()
    func libraryCellOpenDownloads()
}

final class NTPLibraryCellViewModel {
    weak var delegate: NTPLibraryDelegate?
    var theme: Theme
    
    init(delegate: NTPLibraryDelegate? = nil, theme: Theme) {
        self.delegate = delegate
        self.theme = theme
    }
}

// MARK: HomeViewModelProtocol
extension NTPLibraryCellViewModel: HomepageViewModelProtocol {
        
    func setTheme(theme: Theme) {
        self.theme = theme
    }

    var sectionType: HomepageSectionType {
        return .libraryShortcuts
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(100.0))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection, bottomSpacing: 8)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        true
    }
}

extension NTPLibraryCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        (cell as! NTPLibraryCell).delegate = delegate
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {}
}
