// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// TODO: Laurie - UX for pocket
class FxHomePocketCollectionCell: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    var viewModel: FxHomePocketViewModel?

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout(section: layoutSection)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.backgroundColor = UIColor.clear
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(FxHomeHorizontalCell.self, forCellWithReuseIdentifier: FxHomeHorizontalCell.cellIdentifier)

        return collectionView
    }()

    // MARK: - Inits

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private

    private func setupLayout() {
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 2),
            collectionView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            collectionView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }

    private var layoutSection: NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .estimated(JumpBackInCollectionCellUX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: FirefoxHomeJumpBackInViewModel.widthDimension,
            heightDimension: .estimated(JumpBackInCollectionCellUX.cellHeight)
        )

        let subItems = Array(repeating: item, count: FirefoxHomeJumpBackInViewModel.maxNumberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = JumpBackInCollectionCellUX.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0,
                                                      bottom: 0, trailing: JumpBackInCollectionCellUX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuous
        return section
    }
}


// MARK: - UICollectionViewDataSource
extension FxHomePocketCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.pocketStories.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FxHomeHorizontalCell.cellIdentifier, for: indexPath) as! FxHomeHorizontalCell
        guard let viewModel = viewModel else { return UICollectionViewCell() }
        cell.tag = indexPath.item

        // TODO: More button -> headerView.moreButton.setTitle(.PocketMoreStoriesText, for: .normal)

//        viewModel.configureCellForTab(item: <#T##Tab#>, cell: <#T##FxHomeHorizontalCell#>, indexPath: <#T##IndexPath#>)

//        if indexPath.row == (viewModel.jumpBackInList.itemsToDisplay - 1),
//           let group = viewModel.jumpBackInList.group {
//            viewModel.configureCellForGroups(group: group, cell: cell, indexPath: indexPath)
//        } else {
//            viewModel.configureCellForTab(item: viewModel.jumpBackInList.tabs[indexPath.row], cell: cell, indexPath: indexPath)
//        }

        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FxHomePocketCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }
        // TODO: Click action
        // TODO: Long press

//        if indexPath.row == viewModel.jumpBackInList.itemsToDisplay - 1,
//           let group = viewModel.jumpBackInList.group {
//            viewModel.switchTo(group: group)
//
//        } else {
//            let tab = viewModel.jumpBackInList.tabs[indexPath.row]
//            viewModel.switchTo(tab: tab)
//        }

//        var site: Site? = nil
//        switch section {
//        case .pocket:
//            // Pocket site extra
//            site = Site(url: pocketStories[index].url.absoluteString, title: pocketStories[index].title)
//            let key = TelemetryWrapper.EventExtraKey.pocketTilePosition.rawValue
//            let siteExtra = [key : "\(index)"]
//
//            // Origin extra
//            let originExtra = TelemetryWrapper.getOriginExtras(isZeroSearch: isZeroSearch)
//            let extras = originExtra.merge(with: siteExtra)
//
//            TelemetryWrapper.recordEvent(category: .action,
//                                         method: .tap,
//                                         object: .pocketStory,
//                                         value: nil,
//                                         extras: extras)
//        case .topSites, .libraryShortcuts, .jumpBackIn, .recentlySaved, .historyHighlights, .customizeHome:
//            return
//        }
//
//        if let site = site {
//            showSiteWithURLHandler(URL(string: site.url)!)
//        }
    }
}
