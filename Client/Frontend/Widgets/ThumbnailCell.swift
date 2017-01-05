/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared

struct ThumbnailCellUX {
    /// Ratio of width:height of the thumbnail image.
    static let ImageAspectRatio: Float = 1.0
    static let BorderColor = UIColor.blackColor().colorWithAlphaComponent(0.1)
    static let BorderWidth: CGFloat = 1
    static let LabelColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x353535)
    static let LabelBackgroundColor = UIColor(white: 1.0, alpha: 0.5)
    static let LabelAlignment: NSTextAlignment = .Center
    static let SelectedOverlayColor = UIColor(white: 0.0, alpha: 0.25)
    static let InsetSize: CGFloat = 20
    static let InsetSizeCompact: CGFloat = 6
    static func insetsForCollectionViewSize(size: CGSize, traitCollection: UITraitCollection) -> UIEdgeInsets {
        let largeInsets = UIEdgeInsets(
                top: ThumbnailCellUX.InsetSize,
                left: ThumbnailCellUX.InsetSize,
                bottom: ThumbnailCellUX.InsetSize,
                right: ThumbnailCellUX.InsetSize
            )
        let smallInsets = UIEdgeInsets(
                top: ThumbnailCellUX.InsetSizeCompact,
                left: ThumbnailCellUX.InsetSizeCompact,
                bottom: ThumbnailCellUX.InsetSizeCompact,
                right: ThumbnailCellUX.InsetSizeCompact
            )

        if traitCollection.horizontalSizeClass == .Compact {
            return smallInsets
        } else {
            return largeInsets
        }
    }

    static let ImagePaddingWide: CGFloat = 20
    static let ImagePaddingCompact: CGFloat = 10
    static func imageInsetsForCollectionViewSize(size: CGSize, traitCollection: UITraitCollection) -> UIEdgeInsets {
        let largeInsets = UIEdgeInsets(
                top: ThumbnailCellUX.ImagePaddingWide,
                left: ThumbnailCellUX.ImagePaddingWide,
                bottom: ThumbnailCellUX.ImagePaddingWide,
                right: ThumbnailCellUX.ImagePaddingWide
            )

        let smallInsets = UIEdgeInsets(
                top: ThumbnailCellUX.ImagePaddingCompact,
                left: ThumbnailCellUX.ImagePaddingCompact,
                bottom: ThumbnailCellUX.ImagePaddingCompact,
                right: ThumbnailCellUX.ImagePaddingCompact
            )
        if traitCollection.horizontalSizeClass == .Compact {
            return smallInsets
        } else {
            return largeInsets
        }
    }

    static let LabelInsets = UIEdgeInsetsMake(10, 3, 10, 3)
    static let PlaceholderImage = UIImage(named: "defaultTopSiteIcon")
    static let CornerRadius: CGFloat = 3

    static let NearestNeighbordScalingThreshold: CGFloat = 24
}

class ThumbnailCell: UICollectionViewCell {
    var imageInsets: UIEdgeInsets = UIEdgeInsetsZero
    var cellInsets: UIEdgeInsets = UIEdgeInsetsZero

    var imagePadding: CGFloat = 0 {
        didSet {
            // Find out if our image is going to have fractional pixel width.
            // If so, we inset by a tiny extra amount to get it down to an integer for better
            // image scaling.
            let parentWidth = self.imageWrapper.frame.width
            let width = (parentWidth - imagePadding)
            let fractionalW = width - floor(width)
            let additionalW = fractionalW / 2

            imageView.snp_remakeConstraints { make in
                let insets = UIEdgeInsets(top: imagePadding, left: imagePadding, bottom: imagePadding, right: imagePadding)
                make.top.equalTo(self.imageWrapper).inset(insets.top)
                make.bottom.equalTo(textWrapper.snp_top).offset(-imagePadding)
                make.left.equalTo(self.imageWrapper).inset(insets.left + additionalW)
                make.right.equalTo(self.imageWrapper).inset(insets.right + additionalW)
            }
            imageView.setNeedsUpdateConstraints()
        }
    }

    var image: UIImage? = nil {
        didSet {
            if let image = image {
                imageView.image = image
                imageView.contentMode = UIViewContentMode.ScaleAspectFit

                // Force nearest neighbor scaling for small favicons
                if image.size.width < ThumbnailCellUX.NearestNeighbordScalingThreshold {
                    imageView.layer.shouldRasterize = true
                    imageView.layer.rasterizationScale = 2
                    imageView.layer.minificationFilter = kCAFilterNearest
                    imageView.layer.magnificationFilter = kCAFilterNearest
                }

            } else {
                imageView.image = ThumbnailCellUX.PlaceholderImage
                imageView.contentMode = UIViewContentMode.Center
            }
        }
    }

    lazy var textWrapper: UIView = {
        let wrapper = UIView()
        wrapper.backgroundColor = ThumbnailCellUX.LabelBackgroundColor
        return wrapper
    }()

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.setContentHuggingPriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
        textLabel.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
        textLabel.textColor = ThumbnailCellUX.LabelColor
        textLabel.textAlignment = ThumbnailCellUX.LabelAlignment
        return textLabel
    }()

    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = UIViewContentMode.ScaleAspectFit

        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = ThumbnailCellUX.CornerRadius
        return imageView
    }()


    lazy var imageWrapper: UIView = {
        let imageWrapper = UIView()
        imageWrapper.layer.borderColor = ThumbnailCellUX.BorderColor.CGColor
        imageWrapper.layer.borderWidth = ThumbnailCellUX.BorderWidth
        imageWrapper.layer.cornerRadius = ThumbnailCellUX.CornerRadius
        imageWrapper.clipsToBounds = true
        return imageWrapper
    }()

    lazy var backgroundImage: UIImageView = {
        let backgroundImage = UIImageView()
        backgroundImage.contentMode = UIViewContentMode.ScaleAspectFill
        return backgroundImage
    }()

    lazy var selectedOverlay: UIView = {
        let selectedOverlay = UIView()
        selectedOverlay.backgroundColor = ThumbnailCellUX.SelectedOverlayColor
        selectedOverlay.hidden = true
        return selectedOverlay
    }()

    override var selected: Bool {
        didSet {
            self.selectedOverlay.hidden = !selected
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.shouldRasterize = true
        layer.rasterizationScale = UIScreen.mainScreen().scale

        isAccessibilityElement = true

        contentView.addSubview(imageWrapper)
        imageWrapper.addSubview(backgroundImage)
        backgroundImage.snp_remakeConstraints { make in
            make.top.bottom.left.right.equalTo(self.imageWrapper)
        }
        imageWrapper.addSubview(imageView)
        imageWrapper.addSubview(textWrapper)
        imageWrapper.addSubview(selectedOverlay)
        textWrapper.addSubview(textLabel)

        textWrapper.snp_makeConstraints { make in
            make.bottom.equalTo(self.imageWrapper.snp_bottom) // .offset(ThumbnailCellUX.BorderWidth)
            make.left.right.equalTo(self.imageWrapper) // .offset(ThumbnailCellUX.BorderWidth)
        }

        selectedOverlay.snp_makeConstraints { make in
            make.edges.equalTo(self.imageWrapper)
        }

        textLabel.snp_remakeConstraints { make in
            make.edges.equalTo(self.textWrapper).inset(ThumbnailCellUX.LabelInsets) // TODO swift-2.0 I changes insets to inset - how can that be right?
        }

        // Prevents the textLabel from getting squished in relation to other view priorities.
        textLabel.setContentCompressionResistancePriority(1000, forAxis: UILayoutConstraintAxis.Vertical)
    }



    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        backgroundImage.image = nil
        imageWrapper.backgroundColor = UIColor.clearColor()
        textLabel.font = DynamicFontHelper.defaultHelper.DefaultSmallFont
    }

    /**
     Updates the insets and padding of the cell based on the size of the container collection view

     - parameter size: Size of the container collection view
     */
    func updateLayoutForCollectionViewSize(size: CGSize, traitCollection: UITraitCollection, forSuggestedSite: Bool) {
        let cellInsets = ThumbnailCellUX.insetsForCollectionViewSize(size,
            traitCollection: traitCollection)
        let imageInsets = ThumbnailCellUX.imageInsetsForCollectionViewSize(size,
            traitCollection: traitCollection)

        if cellInsets != self.cellInsets {
            self.cellInsets = cellInsets
            imageWrapper.snp_remakeConstraints { make in
                make.edges.equalTo(self.contentView).inset(cellInsets)
            }
        }

        if forSuggestedSite {
            self.imagePadding = 0.0
            return
        }

        if imageInsets != self.imageInsets {
            imageView.snp_remakeConstraints { make in
                make.top.equalTo(self.imageWrapper).inset(imageInsets.top)
                make.left.right.equalTo(self.imageWrapper).inset(imageInsets.left)
                make.right.equalTo(self.imageWrapper).inset(imageInsets.right)
                make.bottom.equalTo(textWrapper.snp_top).offset(-imageInsets.top)
            }
        }
    }

    func extractImageFromCell() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(CGSize(width: imageWrapper.bounds.width, height: imageWrapper.bounds.height - textWrapper.bounds.height), false, 0.0)
        imageWrapper.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let extractedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return extractedImage
    }
}
