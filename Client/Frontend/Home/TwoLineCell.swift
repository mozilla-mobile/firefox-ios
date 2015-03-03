/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ThumbnailCell : UICollectionViewCell {
    let textLabel = UILabel()
    let imageView = UIImageView()
    let margin = 10

    override init() {
        super.init()
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        contentView.addSubview(textLabel)
        contentView.addSubview(imageView)

        textLabel.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        textLabel.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
        textLabel.snp_makeConstraints({ make in
            make.bottom.right.equalTo(self.contentView).offset(-self.margin)
            make.left.equalTo(self.contentView).offset(self.margin)
            make.height.equalTo(26)
            return
        })

        imageView.layer.borderColor = UIColor.lightGrayColor().CGColor
        imageView.layer.borderWidth = 1
        imageView.snp_makeConstraints({ make in
            make.top.equalTo(self.contentView).offset(self.margin)
            make.left.equalTo(self.textLabel.snp_left)
            make.right.equalTo(self.textLabel.snp_right)
            make.bottom.equalTo(self.textLabel.snp_top)
        })
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TopSitesSeperator : UICollectionReusableView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.lightGrayColor()
    }
}

class TopSitesRow : UICollectionViewCell {
    let textLabel = UILabel()
    let descriptionLabel = UILabel()
    let imageView = UIImageView()
    let margin = 10

    override init() {
        super.init()
        setup()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    private func setup() {
        contentView.addSubview(textLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(imageView)

        imageView.contentMode = .ScaleAspectFill
        imageView.image = UIImage(named: "defaultFavicon")
        imageView.snp_makeConstraints({ make in
            make.top.left.equalTo(self.contentView).offset(self.margin)
            make.bottom.equalTo(self.contentView).offset(-self.margin)
            make.width.equalTo(self.contentView.snp_height).offset(-2*self.margin)
        })

        textLabel.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        textLabel.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
        textLabel.snp_makeConstraints({ make in
            make.top.equalTo(self.imageView.snp_top)
            make.right.equalTo(self.contentView).offset(-self.margin)
            make.left.equalTo(self.imageView.snp_right).offset(self.margin)
            return
        })

        descriptionLabel.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        descriptionLabel.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.lightTextColor() : UIColor.lightGrayColor()
        descriptionLabel.snp_makeConstraints({ make in
            make.top.equalTo(self.textLabel.snp_bottom)
            make.right.equalTo(self.contentView).offset(-self.margin)
            make.left.equalTo(self.imageView.snp_right).offset(self.margin)
            return
        })

    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


// UITableViewController doesn't let us specify a style for recycling views. We override the default style here.
class TwoLineCell : UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        // ignore the style argument, use our own to override
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)

        textLabel?.font = UIFont(name: "FiraSans-SemiBold", size: 13)
        textLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
        indentationWidth = 0

        detailTextLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGrayColor() : UIColor.lightGrayColor()

        imageView?.contentMode = .ScaleAspectFill
    }

    private let imgMargin: CGFloat = 5

    override func layoutSubviews() {
        super.layoutSubviews()
        if let img = self.imageView {
            let height = self.frame.height
            let imgSize = height - 2 * imgMargin
            img.frame = CGRectMake(imgMargin, imgMargin, imgSize, imgSize)
            textLabel?.frame    = CGRectMake(height, textLabel!.frame.origin.y,
                self.frame.width - height, textLabel!.frame.height)
            detailTextLabel?.frame = CGRectMake(height, detailTextLabel!.frame.origin.y,
                self.frame.width - height, textLabel!.frame.height)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}