// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// An empty cell to show when a row is incomplete
class EmptyTopSiteCell: UICollectionViewCell, ReusableCell {
    
    lazy private var emptyBG: UIView = .build { view in
        view.layer.cornerRadius = TopSiteItemCell.UX.cellCornerRadius
        view.layer.borderWidth = TopSiteItemCell.UX.borderWidth
        view.layer.borderColor = TopSiteItemCell.UX.borderColor.cgColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(emptyBG)
        
        NSLayoutConstraint.activate([
            emptyBG.topAnchor.constraint(equalTo: contentView.topAnchor),
            emptyBG.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            emptyBG.widthAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.width),
            emptyBG.heightAnchor.constraint(equalToConstant: TopSiteItemCell.UX.imageBackgroundSize.height),
            emptyBG.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
