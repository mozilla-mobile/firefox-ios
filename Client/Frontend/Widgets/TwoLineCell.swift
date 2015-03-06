/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

private let IconSize: CGFloat = 28
private let Margin: CGFloat = 8

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

        layoutMargins = UIEdgeInsetsZero
        separatorInset = UIEdgeInsetsMake(0, IconSize + 2 * Margin, 0, 0)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let height: CGFloat = self.frame.height
        let textLeft = IconSize + 2 * Margin

        imageView?.frame = CGRectMake(Margin, Margin, IconSize, IconSize)
        textLabel?.frame = CGRectMake(textLeft, textLabel!.frame.origin.y,
            self.frame.width - textLeft - Margin, textLabel!.frame.height)
        detailTextLabel?.frame = CGRectMake(textLeft, detailTextLabel!.frame.origin.y,
            self.frame.width - textLeft - Margin, detailTextLabel!.frame.height)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}