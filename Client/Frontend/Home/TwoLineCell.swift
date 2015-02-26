/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

// UITableViewController doesn't let us specify a style for recycling views. We override the default style here.
class TwoLineCell : UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        // ignore the style argument, use our own to override
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)

        let font = UIFont(name: "FiraSans-SemiBold", size: 12)
        textLabel?.font = font
        textLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.blackColor() : UIColor.darkGrayColor()
        indentationWidth = 0

        detailTextLabel?.font = font
        detailTextLabel?.textColor = UIAccessibilityDarkerSystemColorsEnabled() ? UIColor.darkGrayColor() : UIColor.lightGrayColor()

        imageView?.contentMode = .ScaleAspectFill
    }

    private let imgMargin: CGFloat = 10

    override func layoutSubviews() {
        super.layoutSubviews()
        if let img = self.imageView {
            let height = self.frame.height
            let imgSize = height - 2 * imgMargin
            separatorInset = UIEdgeInsets(top: 0, left: height, bottom: 0, right: 0)
            img.frame = CGRectMake(imgMargin, imgMargin, imgSize, imgSize)
            textLabel?.frame = CGRectMake(height, textLabel!.frame.origin.y,
                self.frame.width - height, textLabel!.frame.height)
            detailTextLabel?.frame = CGRectMake(height, detailTextLabel!.frame.origin.y,
                self.frame.width - height, textLabel!.frame.height)
        }
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}