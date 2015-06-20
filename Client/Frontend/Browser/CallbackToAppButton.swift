/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class CallbackToAppButton: UIButton {
    var tab: Browser? = nil

    init() {
        super.init(frame: CGRectZero)
        titleLabel!.font = UIFont(name: "HelveticaNeue-Light", size: 14)
        setTitleColor(UIColor(red:0.373, green:0.388, blue:0.408, alpha: 1.0), forState: UIControlState.Normal)
        titleLabel!.lineBreakMode = NSLineBreakMode.ByTruncatingTail

        let callbackBackArrow = UIImage(named: "callbackBackArrow")
        setImage(callbackBackArrow, forState: UIControlState.Normal)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}