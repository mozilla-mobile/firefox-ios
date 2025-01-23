// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

// App-specific share sheet actions
enum CustomActivityAction {
    case sendToDevice

    var title: String {
        switch self {
        case .sendToDevice:
            return .ShareSheet.SendToDeviceButtonTitle
        }
    }

    var image: UIImage? {
        switch self {
        case .sendToDevice:
            return UIImage(named: StandardImageIdentifiers.Large.deviceDesktopSend)
        }
    }

    var actionType: UIActivity.ActivityType {
        var activityType: String
        switch self {
        case .sendToDevice:
            activityType = ".sendToDevice"
        }

        return UIActivity.ActivityType(rawValue: "\(AppInfo.bundleIdentifier)\(activityType)")
    }
}

protocol AppActivityProtocol: UIActivity {
    var appActivityType: CustomActivityAction { get }
    var url: URL { get }
}

// Parent class to include share code for activity title, icon and type
class CustomAppActivity: UIActivity, AppActivityProtocol {
    var appActivityType: CustomActivityAction
    var url: URL

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

    init(activityType: CustomActivityAction, url: URL) {
        self.appActivityType = activityType
        self.url = url.isReaderModeURL
                   ? (url.decodeReaderModeURL ?? url)
                   : url
        super.init()
    }
}
