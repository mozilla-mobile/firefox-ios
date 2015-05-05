/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct ThumbnailCellUX {
    /// Ratio of width:height of the thumbnail image.
    static let ImageAspectRatio: Float = 1.5
    static let TextSize = AppConstants.DefaultSmallFontSize
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
    static let LabelFont = AppConstants.DefaultSmallFont
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
    static let Insets = UIEdgeInsetsMake(8, 8, 8, 8)
    static let TextOffset = 2
    static let PlaceholderImage = UIImage(named: "defaultFavicon")
}

class ThumbnailCell: UICollectionViewCell {
    let textLabel = UILabel()
    let imageView = UIImageViewAligned()
    let imageWrapper = UIView()

    override init(frame: CGRect) {
        imagePadding = CGFloat(0)
        super.init(frame: frame)

        contentView.addSubview(textLabel)
        contentView.addSubview(imageWrapper)
        imageWrapper.addSubview(imageView)

        imageWrapper.layer.borderColor = ThumbnailCellUX.BorderColor.CGColor
        imageWrapper.layer.borderWidth = 1
        imageWrapper.layer.cornerRadius = 3
        imageWrapper.clipsToBounds = true

        imageWrapper.snp_remakeConstraints({ make in
            make.top.left.right.equalTo(self.contentView).insets(ThumbnailCellUX.Insets)
            make.width.equalTo(self.imageWrapper.snp_height).multipliedBy(ThumbnailCellUX.ImageAspectRatio)
        })

        imageView.snp_remakeConstraints({ make in
            make.top.bottom.left.right.equalTo(self.imageWrapper)
        })

        textLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        textLabel.font = ThumbnailCellUX.LabelFont
        textLabel.textColor = ThumbnailCellUX.LabelColor
        textLabel.snp_remakeConstraints({ make in
            make.top.equalTo(self.imageWrapper.snp_bottom).offset(ThumbnailCellUX.TextOffset)
            make.left.right.equalTo(self.contentView).insets(ThumbnailCellUX.Insets)
            return
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var imagePadding: CGFloat {
        didSet {
            imageView.snp_remakeConstraints({ make in
                make.top.bottom.left.right.equalTo(self.imageWrapper).insets(UIEdgeInsetsMake(imagePadding, imagePadding, imagePadding, imagePadding))
                return
            })
        }
    }

    var image: UIImage? = nil {
        didSet {
            if let image = image {
                imageView.image = image
                imageView.alignment = UIImageViewAlignmentMaskTop
                imageView.contentMode = UIViewContentMode.ScaleAspectFill
            } else {
                imageView.image = ThumbnailCellUX.PlaceholderImage
                imageView.alignment = UIImageViewAlignmentMaskCenter
                imageView.contentMode = UIViewContentMode.Center
            }
        }
    }
}
