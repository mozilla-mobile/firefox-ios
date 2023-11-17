// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core
import Common

protocol NTPBookmarkNudgeCellDelegate: AnyObject {
    func nudgeCellOpenBookmarks()
    func nudgeCellDismiss()
}

final class NTPBookmarkNudgeCellViewModel {
    weak var delegate: NTPBookmarkNudgeCellDelegate?
    var theme: Theme
    
    init(delegate: NTPBookmarkNudgeCellDelegate? = nil, theme: Theme) {
        self.delegate = delegate
        self.theme = theme
    }
}

extension NTPBookmarkNudgeCellViewModel: HomepageViewModelProtocol {

    func setTheme(theme: Theme) {
        self.theme = theme
    }
    

    var sectionType: HomepageSectionType {
        return .bookmarkNudge
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(200))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection, bottomSpacing: 8)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        User.shared.showsBookmarksNTPNudgeCard()
    }
}

extension NTPBookmarkNudgeCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = cell as? NTPBookmarkNudgeCell {
            cell.closeHandler = { [weak self] in
                self?.delegate?.nudgeCellDismiss()
            }
            
            cell.openBookmarksHandler = { [weak self] in
                self?.delegate?.nudgeCellOpenBookmarks()
            }
        }
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {}
}
