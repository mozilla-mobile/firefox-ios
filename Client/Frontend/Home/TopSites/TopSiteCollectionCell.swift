// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The View that describes the topSite cell that appears in the tableView.
class TopSiteCollectionCell: UICollectionViewCell, ReusableCell {

    var viewModel: FxHomeTopSitesViewModel?

    let EmptyCellIdentifier = "TopSiteItemEmptyCell"
    let CellIdentifier = "TopSiteItemCell"

    lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewCompositionalLayout(section: layoutSection)
//        let layout = TopSiteFlowLayout()
//        layout.itemSize = UX.ItemSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TopSiteItemCell.self, forCellWithReuseIdentifier: CellIdentifier)
        collectionView.register(EmptyTopSiteCell.self, forCellWithReuseIdentifier: EmptyCellIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.isScrollEnabled = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.layer.masksToBounds = false
        
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        accessibilityIdentifier = AccessibilityIdentifiers.FirefoxHomepage.TopSites.section
        backgroundColor = UIColor.clear

        setupLayout()
        collectionView.addGestureRecognizer(longPressRecognizer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Helpers

    func reloadLayout() {
        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout(section: layoutSection)
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }

    private func setupLayout() {
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

    private var layoutSection: NSCollectionLayoutSection {
        let numberOfHorizontalItems = FxHomeTopSitesViewModel.numberOfHorizontalItems(for: traitCollection)
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1/4), //.estimated(TopSiteItemCell.UX.cellSize.width), //.fractionalWidth(CGFloat(1/numberOfHorizontalItems)),
            heightDimension: .fractionalHeight(1) // .estimated(TopSiteItemCell.UX.cellSize.height)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let numberOfRows = CGFloat(viewModel?.numberOfRows ?? 2)
        let fractionHeight = 1/numberOfRows
        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1),
            heightDimension: .fractionalHeight(fractionHeight) //.estimated(TopSiteItemCell.UX.cellSize.height)
        )

        let subItems = Array(repeating: item, count: 4)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: subItems)
//        group.interItemSpacing = FxHomeHorizontalCellUX.interItemSpacing
//        group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0,
//                                                      bottom: 0, trailing: FxHomeHorizontalCellUX.interGroupSpacing)

        let section = NSCollectionLayoutSection(group: group)
        return section
    }

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    @objc private func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let viewModel = viewModel // , let onLongPressTileAction = viewModel.onLongPressTileAction
        else { return }

//        let parentIndexPath = IndexPath(row: indexPath.row, section: viewModel.pocketShownInSection)
//        onLongPressTileAction(parentIndexPath)

        // TODO: Laurie - also make sure filler cells doesnt long press
//        presentContextMenu(for: topSiteIndexPath)
    }
}

extension TopSiteCollectionCell: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let viewModel = viewModel else { return 0 }
        let items = FxHomeTopSitesViewModel.numberOfHorizontalItems(for: traitCollection) * viewModel.numberOfRows
        print("Laurie - itemsCount: \(items)")
        return items
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as? TopSiteItemCell,
           let contentItem = viewModel?.tileManager.getSite(index: indexPath.row) {
            cell.configureWithTopSiteItem(contentItem)
            print("Laurie - configuring cell \(indexPath)")
            return cell

        } else if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: EmptyCellIdentifier, for: indexPath) as? EmptyTopSiteCell {
            print("Laurie - configuring empty cell \(indexPath)")
            return cell
        }

        return UICollectionViewCell()
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let contentItem = viewModel?.tileManager.getSite(index: indexPath.row) else { return }
        viewModel?.urlPressedHandler?(contentItem, indexPath)
    }
}
