/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let BorderColor = UIColor(rgb: 0xeeeeee)
private let LabelFont = UIFont(name: UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Bold" : "HelveticaNeue", size: 11)
private let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
private let CellInsets = UIEdgeInsetsMake(8, 8, 8, 8)

private let PlaceholderImage = UIImage(named: "defaultFavicon")

struct ThumbnailCellUX {
    /// Ratio of width:height of the thumbnail image.
    static let ImageAspectRatio: Float = 1.5
}

class ThumbnailCell: UICollectionViewCell {
    let textLabel = UILabel()
    let imageView = UIImageViewAligned()

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
        imageView.clipsToBounds = true
        imageView.snp_makeConstraints({ make in
            make.top.left.right.equalTo(self.contentView).insets(CellInsets)
            make.width.equalTo(self.imageView.snp_height).multipliedBy(ThumbnailCellUX.ImageAspectRatio)
            return
        })

        textLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        textLabel.font = LabelFont
        textLabel.textColor = LabelColor
        textLabel.snp_makeConstraints({ make in
            make.left.right.bottom.equalTo(self.contentView).insets(CellInsets)
            return
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var image: UIImage? = nil {
        didSet {
            if let image = image {
                imageView.image = image
                imageView.alignment = UIImageViewAlignmentMaskTop
                imageView.contentMode = UIViewContentMode.ScaleAspectFill
            } else {
                imageView.image = PlaceholderImage
                imageView.alignment = UIImageViewAlignmentMaskCenter
                imageView.contentMode = UIViewContentMode.Center
            }
        }
    }
}
