/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

class DevicesShareSheet : UIActivity {
    
    var _activityTitle: String
    var _activityImage: UIImage?
    var activityItems = [Any]()
    var action: ([Any]) -> Void
    
    init(title: String, image: UIImage?, performAction: @escaping ([Any]) -> Void) {
        _activityTitle = title
        _activityImage = image
        action = performAction
        super.init()
    }
    
    override var activityTitle: String? {
        return _activityTitle
    }

    override var activityImage: UIImage? {
        return _activityImage
    }
    
    override var activityType: UIActivity.ActivityType? {
        return UIActivity.ActivityType(rawValue: "org.Mozilla.firefoxApp.activity")
    }

    override class var activityCategory: UIActivity.Category {
        return .share
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }
    
    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItems = activityItems
    }
    
    override func perform() {
        action(activityItems)
        activityDidFinish(true)
    }
}
