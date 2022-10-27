// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core

class NTPNewsViewModel {
    struct UX {
        static let bottomSpacing: CGFloat = 12
    }

    private let news = News()
    private (set) var items = [NewsModel]()
    private let images = Images(.init(configuration: .ephemeral))
    weak var delegate: HomepageDataModelDelegate?

    init() {
        news.subscribeAndReceive(self) { [weak self] in
            guard let self = self else { return }
            self.items = $0
            self.delegate?.reloadView()
        }
    }

}

// MARK: HomeViewModelProtocol
extension NTPNewsViewModel: HomepageViewModelProtocol {
    var isEnabled: Bool {
        true
    }

    var sectionType: HomepageSectionType {
        return .news
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return LabelButtonHeaderViewModel(title: "Ecosia news", isButtonHidden: true)
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

        let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                          heightDimension: .estimated(100.0))
        let header = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: size,
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top)
        let footer = NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: size,
            elementKind: UICollectionView.elementKindSectionFooter,
            alignment: .bottom)
        section.boundarySupplementaryItems = [header, footer]
        return section
    }

    func numberOfItemsInSection() -> Int {
        return min(3, items.count)
    }

    var hasData: Bool {
        !items.isEmpty
    }

    func refreshData(for traitCollection: UITraitCollection,
                     isPortrait: Bool = UIWindow.isPortrait,
                     device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {

        news.load(session: .shared, force: items.isEmpty)
    }

}

extension NTPNewsViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NewsCell else { return UICollectionViewCell() }
        let itemCount = numberOfItemsInSection()
        cell.configure(items[indexPath.row], images: images, positions: .derive(row: indexPath.row, items: itemCount))
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {

        let index = indexPath.row
        guard index >= 0, items.count > index else { return }
        Analytics.shared.navigationOpenNews(items[index].trackingName)
        homePanelDelegate?.homePanel(didSelectURL: items[index].targetUrl, visitType: .link, isGoogleTopSite: false)
    }
}
