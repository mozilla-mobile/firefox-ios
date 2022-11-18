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
    private (set) var items = [NewsCell.ViewModel]()
    private let images = Images(.init(configuration: .ephemeral))
    private let goodall = Goodall.shared
    weak var delegate: HomepageDataModelDelegate?

    init() {
        news.subscribeAndReceive(self) { [weak self] in
            guard let self = self else { return }
            var items = $0.map({ NewsCell.ViewModel(model: $0, promo: nil) })

            if let promo = Promo.current(for: .shared, using: .shared) {
                items.insert(.init(model: nil, promo: promo), at: 0)

                // filter out duplicate tree store item
                if Promo.variant(for: .shared, using: .shared) == .control {
                    items = Self.filter(items: items, excluding: "TreeStoreBFCM22")
                }
            }

            self.items = items
            self.delegate?.reloadView()
        }

        NotificationCenter.default.addObserver(self, selector: #selector(localeDidChange), name: NSLocale.currentLocaleDidChangeNotification, object: nil)

    }

    @objc func localeDidChange() {
        Goodall.shared.refresh(force: true)
    }

    static func filter(items: [NewsCell.ViewModel], excluding trackingName: String) -> [NewsCell.ViewModel] {
        items.filter({ !$0.trackingName.hasSuffix(trackingName) })
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
        return LabelButtonHeaderViewModel(title: .localized(.stories), isButtonHidden: true)
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
        let num = Promo.isEnabled(for: .shared, using: .shared) ? 4 : 3
        return min(num, items.count)
    }

    var hasData: Bool {
        numberOfItemsInSection() > 0
    }

    func refreshData(for traitCollection: UITraitCollection,
                     isPortrait: Bool = UIWindow.isPortrait,
                     device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) {

        news.load(session: .shared, force: !hasData)
    }

}

extension NTPNewsViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NewsCell else { return UICollectionViewCell() }
        let itemCount = numberOfItemsInSection()
        cell.defaultBackgroundColor = { .theme.ecosia.ntpImpactBackground }
        cell.configure(items[indexPath.row], images: images, positions: .derive(row: indexPath.row, items: itemCount))
        return cell
    }

    func didSelectItem(at indexPath: IndexPath, homePanelDelegate: HomePanelDelegate?, libraryPanelDelegate: LibraryPanelDelegate?) {

        let index = indexPath.row
        guard index >= 0, items.count > index else { return }
        let item = items[index]
        homePanelDelegate?.homePanel(didSelectURL: item.targetUrl, visitType: .link, isGoogleTopSite: false)

        if item.promo != nil {
            Analytics.Label.Navigation(rawValue: item.trackingName).map {
                Analytics.shared.promo(action: .click, for: $0)
            }
        } else {
            Analytics.shared.navigationOpenNews(item.trackingName)
        }
    }
}
