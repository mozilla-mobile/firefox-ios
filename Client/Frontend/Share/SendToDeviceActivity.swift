// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Storage
import Shared

enum CustomActivityAction {
    case sendToDevice

    var title: String {
        switch self {
        case .sendToDevice:
            return .AppMenu.TouchActions.SendToDeviceTitle
        }
    }

    var image: UIImage? {
        switch self {
        case .sendToDevice:
            return UIImage(named: ImageIdentifiers.sendToDevice)
        }
    }

    var actionType: UIActivity.ActivityType {
        var activityType: String
        switch self {
        case .sendToDevice:
            activityType = ".sendToDevice"
        }
        let bundle = Bundle.main.bundleIdentifier
        return UIActivity.ActivityType(rawValue: "\(bundle!)\(activityType)")
    }
}

class SendToDeviceActivity: UIActivity {
    var appActivityType: CustomActivityAction
    var activityItems = [Any]()

    override var activityTitle: String? {
        return appActivityType.title
    }

    override var activityImage: UIImage? {
        return appActivityType.image
    }

    override var activityType: UIActivity.ActivityType {
        return appActivityType.actionType
    }

    override class var activityCategory: UIActivity.Category {
        return .action
    }

    init(activityType: CustomActivityAction) {
        appActivityType = activityType
        super.init()
    }

    override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
        return true
    }

    override func prepare(withActivityItems activityItems: [Any]) {
        self.activityItems = activityItems
    }

    override func perform() {
        activityDidFinish(true)
    }
}
