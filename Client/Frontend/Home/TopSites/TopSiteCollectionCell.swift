// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The View that describes the topSite cell that appears in the tableView.
class TopSiteCollectionCell: UICollectionViewCell, ReusableCell {

    // TODO: Laurie - need to set this
    var viewModel: FxHomeTopSitesViewModel?

    struct UX {
        static let CellIdentifier = "TopSiteItemCell"
        static let ItemSize = CGSize(width: 65, height: 90)
    }

    lazy var collectionView: UICollectionView = {
        let layout  = TopSiteFlowLayout()
        layout.itemSize = UX.ItemSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TopSiteItemCell.self, forCellWithReuseIdentifier: UX.CellIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
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

    private func setupLayout() {
        contentView.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.trailingAnchor),
        ])
    }

    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func longPress(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else { return }

        let point = longPressGestureRecognizer.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point),
              let viewModel = viewModel // , let onLongPressTileAction = viewModel.onLongPressTileAction
        else { return }

//        let parentIndexPath = IndexPath(row: indexPath.row, section: viewModel.pocketShownInSection)
//        onLongPressTileAction(parentIndexPath)

        // TODO: Laurie
//        presentContextMenu(for: topSiteIndexPath)
    }
}

extension TopSiteCollectionCell: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.viewModel?.tileManager.content.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: UX.CellIdentifier, for: indexPath) as? TopSiteItemCell,
              let contentItem = viewModel?.tileManager.content[indexPath.row]
        else {
            return UICollectionViewCell()
        }

        cell.configureWithTopSiteItem(contentItem)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let contentItem = viewModel?.tileManager.content[indexPath.row] else { return }
        viewModel?.urlPressedHandler?(contentItem, indexPath)
    }
}
