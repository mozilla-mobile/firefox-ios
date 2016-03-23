//
//  MenuPageCollectionViewCell.swift
//  Client
//
//  Created by Emily Toop on 3/23/16.
//  Copyright © 2016 Mozilla. All rights reserved.
//

import UIKit

class MenuPageCollectionViewCell: UICollectionViewCell {

    var pageView: MenuPageView = MenuPageView()

    override init(frame: CGRect) {
        super.init(frame: CGRectZero)

        self.addSubview(self.pageView)
        self.pageView.snp_makeConstraints { make in
            make.edges.equalTo(self)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
