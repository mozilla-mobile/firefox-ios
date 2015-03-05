/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ThumbnailCell: UICollectionViewCell {
    let textLabel = UILabel()
    let imageView = UIImageView()
    let margin = 10

    override init() {
        super.init()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(textLabel)
        contentView.addSubview(imageView)

        textLabel.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        textLabel.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
        textLabel.snp_makeConstraints({ make in
            make.bottom.right.equalTo(self.contentView).offset(-self.margin)
            make.left.equalTo(self.contentView).offset(self.margin)
            make.height.equalTo(26)
        })

        imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        imageView.layer.borderWidth = 1
        imageView.snp_makeConstraints({ make in
            make.top.equalTo(self.contentView).offset(self.margin)
            make.left.right.equalTo(self.textLabel)
            make.bottom.equalTo(self.textLabel.snp_top)
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}