/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let ImageSize: CGFloat = 24
private let ImageMargin: CGFloat = 10
private let TextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor(rgb: 0x333333)
private let DetailTextColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGrayColor() : UIColor.grayColor()

class TwoLineTableViewCell: UITableViewCell {
    private let twoLineHelper: TwoLineCellHelper!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)

        twoLineHelper = TwoLineCellHelper(container: self, textLabel: textLabel!, detailTextLabel: detailTextLabel!, imageView: imageView!)

        indentationWidth = 0
        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsMake(0, ImageSize + 2 * ImageMargin, 0, 0)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()
    }
}

class TwoLineCollectionViewCell: UICollectionViewCell {
    private let twoLineHelper: TwoLineCellHelper!
    let textLabel = UILabel()
    let detailTextLabel = UILabel()
    let imageView = UIImageView()

    override init() {
        super.init()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(textLabel)
        contentView.addSubview(detailTextLabel)
        contentView.addSubview(imageView)

        twoLineHelper = TwoLineCellHelper(container: self, textLabel: textLabel, detailTextLabel: detailTextLabel, imageView: imageView)

        layoutMargins = UIEdgeInsetsZero
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        twoLineHelper.layoutSubviews()
    }
}

private class TwoLineCellHelper {
    private let container: UIView
    let textLabel: UILabel
    let detailTextLabel: UILabel
    let imageView: UIImageView

    init(container: UIView, textLabel: UILabel, detailTextLabel: UILabel, imageView: UIImageView) {
        self.container = container
        self.textLabel = textLabel
        self.detailTextLabel = detailTextLabel
        self.imageView = imageView

        textLabel.font = UIFont(name: "FiraSans-Regular", size: 13)
        textLabel.textColor = TextColor

        detailTextLabel.font = UIFont(name: "FiraSans-Regular", size: 10)
        detailTextLabel.textColor = DetailTextColor

        imageView.contentMode = .ScaleAspectFill
    }

    func layoutSubviews() {
        let height = container.frame.height
        let textLeft = ImageSize + 2 * ImageMargin
        let textLabelHeight = textLabel.intrinsicContentSize().height
        let detailTextLabelHeight = detailTextLabel.intrinsicContentSize().height
        let contentHeight = textLabelHeight + detailTextLabelHeight + 1
        imageView.frame = CGRectMake(ImageMargin, (height - ImageSize) / 2, ImageSize, ImageSize)
        textLabel.frame = CGRectMake(textLeft, (height - contentHeight) / 2,
            container.frame.width - textLeft - ImageMargin, textLabelHeight)
        detailTextLabel.frame = CGRectMake(textLeft, textLabel.frame.maxY + 1,
            container.frame.width - textLeft - ImageMargin, detailTextLabelHeight)
    }
}
