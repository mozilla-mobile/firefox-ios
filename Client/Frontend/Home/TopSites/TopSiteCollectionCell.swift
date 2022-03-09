// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// The View that describes the topSite cell that appears in the tableView.
class TopSiteCollectionCell: UICollectionViewCell, ReusableCell {

    struct UX {
        static let TopSiteCellIdentifier = "TopSiteItemCell"
        static let TopSiteItemSize = CGSize(width: 65, height: 90)
    }

    lazy var collectionView: UICollectionView = {
        let layout  = TopSiteFlowLayout()
        layout.itemSize = UX.TopSiteItemSize
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(TopSiteItemCell.self, forCellWithReuseIdentifier: UX.TopSiteCellIdentifier)
        collectionView.backgroundColor = UIColor.clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.layer.masksToBounds = false
        return collectionView
    }()

    weak var delegate: ASHorizontalScrollCellManager? {
        didSet {
            collectionView.delegate = delegate
            collectionView.dataSource = delegate
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        accessibilityIdentifier = "TopSitesCell"
        backgroundColor = UIColor.clear
        contentView.addSubview(collectionView)

        collectionView.snp.makeConstraints { make in
            make.edges.equalTo(contentView.safeArea.edges)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
