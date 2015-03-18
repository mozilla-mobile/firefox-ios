/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let BorderColor = UIColor(rgb: 0xeeeeee)
private let LabelFont = UIFont(name: "FiraSans-Regular", size: 11)
private let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
private let CellInsets = UIEdgeInsetsMake(8, 8, 8, 8)
private let TextMargin = 5

class ThumbnailCell: UICollectionViewCell {
    let textLabel = UILabel()
    let imageView = UIImageView()

    override init() {
        super.init()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(textLabel)
        contentView.addSubview(imageView)

        imageView.layer.borderColor = BorderColor.CGColor
        imageView.layer.borderWidth = 2
        imageView.layer.cornerRadius = 3
        imageView.snp_makeConstraints({ make in
            make.top.left.right.equalTo(self.contentView).insets(CellInsets)
            return
        })

        textLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        textLabel.font = LabelFont
        textLabel.textColor = LabelColor
        textLabel.snp_makeConstraints({ make in
            make.top.equalTo(self.imageView.snp_bottom).offset(TextMargin)
            make.left.right.bottom.equalTo(self.contentView).insets(CellInsets)
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}