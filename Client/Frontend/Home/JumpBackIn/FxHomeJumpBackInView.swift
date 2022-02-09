// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit
import Storage

struct JumpBackInCollectionCellUX {
    static let verticalCellSpacing: CGFloat = 8
    static let iPadHorizontalSpacing: CGFloat = 48
    static let iPadCellSpacing: CGFloat = 16
}

class FxHomeJumpBackInCollectionCell: UICollectionViewCell, ReusableCell {

    // MARK: - Properties
    var viewModel: FirefoxHomeJumpBackInViewModel?

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

    // MARK: - Helpers

    func reloadLayout() {
        viewModel?.refreshData()
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(section: layoutSection)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
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
            heightDimension: .estimated(FxHomeHorizontalCellUX.cellHeight)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: FirefoxHomeJumpBackInViewModel.widthDimension,
            heightDimension: .estimated(FxHomeHorizontalCellUX.cellHeight)
        )

        let subItems = Array(repeating: item, count: FirefoxHomeJumpBackInViewModel.maxNumberOfItemsInColumn)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: groupSize, subitems: subItems)
        group.interItemSpacing = FxHomeHorizontalCellUX.interItemSpacing
        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0,
                                                      bottom: 0, trailing: FxHomeHorizontalCellUX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)

        section.orthogonalScrollingBehavior = .continuous
        return section
    }
}

// MARK: - UICollectionViewDataSource
extension FxHomeJumpBackInCollectionCell: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.jumpBackInList.itemsToDisplay ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FxHomeHorizontalCell.cellIdentifier, for: indexPath) as! FxHomeHorizontalCell
        guard let viewModel = viewModel else { return UICollectionViewCell() }

        if indexPath.row == (viewModel.jumpBackInList.itemsToDisplay - 1),
           let group = viewModel.jumpBackInList.group {
            configureCellForGroups(group: group, cell: cell, indexPath: indexPath)
        } else {
            configureCellForTab(item: viewModel.jumpBackInList.tabs[indexPath.row], cell: cell, indexPath: indexPath)
        }

        return cell
    }

    private func configureCellForGroups(group: ASGroup<Tab>, cell: FxHomeHorizontalCell, indexPath: IndexPath) {
        let firstGroupItem = group.groupedItems.first
        let site = Site(url: firstGroupItem?.lastKnownUrl?.absoluteString ?? "", title: firstGroupItem?.lastTitle ?? "")

        let descriptionText = String.localizedStringWithFormat(.FirefoxHomepage.JumpBackIn.GroupSiteCount, group.groupedItems.count)
        let faviconImage = UIImage(imageLiteralResourceName: "recently_closed").withRenderingMode(.alwaysTemplate)
        let cellViewModel = FxHomeHorizontalCellViewModel(titleText: group.searchTerm.localizedCapitalized,
                                                          descriptionText: descriptionText,
                                                          tag: indexPath.item,
                                                          hasFavicon: true,
                                                          favIconImage: faviconImage)
        cell.configure(viewModel: cellViewModel)

        guard let viewModel = viewModel else { return }
        viewModel.getHeroImage(forSite: site) { image in
            guard cell.tag == indexPath.item else { return }
            cell.heroImage.image = image
        }
    }

    private func configureCellForTab(item: Tab, cell: FxHomeHorizontalCell, indexPath: IndexPath) {
        let itemURL = item.lastKnownUrl?.absoluteString ?? ""
        let site = Site(url: itemURL, title: item.displayTitle)
        let descriptionText = site.tileURL.shortDisplayString.capitalized

        let cellViewModel = FxHomeHorizontalCellViewModel(titleText: site.title,
                                                          descriptionText: descriptionText,
                                                          tag: indexPath.item,
                                                          hasFavicon: true)
        cell.configure(viewModel: cellViewModel)

        guard let viewModel = viewModel else { return }
        /// Sets a small favicon in place of the hero image in case there's no hero image
        viewModel.getFaviconImage(forSite: site) { image in
            guard cell.tag == indexPath.item else { return }
            cell.faviconImage.image = image

            if cell.heroImage.image == nil {
                cell.fallbackFaviconImage.image = image
            }
        }

        /// Replace the fallback favicon image when it's ready or available
        viewModel.getHeroImage(forSite: site) { image in
            guard cell.tag == indexPath.item else { return }

            // If image is a square use it as a favicon
            if image?.size.width == image?.size.height {
                cell.fallbackFaviconImage.image = image
                return
            }

            cell.setFallBackFaviconVisibility(isHidden: true)
            cell.heroImage.image = image
        }
    }
}

// MARK: - UICollectionViewDelegate
extension FxHomeJumpBackInCollectionCell: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }
        if indexPath.row == viewModel.jumpBackInList.itemsToDisplay - 1,
           let group = viewModel.jumpBackInList.group {
            viewModel.switchTo(group: group)

        } else {
            let tab = viewModel.jumpBackInList.tabs[indexPath.row]
            viewModel.switchTo(tab: tab)
        }
    }
}
