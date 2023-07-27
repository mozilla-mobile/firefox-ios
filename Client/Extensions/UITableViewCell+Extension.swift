// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension UITableViewCell {
    private static var customTopSeparatorKey = "customTopSeparatorKey"
    private static var customBottomSeparatorKey = "customBottomSeparatorKey"

    var customTopSeparatorView: UIView? {
        get { return objc_getAssociatedObject(self, &UITableViewCell.customTopSeparatorKey) as? UIView }
        set { objc_setAssociatedObject(self, &UITableViewCell.customTopSeparatorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    var customBottomSeparatorView: UIView? {
        get { return objc_getAssociatedObject(self, &UITableViewCell.customBottomSeparatorKey) as? UIView }
        set { objc_setAssociatedObject(self, &UITableViewCell.customBottomSeparatorKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func addCustomSeparator(atTop: Bool, atBottom: Bool, separatorColor: UIColor) {
        let height: CGFloat = 0.5  // firefox separator height
        let leading: CGFloat = atTop || atBottom ? 0 : 50 // 50 is just a placeholder fallback

        if atTop {
            let topSeparatorView = UIView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: height))
            topSeparatorView.backgroundColor = separatorColor
            topSeparatorView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
            contentView.addSubview(topSeparatorView)
            self.customTopSeparatorView = topSeparatorView
        }

        if atBottom {
            let bottomSeparatorView = UIView(frame: CGRect(x: leading, y: frame.size.height - height, width: frame.size.width, height: height))
            bottomSeparatorView.backgroundColor = separatorColor
            bottomSeparatorView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
            contentView.addSubview(bottomSeparatorView)
            self.customBottomSeparatorView = bottomSeparatorView
        }
    }
}
