// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// An empty cell to show when a row is incomplete
class EmptyTopSiteCell: UICollectionReusableView {

    lazy private var emptyBG: UIView = {
        let view = UIView()
        view.layer.cornerRadius = TopSiteItemCell.UX.cellCornerRadius
        view.layer.borderWidth = TopSiteItemCell.UX.borderWidth
        view.layer.borderColor = TopSiteItemCell.UX.borderColor.cgColor
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(emptyBG)
        emptyBG.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(TopSiteItemCell.UX.backgroundSize)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
