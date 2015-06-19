/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

struct ThumbnailCellUX {
    /// Ratio of width:height of the thumbnail image.
    static let ImageAspectRatio: Float = 1.5
    static let TextSize = UIConstants.DefaultSmallFontSize
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
    static let LabelFont = UIConstants.DefaultSmallFont
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
    static let InsetSize: CGFloat = 8
    static let Insets = UIEdgeInsetsMake(InsetSize, InsetSize, InsetSize, InsetSize)
    static let TextOffset = 2
    static let PlaceholderImage = UIImage(named: "defaultFavicon")

    // Make the remove button look 20x20 in size but have the clickable area be 44x44
    static let RemoveButtonSize: CGFloat = 44
    static let RemoveButtonInsets = UIEdgeInsets(top: 11, left: 11, bottom: 11, right: 11)
    static let RemoveButtonAnimationDuration: NSTimeInterval = 0.4
    static let RemoveButtonAnimationDamping: CGFloat = 0.6
}

@objc protocol ThumbnailCellDelegate {
    func didRemoveThumbnail(thumbnailCell: ThumbnailCell)
    func didLongPressThumbnail(thumbnailCell: ThumbnailCell)
}

class ThumbnailCell: UICollectionViewCell {
    weak var delegate: ThumbnailCellDelegate?

    lazy var longPressGesture: UILongPressGestureRecognizer = {
        return UILongPressGestureRecognizer(target: self, action: "SELdidLongPress")
    }()

    let textLabel = UILabel()
    let imageView = UIImageViewAligned()
    let imageWrapper = UIView()
    let removeButton = UIButton()

    override init(frame: CGRect) {
        imagePadding = CGFloat(0)
        super.init(frame: frame)

        addGestureRecognizer(longPressGesture)

        contentView.addSubview(textLabel)
        contentView.addSubview(imageWrapper)
        imageWrapper.addSubview(imageView)
        contentView.addSubview(removeButton)

        imageWrapper.layer.borderColor = ThumbnailCellUX.BorderColor.CGColor
        imageWrapper.layer.borderWidth = 1
        imageWrapper.layer.cornerRadius = 3
        imageWrapper.clipsToBounds = true

        removeButton.setImage(UIImage(named: "TileCloseButton"), forState: UIControlState.Normal)
        removeButton.addTarget(self, action: "SELdidRemove", forControlEvents: UIControlEvents.TouchUpInside)
        removeButton.hidden = true
        removeButton.imageEdgeInsets = ThumbnailCellUX.RemoveButtonInsets

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

    override func layoutSubviews() {
        super.layoutSubviews()
        var frame = removeButton.frame
        frame.size = CGSize(width: ThumbnailCellUX.RemoveButtonSize, height: ThumbnailCellUX.RemoveButtonSize)
        frame.center = CGPoint(x: ThumbnailCellUX.InsetSize, y: ThumbnailCellUX.InsetSize)
        removeButton.frame = frame
    }

    func SELdidRemove() {
        delegate?.didRemoveThumbnail(self)
    }

    func SELdidLongPress() {
        delegate?.didLongPressThumbnail(self)
    }

    func toggleRemoveButton(show: Bool) {
        // Only toggle if we change state
        if removeButton.hidden != show {
            return
        }

        if show {
            removeButton.hidden = false
        }

        let scaleTransform = CGAffineTransformMakeScale(0.01, 0.01)
        removeButton.transform = show ? scaleTransform : CGAffineTransformIdentity
        UIView.animateWithDuration(ThumbnailCellUX.RemoveButtonAnimationDuration,
            delay: 0,
            usingSpringWithDamping: ThumbnailCellUX.RemoveButtonAnimationDamping,
            initialSpringVelocity: 0,
            options: UIViewAnimationOptions.AllowUserInteraction |  UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                self.removeButton.transform = show ? CGAffineTransformIdentity : scaleTransform
            }, completion: { _ in
                if !show {
                    self.removeButton.hidden = true
                }
            })
    }

    var imagePadding: CGFloat {
        didSet {
            imageView.snp_remakeConstraints({ make in
                make.top.bottom.left.right.equalTo(self.imageWrapper).insets(UIEdgeInsetsMake(imagePadding, imagePadding, imagePadding, imagePadding))
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
