/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/**
 * creates a view that consists of an image and a title.
 * the image view is displayed at the center top of the
 **/
class MenuItemCollectionViewCell: UICollectionViewCell {

    var padding: CGFloat = 5.0

    lazy var menuImageView: UIImageView = UIImageView()
    lazy var menuTitleLabel: UILabel = {
        let menuTitleLabel = UILabel()
        menuTitleLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        menuTitleLabel.numberOfLines = 0
        menuTitleLabel.textAlignment = NSTextAlignment.Center
        return menuTitleLabel
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.contentView.addSubview(menuImageView)

        self.contentView.addSubview(menuTitleLabel)

        menuImageView.snp_makeConstraints { make in
            make.centerX.equalTo(self)
            make.bottom.equalTo(self.snp_centerYWithinMargins)
        }

        menuTitleLabel.snp_makeConstraints { make in
            make.top.equalTo(menuImageView.snp_bottom).offset(padding)
            make.centerX.equalTo(self)
            make.bottom.greaterThanOrEqualTo(self).offset(-padding)
            make.left.lessThanOrEqualTo(self).offset(2 * padding)
            make.right.lessThanOrEqualTo(self).offset(-(2 * padding))
        }

        self.isAccessibilityElement = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        menuImageView.image = nil
        menuTitleLabel.text = nil
    }
}
